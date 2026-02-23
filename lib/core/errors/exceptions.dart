/// Base exception for all application-specific errors
abstract class AppException implements Exception {
  const AppException(this.message, this.code);

  final String message;
  final String code;

  @override
  String toString() => 'AppException: $message (Code: $code)';
}

/// Database-related exceptions
class DatabaseException extends AppException {
  const DatabaseException(super.message, super.code);
}

/// Security-related exceptions
class SecurityException extends AppException {
  const SecurityException(super.message, super.code);
}

/// Parsing-related exceptions
class ParsingException extends AppException {
  const ParsingException(super.message, super.code);
}

/// Validation exceptions
class ValidationException extends AppException {
  const ValidationException(super.message, super.code);
}

/// Business logic exceptions
class BusinessException extends AppException {
  const BusinessException(super.message, super.code);
}
