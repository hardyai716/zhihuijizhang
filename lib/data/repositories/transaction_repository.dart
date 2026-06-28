/// Transaction Repository —— 收支记录的仓储
///
/// 职责：
/// - 把 DataSource 的 Hive Model 转换为领域 Entity
/// - 业务校验（金额范围、必填字段）
/// - 返回 Result<T>，不抛异常
/// - 提供 Stream 供 UI 响应式监听
///
/// 调用方：TransactionService、Providers

import 'dart:async';
import 'package:hive/hive.dart';
import '../../core/errors/result.dart';
import '../../core/failures/failure.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import '../sources/local/hive_local_data_source.dart';
import '../models/transaction_model.dart';

class TransactionRepository {
  TransactionRepository(this._local);
  final HiveLocalDataSource _local;

  Box<TransactionModel> get _box => _local.transactions;

  // ══════════════════════════════════
  // 读取
  // ══════════════════════════════════

  /// 获取全部记录（按日期倒序）
  Result<List<Transaction>> getAll() {
    try {
      final list = _box.values.map((m) => m.toEntity()).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return Ok(list);
    } catch (e, st) {
      AppLog.e(AppConstants.logTagRepo, 'getAll 失败', e, st);
      return Err(StorageFailure(message: '读取记录失败', cause: e));
    }
  }

  /// 按 ID 查找
  Result<Transaction?> findById(String id) {
    try {
      final model = _box.get(id);
      return Ok(model?.toEntity());
    } catch (e) {
      return Err(StorageFailure(message: '查找记录失败', cause: e));
    }
  }

  /// 按时间范围查询
  Result<List<Transaction>> findByDateRange(DateTime start, DateTime end) {
    try {
      final list = _box.values
          .where((m) => !m.date.isBefore(start) && !m.date.isAfter(end))
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return Ok(list);
    } catch (e) {
      return Err(StorageFailure(message: '按时间范围查询失败', cause: e));
    }
  }

  /// 按分类 ID 查询（用于删除分类时统计）
  Result<List<Transaction>> findByCategoryId(String categoryId) {
    try {
      final list = _box.values
          .where((m) => m.categoryId == categoryId)
          .map((m) => m.toEntity())
          .toList();
      return Ok(list);
    } catch (e) {
      return Err(StorageFailure(message: '按分类查询失败', cause: e));
    }
  }

  /// 关键词搜索（匹配备注/分类名/金额）
  /// 注意：分类名匹配需要在调用方配合（先查分类表）
  Result<List<Transaction>> search({
    required String keyword,
    DateTime? startDate,
    DateTime? endDate,
    TransactionKind? kind,
  }) {
    try {
      final lower = keyword.toLowerCase();
      final list = _box.values
          .where((m) {
            // 备注匹配
            if (m.note.toLowerCase().contains(lower)) return true;
            // 金额匹配（"12.5" → 匹配 12.5 / 12.50 / 125）
            final amountStr = m.amount.toStringAsFixed(2);
            if (amountStr.contains(lower)) return true;
            // 分类 ID 匹配（由调用方再过滤）
            if (m.categoryId.toLowerCase().contains(lower)) return true;
            return false;
          })
          .where((m) {
            if (startDate != null && m.date.isBefore(startDate)) return false;
            if (endDate != null && m.date.isAfter(endDate)) return false;
            if (kind != null && m.kind != kind.name) return false;
            return true;
          })
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      return Ok(list);
    } catch (e) {
      return Err(StorageFailure(message: '搜索失败', cause: e));
    }
  }

  /// 分页查询（按日期倒序）
  Result<List<Transaction>> findPaged({
    required int offset,
    int limit = AppConstants.pageSize,
  }) {
    try {
      final all = _box.values.map((m) => m.toEntity()).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      final end = (offset + limit).clamp(0, all.length);
      final start = offset.clamp(0, end);
      return Ok(all.sublist(start, end));
    } catch (e) {
      return Err(StorageFailure(message: '分页查询失败', cause: e));
    }
  }

  // ══════════════════════════════════
  // 写入
  // ══════════════════════════════════

  /// 新增记录（含业务校验）
  Result<Transaction> add(Transaction t) {
    // 业务校验
    final validation = _validate(t);
    if (validation != null) return Err(validation);

    try {
      _box.put(t.id, TransactionModel.fromEntity(t));
      AppLog.repo('新增记录 ${t.id} amount=${t.amount} kind=${t.kind}');
      return Ok(t);
    } catch (e, st) {
      AppLog.e(AppConstants.logTagRepo, 'add 失败', e, st);
      return Err(StorageFailure(message: '保存记录失败', cause: e));
    }
  }

  /// 更新记录
  Result<Transaction> update(Transaction t) {
    final validation = _validate(t);
    if (validation != null) return Err(validation);

    if (!_box.containsKey(t.id)) {
      return Err(NotFoundFailure(message: '记录不存在: ${t.id}'));
    }

    try {
      _box.put(t.id, TransactionModel.fromEntity(t));
      AppLog.repo('更新记录 ${t.id}');
      return Ok(t);
    } catch (e) {
      return Err(StorageFailure(message: '更新记录失败', cause: e));
    }
  }

  /// 删除记录
  Result<void> delete(String id) {
    try {
      _box.delete(id);
      AppLog.repo('删除记录 $id');
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(message: '删除记录失败', cause: e));
    }
  }

  /// 批量删除
  Result<int> deleteMany(List<String> ids) {
    try {
      _box.deleteAll(ids);
      AppLog.repo('批量删除 ${ids.length} 条');
      return Ok(ids.length);
    } catch (e) {
      return Err(StorageFailure(message: '批量删除失败', cause: e));
    }
  }

  // ══════════════════════════════════
  // 业务校验
  // ══════════════════════════════════

  ValidationFailure? _validate(Transaction t) {
    if (t.amount < AppConstants.minAmount) {
      return ValidationFailure(message: '金额不能小于 ¥${AppConstants.minAmount}');
    }
    if (t.amount > AppConstants.maxAmount) {
      return ValidationFailure(
        message: '金额不能超过 ¥${Formatters.amount(AppConstants.maxAmount)}',
      );
    }
    if (t.note.length > AppConstants.maxNoteLength) {
      return ValidationFailure(
        message: '备注最多 ${AppConstants.maxNoteLength} 字',
      );
    }
    if (t.categoryId.isEmpty) {
      return const ValidationFailure(message: '请选择分类');
    }
    return null;
  }

  // ══════════════════════════════════
  // 响应式监听
  // ══════════════════════════════════

  /// 监听 Box 变化 —— 任何新增/更新/删除都会触发
  Stream<void> watch() => _box.watch().map((_) => null);
}
