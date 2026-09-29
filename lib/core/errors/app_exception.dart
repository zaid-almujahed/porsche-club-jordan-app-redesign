class AppException implements Exception {
  const AppException(this.message, {this.statusCode, this.code, this.cause});

  final String message;
  final int? statusCode;
  final String? code;
  final Object? cause;

  @override
  String toString() => message;
}

class AuthenticationException extends AppException {
  const AuthenticationException(
    super.message, {
    super.statusCode,
    super.code = 'authentication_failed',
    super.cause,
  });
}

String readableError(
  Object error, {
  String fallback = 'Something went wrong. Please try again.',
}) {
  if (error is AppException) return error.message;
  return fallback;
}
