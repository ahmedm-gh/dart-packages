/// Base exception class for all caster operations.
abstract class CasterException implements Exception {
  /// The message describing the exception.
  final String message;

  /// The stack trace where the exception occurred.
  final StackTrace? stackTrace;

  /// Creates a [CasterException] with the provided [message] and optional [stackTrace].
  const CasterException(this.message, {this.stackTrace});

  /// Factory constructor creating a [CasterArgumentException].
  const factory CasterException.argument(
    String message, {
    StackTrace? stackTrace,
  }) = CasterArgumentException;

  /// Factory constructor creating a [CasterTypeException].
  const factory CasterException.type(String message, {StackTrace? stackTrace}) =
      CasterTypeException;
}

/// Exception thrown when a type parameter [T] is not properly specified (e.g. [Object]).
class CasterArgumentException extends CasterException {
  /// Creates a [CasterArgumentException].
  const CasterArgumentException(super.message, {super.stackTrace});

  @override
  String toString() => 'CasterArgumentException: $message';
}

/// Exception thrown when a value cannot be safely cast to the requested type [T].
class CasterTypeException extends CasterException {
  /// Creates a [CasterTypeException].
  const CasterTypeException(super.message, {super.stackTrace});

  @override
  String toString() => 'CasterTypeException: $message';
}
