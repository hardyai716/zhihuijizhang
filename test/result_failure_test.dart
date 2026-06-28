// 单元测试 3: Result<T> 错误体系
// 验证：业务方法不抛异常，全部返回 Result，调用方编译期强制处理

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/core/errors/result.dart';
import 'package:smart_ledger/core/failures/failure.dart';

void main() {
  group('Result<T> 错误体系', () {
    test('Ok 分支可取值', () {
      final r = Ok<int>(42);
      expect(r.isOk, true);
      expect(r.isErr, false);
      expect(r.valueOrNull, 42);
      expect(r.failureOrNull, isNull);
    });

    test('Err 分支取失败原因', () {
      final r = Err<int>(const ValidationFailure(message: '金额必须 > 0'));
      expect(r.isOk, false);
      expect(r.isErr, true);
      expect(r.failureOrNull, isA<ValidationFailure>());
      expect(r.failureOrNull!.message, '金额必须 > 0');
    });

    test('switch 模式匹配覆盖所有类型', () {
      final Result<String> r1 = Ok('yes');
      final Result<String> r2 = Err(NotFoundFailure(message: 'lost'));

      String show(Result<String> r) => switch (r) {
            Ok(:final value) => 'OK: $value',
            Err(:final failure) => 'ERR: ${failure.message}',
          };

      expect(show(r1), 'OK: yes');
      expect(show(r2), 'ERR: lost');
    });

    test('CategoryInUseFailure 带有关联记录数', () {
      final f = CategoryInUseFailure(recordCount: 17);
      expect(f.recordCount, 17);
      expect(f.message, contains('17'));
    });

    test('wrapExceptionCall 工具函数（带 opName）', () {
      // 模拟业务抛错时包装成 StorageFailure
      final r = wrapExceptionCall<int>(
        '读取记录',
        () => throw StateError('磁盘读错误'),
      );
      expect(r.isErr, true);
      expect(r.failureOrNull, isA<StorageFailure>());
      expect(r.failureOrNull!.cause, isA<StateError>());
    });

    test('wrapExceptionCall 正常路径', () {
      final r = wrapExceptionCall<int>('计算', () => 99);
      expect(r.isOk, true);
      expect(r.valueOrNull, 99);
    });
  });
}
