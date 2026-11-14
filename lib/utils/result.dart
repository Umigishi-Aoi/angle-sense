/// 失敗しうる処理の結果。例外を投げる代わりに、成功（[Ok]）か失敗（[Error]）を値で返す。
///
/// 呼び出し側は `switch` で両方を扱う（失敗したときの見せ方を呼び出し側で決められる）。
sealed class const Result<T>() {
  const factory ok(T value) = Ok<T>;
  const factory error(Exception error) = Error<T>;
}

/// 成功。
final class const Ok<T>(final T value) extends Result<T> {
  @override
  String toString() => 'Result<$T>.ok($value)';
}

/// 失敗。
final class const Error<T>(final Exception error) extends Result<T> {
  @override
  String toString() => 'Result<$T>.error($error)';
}
