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
  Future<User?> checkMembershipStatus(User user) async {
    final String? token = await _tokenStore.read();
    if (token == null || token.isEmpty) return null;
    final Map<String, dynamic> membership = requireJsonMap(
      await _apiClient.get('/member/membership'),
      description: 'membership response',
    );
    return UserModel.withMembership(user, membership);
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
    final String? token = firstString(json, const <String>['reset_token']);
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
    // Independent reads, so they run in parallel: a signed-in member reaches
    // Home after one round trip. Cars are read with the profile.
    final List<Object?> responses = await Future.wait<Object?>(
      <Future<Object?>>[
        _apiClient.get('/auth/me'),
        _apiClient.get('/member/membership'),
      ],
    );
    return UserModel.fromJson(
      requireJsonMap(responses[0], description: 'signed-in user response'),
      membership: requireJsonMap(
        responses[1],
        description: 'membership response',
      ),
    );
  }

  static _SignInTokens _extractSignInTokens(Object? response) {
    final Map<String, dynamic> json = requireJsonMap(
      response,
      description: 'login OTP verification response',
    );
    final String? token = firstString(json, const <String>['access_token']);
    final String? refreshToken = firstString(json, const <String>[
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
