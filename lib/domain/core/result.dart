/// Result type for handling success and failure states without throwing exceptions
sealed class Result<S, F> {
  const Result();

  /// Returns true if this is a Success result
  bool get isSuccess => this is Success<S, F>;

  /// Returns true if this is a Failure result
  bool get isFailure => this is Failure<S, F>;

  /// Returns the success value if this is a Success, otherwise null
  S? get successData => switch (this) {
        Success<S, F>(value: final data) => data,
        Failure<S, F>() => null,
      };

  /// Returns the failure value if this is a Failure, otherwise null
  F? get failureData => switch (this) {
        Success<S, F>() => null,
        Failure<S, F>(value: final error) => error,
      };

  /// Maps the success value to a new type
  Result<T, F> map<T>(T Function(S data) mapper) {
    return switch (this) {
      Success<S, F>(value: final data) => Success(mapper(data)),
      Failure<S, F>(value: final error) => Failure(error),
    };
  }

  /// Maps the failure value to a new type
  Result<S, T> mapFailure<T>(T Function(F error) mapper) {
    return switch (this) {
      Success<S, F>(value: final data) => Success(data),
      Failure<S, F>(value: final error) => Failure(mapper(error)),
    };
  }

  /// Executes the given function on success, returns the original result
  Result<S, F> onSuccess(void Function(S data) action) {
    if (this is Success<S, F>) {
      action((this as Success<S, F>).value);
    }
    return this;
  }

  /// Executes the given function on failure, returns the original result
  Result<S, F> onFailure(void Function(F error) action) {
    if (this is Failure<S, F>) {
      action((this as Failure<S, F>).value);
    }
    return this;
  }

  /// Returns the success value or throws the failure
  S get dataOrThrow {
    return switch (this) {
      Success<S, F>(value: final data) => data,
      Failure<S, F>(value: final error) => throw error as Exception,
    };
  }
}

/// Represents a successful operation
class Success<S, F> extends Result<S, F> {
  const Success(this.value);

  final S value;

  @override
  bool operator ==(Object other) {
    return other is Success<S, F> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Success($value)';
}

/// Represents a failed operation
class Failure<S, F> extends Result<S, F> {
  const Failure(this.value);

  final F value;

  @override
  bool operator ==(Object other) {
    return other is Failure<S, F> && other.value == value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'Failure($value)';
}
