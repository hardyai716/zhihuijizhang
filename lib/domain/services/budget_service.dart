/// BudgetService —— 预算执行计算
///
/// 预算本身只存上限，实际支出由 StatsService 实时聚合
/// BudgetService = BudgetRepository + StatsService 的组合

import '../../core/errors/result.dart';
import '../../core/failures/failure.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/category.dart';
import '../../data/repositories/budget_repository.dart';
import '../../data/repositories/transaction_repository.dart';
import 'stats_service.dart';

class BudgetService {
  BudgetService({
    required BudgetRepository budgetRepo,
    required TransactionRepository txRepo,
    required StatsService statsService,
  })  : _budgetRepo = budgetRepo,
        _txRepo = txRepo,
        _stats = statsService;

  final BudgetRepository _budgetRepo;
  final TransactionRepository _txRepo;
  final StatsService _stats;

  /// 获取某月所有预算的执行情况
  Result<List<BudgetStatus>> getMonthStatus(String month) {
    final budgetsResult = _budgetRepo.findByMonth(month);
    if (budgetsResult.isErr) return Err(budgetsResult.failureOrNull!);

    final budgets = budgetsResult.valueOrNull!;
    if (budgets.isEmpty) return const Ok([]);

    // 一次性查出本月所有支出，再按分类聚合
    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final range = DateRange(
      start: Formatters.startOfMonth(DateTime(year, m)),
      end: Formatters.endOfMonth(DateTime(year, m)),
    );

    final aggResult = _stats.aggregateByCategory(
      range: range,
      kind: TransactionKind.expense,
    );
    if (aggResult.isErr) return Err(aggResult.failureOrNull!);

    final spentByCat = {
      for (final a in aggResult.valueOrNull!) a.categoryId: a.amount,
    };

    final statuses = budgets.map((b) {
      final spent = spentByCat[b.categoryId] ?? 0;
      final progress = b.limitAmount > 0 ? spent / b.limitAmount : 0.0;
      return BudgetStatus(
        budget: b,
        spent: spent,
        remaining: b.limitAmount - spent,
        progress: progress.toDouble(),
      );
    }).toList();

    return Ok(statuses);
  }

  /// 获取超预算的分类
  Result<List<BudgetStatus>> getOverBudgets(String month) {
    final all = getMonthStatus(month);
    if (all.isErr) return Err(all.failureOrNull!);
    return Ok(all.valueOrNull!.where((s) => s.isOverBudget).toList());
  }

  /// 获取需要预警的分类（>=80% 或超支）
  Result<List<BudgetStatus>> getWarnings(String month) {
    final all = getMonthStatus(month);
    if (all.isErr) return Err(all.failureOrNull!);
    return Ok(
      all.valueOrNull!.where((s) => s.isWarning || s.isOverBudget).toList(),
    );
  }
}
