import 'package:pcj_v5/core/errors/app_exception.dart';
import 'package:pcj_v5/core/network/api_parsers.dart';
import 'package:pcj_v5/core/network/pcj_api_client.dart';
import 'package:pcj_v5/core/network/token_store.dart';
import 'package:pcj_v5/features/auth/domain/repositories/auth_repository.dart';

import '../models/user_model.dart';

class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required PcjApiClient apiClient,
    required TokenStore tokenStore,
  }) : _apiClient = apiClient,
       _tokenStore = tokenStore;

  final PcjApiClient _apiClient;
  final TokenStore _tokenStore;
  static const String _loginOtpPurpose = 'login';
  static const String _passwordResetOtpPurpose = 'forgot_password';

  @override
  Future<User?> restoreSession() async {
    final String? token = await _tokenStore.read();
    if (token == null || token.isEmpty) return null;
    try {
      return await _getCurrentUser();
    } on AuthenticationException {
      await _tokenStore.clear();
      return null;
    }
  }

  @override
  Future<void> requestSignInOtp({
    required String email,
    required String password,
  }) async {
    await _apiClient.postForm(
      '/auth/login',
      fields: <String, Object?>{'email': email.trim(), 'password': password},
      authenticated: false,
    );
  }

  @override
  Future<User> verifySignInOtp({
    required String email,
    required String otp,
  }) async {
    final Object? response = await verifyOtp(
      email: email,
      otp: otp,
      purpose: _loginOtpPurpose,
    );
    final _SignInTokens tokens = _extractSignInTokens(response);
    await _tokenStore.write(
      tokens.token,
      refreshToken: tokens.refreshToken,
    );
    try {
      return await _getCurrentUser();
    } catch (_) {
      await _tokenStore.clear();
      rethrow;
    }
  }

  @override
  Future<void> resendSignInOtp({required String email}) {
    return resendOtp(
      email: email,
      purpose: _loginOtpPurpose,
    );
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await _apiClient.postJson(
      '/auth/forgot-password',
      body: <String, Object?>{'email': email.trim()},
      authenticated: false,
    );
  }

  @override
  Future<String> verifyPasswordResetOtp({
    required String email,
    required String otp,
  }) async {
    final Object? response = await verifyOtp(
      email: email,
      otp: otp,
      purpose: _passwordResetOtpPurpose,
    );
    final Map<String, dynamic> json = requireJsonMap(
      response,
      description: 'password reset verification response',
    );
    final Object? nested = json['data'];
    final Map<String, dynamic> values = nested is Map
        ? Map<String, dynamic>.from(nested)
        : json;
    final String? token = firstString(values, const <String>[
      'reset_token',
      'reset-token',
      'resent_token',
      'resent-token',
      'token',
    ]);
    if (token == null || token.isEmpty) {
      throw const AppException(
        'The verification response did not include a password reset token.',
      );
    }
    return token;
  }

  @override
  Future<void> resendPasswordResetOtp({required String email}) {
    return resendOtp(email: email, purpose: _passwordResetOtpPurpose);
  }

  @override
  Future<void> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    await _apiClient.postForm(
      '/auth/reset-password',
      fields: <String, Object?>{
        'reset_token': resetToken,
        'new_password': newPassword,
      },
      authenticated: false,
    );
  }

  @override
  Future<Object?> verifyOtp({
    required String email,
    required String otp,
    required String purpose,
  }) {
    return _apiClient.postForm(
      '/auth/verify-otp',
      fields: <String, Object?>{
        'email': email.trim(),
        'otp': otp.trim(),
        'purpose': purpose.trim(),
      },
      authenticated: false,
    );
  }

  @override
  Future<void> resendOtp({
    required String email,
    required String purpose,
  }) async {
    await _apiClient.post(
      '/auth/resend-otp',
      query: <String, Object?>{
        'email': email.trim(),
        'purpose': purpose.trim(),
      },
      authenticated: false,
    );
  }

  @override
  Future<void> signOut() async {
    try {
      await _apiClient.post('/auth/logout');
    } finally {
      await _tokenStore.clear();
    }
  }

  Future<User> _getCurrentUser() async {
    // The three reads are independent, so they run in parallel: a signed-in
    // member reaches Home after one round trip instead of three.
    final List<Object?> responses = await Future.wait<Object?>(
      <Future<Object?>>[
        _apiClient.get('/auth/me'),
        _apiClient.get('/member/membership'),
        // QR data is supplementary. Authentication and status routing must
        // not fail merely because a QR code has not been issued yet.
        _apiClient
            .get('/member/qr')
            .then<Object?>(
              (Object? value) => value,
              onError: (Object _) => null,
            ),
      ],
    );
    final Map<String, dynamic> profile = requireJsonMap(
      responses[0],
      description: 'signed-in user response',
    );
    final Map<String, dynamic> membership = requireJsonMap(
      responses[1],
      description: 'membership response',
    );

    Map<String, dynamic> memberQr = const <String, dynamic>{};
    try {
      memberQr = requireJsonMap(
        responses[2],
        description: 'member QR response',
      );
    } catch (_) {
      // See above: a missing QR never blocks sign in.
    }

    return UserModel.fromJson(<String, dynamic>{
      ...profile,
      'membership': membership,
      if (memberQr['cars'] != null) 'cars': memberQr['cars'],
      if (memberQr['name'] != null && profile['name'] == null)
        'name': memberQr['name'],
      if (memberQr['phone'] != null && profile['phone'] == null)
        'phone': memberQr['phone'],
      if (memberQr['email'] != null && profile['email'] == null)
        'email': memberQr['email'],
    });
  }

  static _SignInTokens _extractSignInTokens(Object? response) {
    final Map<String, dynamic> json = requireJsonMap(
      response,
      description: 'login OTP verification response',
    );
    final Object? nested = json['data'];
    final Map<String, dynamic> tokenJson = nested is Map
        ? Map<String, dynamic>.from(nested)
        : json;
    final String? token = firstString(tokenJson, const <String>[
      'access_token',
    ]);
    final String? refreshToken = firstString(tokenJson, const <String>[
      'refresh_token',
    ]);
    if (token == null || refreshToken == null) {
      throw const AuthenticationException(
        'The OTP verification response did not contain access_token and '
        'refresh_token.',
      );
    }
    return _SignInTokens(token: token, refreshToken: refreshToken);
  }
}

class _SignInTokens {
  const _SignInTokens({required this.token, required this.refreshToken});

  final String token;
  final String refreshToken;
}
