// 性能基准 1: 内存版 1万笔记录聚合
// 在没有真实 Hive + Flutter 环境的条件下，用纯 Dart 复刻 Notifier 的聚合算法
// 验证：1万笔交易 < 100ms 完成月份汇总与分类汇总

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/domain/entities/transaction.dart';
import 'package:smart_ledger/domain/entities/category.dart';

void main() {
  test('1万笔交易 月度+分类汇总 < 100ms', () {
    // 1. 准备 1万笔数据
    final now = DateTime.now();
    final txs = <Transaction>[];
    final categories = ['food', 'transport', 'shopping', 'housing', 'medical', 'entertainment'];
    for (int i = 0; i < 10000; i++) {
      final catId = categories[i % categories.length];
      txs.add(Transaction(
        id: 'tx-$i',
        amount: (i % 1000).toDouble() + 0.5,
        kind: i % 5 == 0 ? TransactionKind.income : TransactionKind.expense,
        categoryId: catId,
        date: DateTime(now.year, now.month, 1 + (i % 28)),
        note: '备注 $i',
        createdAt: now,
        updatedAt: now,
      ));
    }

    // 2. 预热（避免 JIT 干扰）
    for (int w = 0; w < 3; w++) {
      _runAggregation(txs, now);
    }

    // 3. 正式测试 3 次取最佳
    final times = <int>[];
    for (int r = 0; r < 3; r++) {
      final sw = Stopwatch()..start();
      final result = _runAggregation(txs, now);
      sw.stop();
      times.add(sw.elapsedMilliseconds);
      expect(result.totalExpense, greaterThan(0));
      expect(result.totalIncome, greaterThan(0));
    }

    final bestMs = times.reduce((a, b) => a < b ? a : b);
    final avgMs = (times.reduce((a, b) => a + b) / times.length).round();
    // ignore: avoid_print
    print('PERF 1万笔聚合: best=${bestMs}ms avg=${avgMs}ms (3 runs: $times)');
    expect(bestMs, lessThan(100),
        reason: '聚合 1万笔必须在 100ms 内完成（PRD 性能假设）');
  });

  test('1万笔交易 按月分组 < 50ms', () {
    final now = DateTime.now();
    final txs = <Transaction>[];
    for (int i = 0; i < 10000; i++) {
      txs.add(Transaction(
        id: 'tx-$i',
        amount: 10.0,
        kind: TransactionKind.expense,
        categoryId: 'food',
        date: DateTime(2026, 1 + (i % 12), 1 + (i % 28)),
        createdAt: now,
        updatedAt: now,
      ));
    }

    for (int w = 0; w < 3; w++) {
      _groupByMonth(txs);
    }

    final sw = Stopwatch()..start();
    final groups = _groupByMonth(txs);
    sw.stop();
    // ignore: avoid_print
    print('PERF 1万笔按月分组: ${sw.elapsedMilliseconds}ms (${groups.length} 个月)');
    expect(sw.elapsedMilliseconds, lessThan(50));
    expect(groups.length, 12);
  });

  test('1万笔交易 内存筛选 < 50ms', () {
    final now = DateTime.now();
    final txs = <Transaction>[];
    for (int i = 0; i < 10000; i++) {
      txs.add(Transaction(
        id: 'tx-$i',
        amount: (i % 500).toDouble(),
        kind: i % 3 == 0 ? TransactionKind.income : TransactionKind.expense,
        categoryId: 'food',
        date: DateTime(now.year, now.month, 1 + (i % 28)),
        note: i % 5 == 0 ? '午餐' : '其他 $i',
        createdAt: now,
        updatedAt: now,
      ));
    }

    // 预热
    for (int w = 0; w < 3; w++) {
      _searchInMemory(txs, '午餐', null, null);
    }

    final sw = Stopwatch()..start();
    final r1 = _searchInMemory(txs, '午餐', null, null);
    final r2 = _searchInMemory(txs, '', TransactionKind.expense, null);
    final r3 = _searchInMemory(txs, '', null, (a) => a >= 100 && a <= 300);
    sw.stop();
    // ignore: avoid_print
    print('PERF 1万笔 3 种筛选: ${sw.elapsedMilliseconds}ms '
        '(keyword=${r1.length}, kind=${r2.length}, range=${r3.length})');
    expect(sw.elapsedMilliseconds, lessThan(50));
  });
}

// ── 复刻 Notifier 内部算法 ──

class AggregationResult {
  final double totalExpense;
  final double totalIncome;
  final Map<String, double> expenseByCategory;
  AggregationResult(this.totalExpense, this.totalIncome, this.expenseByCategory);
}

AggregationResult _runAggregation(List<Transaction> txs, DateTime now) {
  double expense = 0, income = 0;
  final byCat = <String, double>{};
  for (final t in txs) {
    if (t.date.year != now.year || t.date.month != now.month) continue;
    if (t.kind == TransactionKind.expense) {
      expense += t.amount;
      byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
    } else {
      income += t.amount;
    }
  }
  return AggregationResult(expense, income, byCat);
}

Map<String, List<Transaction>> _groupByMonth(List<Transaction> txs) {
  final map = <String, List<Transaction>>{};
  for (final t in txs) {
    final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
    map.putIfAbsent(key, () => []);
    map[key]!.add(t);
  }
  for (final list in map.values) {
    list.sort((a, b) => b.date.compareTo(a.date));
  }
  return map;
}

List<Transaction> _searchInMemory(
  List<Transaction> txs,
  String keyword,
  TransactionKind? kind,
  bool Function(double)? amountRange,
) {
  final lower = keyword.toLowerCase();
  return txs.where((t) {
    if (keyword.isNotEmpty && !t.note.toLowerCase().contains(lower)) return false;
    if (kind != null && t.kind != kind) return false;
    if (amountRange != null && !amountRange(t.amount)) return false;
    return true;
  }).toList();
}
