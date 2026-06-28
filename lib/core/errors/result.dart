/// Result 模式 —— 替代抛异常的"成功/失败"封装
///
/// 设计目的：
/// 1. 业务错误不应该是"异常"（异常是给程序员 debug 用的）
/// 2. 调用方必须显式处理失败路径（编译期强制）
/// 3. 与 Either<Failure, T> 语义一致，但更易读
///
/// 使用：
/// ```dart
/// final r = await repo.add(t);
/// switch (r) {
///   case Ok(value: final v): print('ok $v');
///   case Err(failure: final f): print('err ${f.message}');
/// }
/// ```
import '../failures/failure.dart';

sealed class Result<T> {
  const Result();

  /// 是否成功
  bool get isOk => this is Ok<T>;
  bool get isErr => this is Err<T>;

  /// 成功取值（失败时返回 null）
  T? get valueOrNull => switch (this) {
        Ok<T>(value: final v) => v,
        Err<T>() => null,
      };

  /// 失败取值（成功时返回 null）
  Failure? get failureOrNull => switch (this) {
        Ok<T>() => null,
        Err<T>(failure: final f) => f,
      };

  /// 映射成功值
  Result<R> map<R>(R Function(T) f) => switch (this) {
        Ok<T>(value: final v) => Ok<R>(f(v)),
        Err<T>(failure: final f) => Err<R>(f),
      };

  /// 链式调用（flatMap）
  Result<R> flatMap<R>(Result<R> Function(T) f) => switch (this) {
        Ok<T>(value: final v) => f(v),
        Err<T>(failure: final f) => Err<R>(f),
      };
}

final class Ok<T> extends Result<T> {
  final T value;
  const Ok(this.value);
}

final class Err<T> extends Result<T> {
  final Failure failure;
  const Err(this.failure);
}
