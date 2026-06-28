import '../errors/result.dart';

/// 业务失败类型 —— 所有可预期的失败都应包装为 Failure
///
/// 失败 vs 异常：
/// - Failure：业务可预期的失败（输入校验失败、数据不存在、磁盘满）
/// - Exception：程序员的 bug（NullPointer、StackOverflow）
///
/// 业务层只返回 Failure，绝不抛出 Exception
sealed class Failure {
  final String message;
  final String? code; // 用于 i18n 或埋点
  final Object? cause; // 原始错误，便于排查

  const Failure({
    required this.message,
    this.code,
    this.cause,
  });

  @override
  String toString() => 'Failure($code): $message';
}

// ══════════════════════════════════
// 输入校验失败
// ══════════════════════════════════

class ValidationFailure extends Failure {
  const ValidationFailure({
    required super.message,
    super.code = 'VALIDATION_ERROR',
    super.cause,
  });
}

// ══════════════════════════════════
// 数据未找到
// ══════════════════════════════════

class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required super.message,
    super.code = 'NOT_FOUND',
    super.cause,
  });
}

// ══════════════════════════════════
// 存储层失败（Hive 读写错误）
// ══════════════════════════════════

class StorageFailure extends Failure {
  const StorageFailure({
    required super.message,
    super.code = 'STORAGE_ERROR',
    super.cause,
  });
}

/// Hive 文件损坏 —— 严重错误，需提示用户从备份恢复
class CorruptedDataFailure extends StorageFailure {
  const CorruptedDataFailure({
    super.message = '数据文件已损坏，请从备份恢复',
    super.code = 'STORAGE_CORRUPTED',
    super.cause,
  });
}

// ══════════════════════════════════
// 业务规则违反
// ══════════════════════════════════

class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure({
    required super.message,
    super.code = 'BUSINESS_RULE_VIOLATION',
    super.cause,
  });
}

/// 分类下仍有记录，不允许删除
class CategoryInUseFailure extends BusinessRuleFailure {
  final int recordCount;
  CategoryInUseFailure({
    required this.recordCount,
    String? message,
    super.cause,
  }) : super(
          message: message ?? '该分类下还有 $recordCount 条记录，无法删除',
          code: 'CATEGORY_IN_USE',
        );
}

// ══════════════════════════════════
// 文件操作失败
// ══════════════════════════════════

class FileFailure extends Failure {
  const FileFailure({
    required super.message,
    super.code = 'FILE_ERROR',
    super.cause,
  });
}

// ══════════════════════════════════
// 导入失败（数据迁移/CSV 导入）
// ══════════════════════════════════

class ImportFailure extends Failure {
  /// 第几行出错（1-based），用于定位
  final int? line;

  const ImportFailure({
    required super.message,
    this.line,
    super.code = 'IMPORT_ERROR',
    super.cause,
  });
}

// ══════════════════════════════════
// 工具：将 Exception 包装为 Failure
// ══════════════════════════════════

/// 兜底工具：捕获所有 Exception，包装为 StorageFailure
/// 用在 try/catch 的最外层，避免原始异常逃逸到 UI
Failure wrapException(Object e, [StackTrace? st]) {
  if (e is Failure) return e;
  return StorageFailure(
    message: '操作失败: ${e.toString()}',
    cause: e,
  );
}

/// 便捷版：传入操作名 + lambda，自动捕获异常并包装
/// 业务方法推荐用这种：
/// ```dart
/// return wrapException('读取分类', () => _local.categories.values.toList());
/// ```
Result<T> wrapExceptionCall<T>(String opName, T Function() body) {
  try {
    return Ok(body());
  } catch (e, st) {
    return Err(wrapException(e, st));
  }
}
