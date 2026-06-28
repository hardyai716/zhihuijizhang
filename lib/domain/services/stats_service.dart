/// StatsService —— 统计聚合服务
///
/// 职责：在 Repository 之上做内存聚合计算
///
/// 性能注意：
/// - MVP 数据量（≤1万笔），全量扫描+GroupBy 不会卡顿
/// - 若未来数据量爆炸，可引入 in-memory index
///
/// 关键设计：
/// - 所有方法都是纯函数（除依赖 Repository 外无副作用）
/// - 返回领域对象，不依赖 Flutter UI

import '../../core/errors/result.dart';
import '../../core/failures/failure.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';

class StatsService {
  StatsService({
    required TransactionRepository txRepo,
    required CategoryRepository catRepo,
  })  : _txRepo = txRepo,
        _catRepo = catRepo;

  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;

  // ══════════════════════════════════
  // 周期汇总
  // ══════════════════════════════════

  /// 周期内汇总（总收/总支/结余/笔数）
  Result<PeriodSummary> summarize(DateRange range) {
    final txResult = _txRepo.findByDateRange(range.start, range.end);
    if (txResult.isErr) return Err(txResult.failureOrNull!);

    final txs = txResult.valueOrNull!;
    double income = 0, expense = 0;
    int incomeCount = 0, expenseCount = 0;

    for (final t in txs) {
      if (t.kind == TransactionKind.income) {
        income += t.amount;
        incomeCount++;
      } else {
        expense += t.amount;
        expenseCount++;
      }
    }

    return Ok(PeriodSummary(
      range: range,
      totalIncome: income,
      totalExpense: expense,
      balance: income - expense,
      incomeCount: incomeCount,
      expenseCount: expenseCount,
    ));
  }

  /// 本月汇总（快捷方法）
  Result<PeriodSummary> thisMonth() => summarize(DateRange.thisMonth());

  // ══════════════════════════════════
  // 按分类聚合
  // ══════════════════════════════════

  /// 周期内按分类聚合（仅支出，用于饼图）
  Result<List<CategoryAggregate>> aggregateByCategory({
    required DateRange range,
    TransactionKind kind = TransactionKind.expense,
  }) {
    final txResult = _txRepo.findByDateRange(range.start, range.end);
    if (txResult.isErr) return Err(txResult.failureOrNull!);

    final catResult = _catRepo.getAll();
    if (catResult.isErr) return Err(catResult.failureOrNull!);

    final txs = txResult.valueOrNull!.where((t) => t.kind == kind);
    final cats = {for (final c in catResult.valueOrNull!) c.id: c};

    // 分组累加
    final sums = <String, double>{};
    for (final t in txs) {
      sums[t.categoryId] = (sums[t.categoryId] ?? 0) + t.amount;
    }

    final total = sums.values.fold(0.0, (a, b) => a + b);
    final list = sums.entries.map((e) {
      final cat = cats[e.key];
      return CategoryAggregate(
        categoryId: e.key,
        categoryName: cat?.name ?? '未分类',
        categoryIcon: cat?.icon ?? '📌',
        amount: e.value,
        percentage: total > 0 ? e.value / total : 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Ok(list);
  }

  // ══════════════════════════════════
  // 时间序列
  // ══════════════════════════════════

  /// 按日聚合（用于折线图）
  Result<List<DailyAggregate>> aggregateByDay(DateRange range) {
    final txResult = _txRepo.findByDateRange(range.start, range.end);
    if (txResult.isErr) return Err(txResult.failureOrNull!);

    final byDay = <String, DailyAggregate>{};
    // 初始化所有日期为 0（避免折线断点）
    for (DateTime d = range.start;
        !d.isAfter(range.end);
        d = d.add(const Duration(days: 1))) {
      final key = Formatters.date(d);
      byDay[key] = DailyAggregate(date: d, income: 0, expense: 0);
    }

    for (final t in txResult.valueOrNull!) {
      final key = Formatters.date(t.date);
      final agg = byDay[key]!;
      if (t.kind == TransactionKind.income) {
        byDay[key] = DailyAggregate(
          date: agg.date, income: agg.income + t.amount, expense: agg.expense,
        );
      } else {
        byDay[key] = DailyAggregate(
          date: agg.date, income: agg.income, expense: agg.expense + t.amount,
        );
      }
    }

    return Ok(byDay.values.toList()..sort((a, b) => a.date.compareTo(b.date)));
  }

  /// 按月聚合（用于趋势图）
  Result<List<MonthlyAggregate>> aggregateByMonth(int year) {
    final start = DateTime(year, 1, 1);
    final end = DateTime(year, 12, 31, 23, 59, 59);
    final txResult = _txRepo.findByDateRange(start, end);
    if (txResult.isErr) return Err(txResult.failureOrNull!);

    final byMonth = <int, List<Transaction>>{};
    for (int m = 1; m <= 12; m++) {
      byMonth[m] = [];
    }
    for (final t in txResult.valueOrNull!) {
      byMonth[t.date.month]!.add(t);
    }

    final list = byMonth.entries.map((e) {
      double income = 0, expense = 0;
      for (final t in e.value) {
        if (t.kind == TransactionKind.income) {
          income += t.amount;
        } else {
          expense += t.amount;
        }
      }
      return MonthlyAggregate(
        year: year,
        month: e.key,
        income: income,
        expense: expense,
        balance: income - expense,
      );
    }).toList();

    return Ok(list);
  }

  // ══════════════════════════════════
  // 排行
  // ══════════════════════════════════

  /// Top N 分类排行（用于统计页排行列表）
  Result<List<CategoryAggregate>> topCategories({
    required DateRange range,
    int limit = 10,
    TransactionKind kind = TransactionKind.expense,
  }) {
    final aggResult = aggregateByCategory(range: range, kind: kind);
    if (aggResult.isErr) return Err(aggResult.failureOrNull!);
    final list = aggResult.valueOrNull!;
    return Ok(list.take(limit).toList());
  }
}

// ══════════════════════════════════
// 统计结果领域对象
// ══════════════════════════════════

class PeriodSummary {
  final DateRange range;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final int incomeCount;
  final int expenseCount;

  const PeriodSummary({
    required this.range,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.incomeCount,
    required this.expenseCount,
  });

  int get totalCount => incomeCount + expenseCount;
}

class CategoryAggregate {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final double amount;
  final double percentage; // 0.0 ~ 1.0

  const CategoryAggregate({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.amount,
    required this.percentage,
  });
}

class DailyAggregate {
  final DateTime date;
  final double income;
  final double expense;

  const DailyAggregate({
    required this.date,
    required this.income,
    required this.expense,
  });

  double get balance => income - expense;
}

class MonthlyAggregate {
  final int year;
  final int month;
  final double income;
  final double expense;
  final double balance;

  const MonthlyAggregate({
    required this.year,
    required this.month,
    required this.income,
    required this.expense,
    required this.balance,
  });
}
