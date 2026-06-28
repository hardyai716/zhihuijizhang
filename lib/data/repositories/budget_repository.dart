/// Budget Repository —— 预算仓储

import '../../core/errors/result.dart';
import '../../core/failures/failure.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_log.dart';
import '../../domain/entities/budget.dart';
import '../sources/local/hive_local_data_source.dart';
import '../models/budget_model.dart';

class BudgetRepository {
  BudgetRepository(this._local);
  final HiveLocalDataSource _local;

  // ══════════════════════════════════
  // 读取
  // ══════════════════════════════════

  Result<List<Budget>> getAll() {
    try {
      final list = _local.budgets.values.map((m) => m.toEntity()).toList()
        ..sort((a, b) => b.month.compareTo(a.month));
      return Ok(list);
    } catch (e) {
      return Err(StorageFailure(message: '读取预算失败', cause: e));
    }
  }

  Result<List<Budget>> findByMonth(String month) {
    try {
      final list = _local.budgets.values
          .where((m) => m.month == month)
          .map((m) => m.toEntity())
          .toList();
      return Ok(list);
    } catch (e) {
      return Err(StorageFailure(message: '查询预算失败', cause: e));
    }
  }

  // ══════════════════════════════════
  // 写入
  // ══════════════════════════════════

  Result<Budget> set(Budget b) {
    final v = _validate(b);
    if (v != null) return Err(v);

    try {
      _local.budgets.put(b.id, BudgetModel.fromEntity(b));
      AppLog.repo('设置预算 ${b.month}/${b.categoryId} = ${b.limitAmount}');
      return Ok(b);
    } catch (e) {
      return Err(StorageFailure(message: '保存预算失败', cause: e));
    }
  }

  Result<void> delete(String id) {
    try {
      _local.budgets.delete(id);
      AppLog.repo('删除预算 $id');
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(message: '删除预算失败', cause: e));
    }
  }

  ValidationFailure? _validate(Budget b) {
    if (b.limitAmount <= 0) {
      return const ValidationFailure(message: '预算金额必须大于0');
    }
    if (b.limitAmount > AppConstants.maxAmount) {
      return const ValidationFailure(message: '预算金额超出上限');
    }
    if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(b.month)) {
      return const ValidationFailure(message: '月份格式错误（应为 yyyy-MM）');
    }
    if (b.categoryId.isEmpty) {
      return const ValidationFailure(message: '请选择分类');
    }
    return null;
  }
}
