/// Minimal success/failure type for repository and service results.
///
/// Repositories return [Result] instead of throwing for expected failures
/// (validation, not-found, storage errors). Unexpected programming errors
/// still throw.
sealed class Result<T> {
  const Result();
}

/// Successful result carrying [value].
final class Success<T> extends Result<T> {
  final T value;

  const Success(this.value);
}

/// Failed result with a user-presentable [message] and optional [cause].
final class Failure<T> extends Result<T> {
  final String message;
  final Object? cause;

  const Failure(this.message, {this.cause});
}

/// True when this is a [Success].
bool isSuccess<T>(Result<T> result) => result is Success<T>;

/// The success value, or null for [Failure].
T? valueOrNull<T>(Result<T> result) {
  if (result is Success<T>) {
    return result.value;
  }
  return null;
}
