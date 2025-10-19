class Result<T, E> {
  final T? value;
  final E? error;

  Result.success(this.value) : error = null;
  Result.failure(this.error) : value = null;

  bool get isSuccess => value != null;
  bool get isFailure => error != null;
}