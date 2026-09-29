import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';
import '../errors/app_exception.dart';
import 'token_store.dart';

class ApiUpload {
  const ApiUpload({
    required this.field,
    required this.fileName,
    required this.bytes,
  });

  final String field;
  final String fileName;
  final Uint8List bytes;
}

/// Small package:http wrapper for the documented PCJ REST API.
class PcjApiClient {
  PcjApiClient(
    this._client, {
    required TokenStore tokenStore,
    Uri? baseUri,
    this.timeout = const Duration(seconds: 30),
  }) : _tokenStore = tokenStore,
       _baseUri = baseUri ?? Uri.parse(AppConfig.apiBaseUrl);

  final http.Client _client;
  final TokenStore _tokenStore;
  final Uri _baseUri;
  final Duration timeout;

  /// Called with the backend's message when an authenticated request is
  /// rejected with 401: the access token expired (after one month), was
  /// revoked, or its account no longer exists. The stored token is cleared
  /// first.
  void Function(String message)? onSessionExpired;

  /// Called when an authenticated request is refused with 403 (e.g. the
  /// account was deactivated), so the member's status is re-checked
  /// straight away.
  void Function()? onAccessDenied;

  Future<Object?> get(
    String path, {
    Map<String, Object?> query = const <String, Object?>{},
    bool authenticated = true,
  }) {
    return _send(
      method: 'GET',
      path: path,
      query: query,
      authenticated: authenticated,
    );
  }

  Future<Object?> postJson(
    String path, {
    Map<String, Object?> body = const <String, Object?>{},
    bool authenticated = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      body: jsonEncode(body),
      contentType: 'application/json',
      authenticated: authenticated,
    );
  }

  Future<Object?> post(
    String path, {
    Map<String, Object?> query = const <String, Object?>{},
    bool authenticated = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      query: query,
      authenticated: authenticated,
    );
  }

  Future<Object?> postForm(
    String path, {
    Map<String, Object?> fields = const <String, Object?>{},
    bool authenticated = true,
  }) {
    return _send(
      method: 'POST',
      path: path,
      body: _stringFields(fields),
      contentType: 'application/x-www-form-urlencoded',
      authenticated: authenticated,
    );
  }

  Future<Object?> patch(
    String path, {
    Map<String, Object?> query = const <String, Object?>{},
    bool authenticated = true,
  }) {
    return _send(
      method: 'PATCH',
      path: path,
      query: query,
      authenticated: authenticated,
    );
  }

  Future<Object?> delete(String path, {bool authenticated = true}) {
    return _send(method: 'DELETE', path: path, authenticated: authenticated);
  }

  Future<Object?> multipart(
    String path, {
    required String method,
    Map<String, Object?> fields = const <String, Object?>{},
    List<ApiUpload> files = const <ApiUpload>[],
    bool authenticated = true,
  }) async {
    final http.MultipartRequest request = http.MultipartRequest(
      method,
      _buildUri(path),
    );
    request.headers.addAll(await _headers(authenticated: authenticated));
    request.fields.addAll(_stringFields(fields));
    for (final ApiUpload file in files) {
      request.files.add(
        http.MultipartFile.fromBytes(
          file.field,
          file.bytes,
          filename: file.fileName,
          contentType: _detectImageContentType(file),
        ),
      );
    }

    // Do not log fields, filenames, URLs, or response bodies here. These
    // requests can contain passwords, OTPs, tokens, VINs, personal details,
    // licence images, and payment data.

    try {
      final http.StreamedResponse streamed = await _client
          .send(request)
          .timeout(timeout);
      return _decode(
        await http.Response.fromStream(streamed),
        authenticated: authenticated,
      );
    } on TimeoutException catch (error) {
      throw AppException(
        'The request timed out. Please check your connection and try again.',
        code: 'request_timeout',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw AppException(
        'The server could not be reached. Please check your connection.',
        code: 'network_error',
        cause: error,
      );
    }
  }

  Future<Object?> _send({
    required String method,
    required String path,
    Map<String, Object?> query = const <String, Object?>{},
    Object? body,
    String? contentType,
    required bool authenticated,
  }) async {
    final Map<String, String> headers = await _headers(
      authenticated: authenticated,
    );
    if (contentType != null) headers['Content-Type'] = contentType;
    final http.Request request = http.Request(
      method,
      _buildUri(path, query: query),
    )..headers.addAll(headers);

    if (body is String) {
      request.body = body;
    } else if (body is Map<String, String>) {
      request.bodyFields = body;
    }

    try {
      final http.StreamedResponse streamed = await _client
          .send(request)
          .timeout(timeout);
      return _decode(
        await http.Response.fromStream(streamed),
        authenticated: authenticated,
      );
    } on TimeoutException catch (error) {
      throw AppException(
        'The request timed out. Please check your connection and try again.',
        code: 'request_timeout',
        cause: error,
      );
    } on http.ClientException catch (error) {
      throw AppException(
        'The server could not be reached. Please check your connection.',
        code: 'network_error',
        cause: error,
      );
    }
  }

  Uri _buildUri(
    String path, {
    Map<String, Object?> query = const <String, Object?>{},
  }) {
    final Uri resolved = _baseUri.resolve(path.trim());
    return query.isEmpty
        ? resolved
        : resolved.replace(queryParameters: _stringFields(query));
  }

  Future<Map<String, String>> _headers({required bool authenticated}) async {
    final Map<String, String> headers = <String, String>{
      'Accept': 'application/json',
    };
    if (!authenticated) return headers;

    final String? token = await _tokenStore.read();
    if (token == null || token.isEmpty) {
      throw const AuthenticationException('Please sign in to continue.');
    }
    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  Object? _decode(http.Response response, {required bool authenticated}) {
    final String body = utf8.decode(response.bodyBytes).trim();
    Object? decoded;
    if (body.isNotEmpty) {
      try {
        decoded = jsonDecode(body);
      } on FormatException {
        decoded = body;
      }
    }

    if (response.statusCode < 200 || response.statusCode > 299) {
      final String message =
          _errorMessage(decoded) ??
          'Request failed with status ${response.statusCode}.';
      if (response.statusCode == 401 && authenticated) {
        unawaited(_tokenStore.clear());
        onSessionExpired?.call(message);
      }
      if (response.statusCode == 403 && authenticated) {
        onAccessDenied?.call();
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthenticationException(message, statusCode: response.statusCode);
      }
      throw AppException(message, statusCode: response.statusCode);
    }
    return decoded;
  }

  static String? _errorMessage(Object? decoded) {
    if (decoded is String && decoded.trim().isNotEmpty) return decoded;
    if (decoded is! Map) return null;
    final Object? detail =
        decoded['detail'] ?? decoded['message'] ?? decoded['error'];
    if (detail is String) return detail;
    if (detail is List) {
      return detail
          .map((Object? item) {
            if (item is Map && item['msg'] != null) {
              return item['msg'].toString();
            }
            return item.toString();
          })
          .join('\n');
    }
    return detail?.toString();
  }

  static MediaType? _detectImageContentType(ApiUpload file) {
    final Uint8List bytes = file.bytes;

    // JPEG files begin with FF D8 FF.
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return MediaType('image', 'jpeg');
    }

    // PNG files begin with this eight-byte signature.
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47 &&
        bytes[4] == 0x0D &&
        bytes[5] == 0x0A &&
        bytes[6] == 0x1A &&
        bytes[7] == 0x0A) {
      return MediaType('image', 'png');
    }

    // Fallback when the file signature cannot be determined.
    final String fileName = file.fileName.toLowerCase();

    if (fileName.endsWith('.jpg') ||
        fileName.endsWith('.jpeg')) {
      return MediaType('image', 'jpeg');
    }

    if (fileName.endsWith('.png')) {
      return MediaType('image', 'png');
    }

    return null;
  }

  static Map<String, String> _stringFields(Map<String, Object?> values) {
    return <String, String>{
      for (final MapEntry<String, Object?> entry in values.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };
  }
}
