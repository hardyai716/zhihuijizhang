// Happy Path 集成测试：模拟从启动到备份恢复的完整链路
// 不依赖 Flutter/Hive，纯 Dart 跑核心业务逻辑

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/core/errors/result.dart';
import 'package:smart_ledger/core/failures/failure.dart';
import 'package:smart_ledger/domain/entities/transaction.dart';
import 'package:smart_ledger/domain/entities/category.dart';

void main() {
  group('Happy Path 端到端', () {
    test('Step1 启动 → Step2 记账 → Step3 统计 → Step4 备份 → Step5 恢复', () {
      // ── 模拟 1：内存版"分类 + 交易 + 备份"全链路 ──
      final inMemoryStore = _InMemoryStore();

      // ① 启动 → seed 预设分类
      final seedR = inMemoryStore.seedDefaultCategories();
      expect(seedR.isOk, true, reason: '首次启动应成功 seed');
      expect(inMemoryStore.categories.length, 8,
          reason: '6 个支出 + 2 个收入');

      // ② 用户记账 5 笔
      final now = DateTime.now();
      final txns = [
        Transaction(id: '1', amount: 35, kind: TransactionKind.expense,
          categoryId: 'food', date: now, note: '午餐',
          createdAt: now, updatedAt: now),
        Transaction(id: '2', amount: 12, kind: TransactionKind.expense,
          categoryId: 'transport', date: now, note: '地铁',
          createdAt: now, updatedAt: now),
        Transaction(id: '3', amount: 15000, kind: TransactionKind.income,
          categoryId: 'salary', date: now, note: '工资',
          createdAt: now, updatedAt: now),
        Transaction(id: '4', amount: 89, kind: TransactionKind.expense,
          categoryId: 'shopping', date: now, note: '超市',
          createdAt: now, updatedAt: now),
        Transaction(id: '5', amount: 58, kind: TransactionKind.expense,
          categoryId: 'food', date: now, note: '晚餐',
          createdAt: now, updatedAt: now),
      ];
      for (final t in txns) {
        final r = inMemoryStore.addTransaction(t);
        expect(r.isOk, true, reason: '记账应成功: ${t.id}');
      }
      expect(inMemoryStore.transactions.length, 5);

      // ③ 统计验证：本月支出 35+12+89+58=194，收入 15000
      final stats = inMemoryStore.computeMonthlyStats(now);
      expect(stats.totalExpense, 194);
      expect(stats.totalIncome, 15000);
      expect(stats.balance, 15000 - 194);
      expect(stats.expenseByCategory['food'], 35 + 58);
      expect(stats.expenseByCategory['transport'], 12);
      expect(stats.expenseByCategory['shopping'], 89);

      // ④ 备份 → 序列化为 JSON
      final backup = inMemoryStore.exportToJson();
      expect(backup, isNotEmpty);
      expect(backup, contains('"id":"1"'));
      expect(backup, contains('"amount":35.0'));

      // ⑤ 清空 → 恢复
      inMemoryStore.clearAll();
      expect(inMemoryStore.transactions.length, 0);
      expect(inMemoryStore.categories.length, 0);

      final restoreR = inMemoryStore.importFromJson(backup);
      expect(restoreR.isOk, true, reason: '恢复应成功');
      expect(inMemoryStore.transactions.length, 5);
      // 分类不在备份范围内，恢复后仍为 0（备份只覆盖交易）

      // ⑥ 恢复后统计应一致
      final stats2 = inMemoryStore.computeMonthlyStats(now);
      expect(stats2.totalExpense, 194);
      expect(stats2.totalIncome, 15000);
    });

    test('Step6 业务规则：删除有记录的分类应拒绝', () {
      final store = _InMemoryStore();
      store.seedDefaultCategories();
      final now = DateTime.now();
      store.addTransaction(Transaction(
        id: 't1', amount: 10, kind: TransactionKind.expense,
        categoryId: 'food', date: now, createdAt: now, updatedAt: now,
      ));

      // 尝试删除 food 分类（有 1 笔记录）→ 应失败
      final r = store.deleteCategory('food');
      expect(r.isErr, true);
      expect(r.failureOrNull, isA<CategoryInUseFailure>());
      expect((r.failureOrNull! as CategoryInUseFailure).recordCount, 1);

      // 验证 food 分类仍在
      expect(store.categories.containsKey('food'), true);

      // 强制删除 → 应成功
      final r2 = store.deleteCategory('food', force: true);
      expect(r2.isOk, true);
      expect(store.categories.containsKey('food'), false);
    });

    test('Step7 业务规则：删除空分类应成功', () {
      final store = _InMemoryStore();
      store.seedDefaultCategories();

      // 删除 medical（预设里无记录）
      final r = store.deleteCategory('medical');
      expect(r.isOk, true);
      expect(store.categories.containsKey('medical'), false);
      expect(store.categories.length, 7);
    });

    test('Step8 业务规则：重复 ID 拒绝', () {
      final store = _InMemoryStore();
      store.seedDefaultCategories();
      final now = DateTime.now();
      final r = store.addCategory(Category(
        id: 'food',  // 已存在
        name: '重名分类', icon: '🎯', kind: TransactionKind.expense,
        createdAt: now, updatedAt: now,
      ));
      expect(r.isErr, true);
      expect(r.failureOrNull, isA<BusinessRuleFailure>());
    });

    test('Step9 业务规则：空分类名拒绝', () {
      final store = _InMemoryStore();
      store.seedDefaultCategories();
      final now = DateTime.now();
      final r = store.addCategory(Category(
        id: 'new1', name: '  ', icon: '🎯', kind: TransactionKind.expense,
        createdAt: now, updatedAt: now,
      ));
      expect(r.isErr, true);
      expect(r.failureOrNull, isA<ValidationFailure>());
    });
  });
}

// ═══════════════════════════════════════
// 内存版全链路 stub —— 复刻 Repository 业务规则
// ═══════════════════════════════════════

class _InMemoryStore {
  final Map<String, Category> categories = {};
  final Map<String, Transaction> transactions = {};

  // ── 业务规则（复刻 CategoryRepository / TransactionRepository）──

  static const _maxCategoryNameLength = 8;

  Result<void> seedDefaultCategories() {
    if (categories.isNotEmpty) return const Ok(null);
    final now = DateTime.now();
    final defaults = [
      Category(id: 'food', name: '餐饮', icon: '🍜',
        kind: TransactionKind.expense, sortOrder: 0,
        createdAt: now, updatedAt: now),
      Category(id: 'transport', name: '交通', icon: '🚗',
        kind: TransactionKind.expense, sortOrder: 1,
        createdAt: now, updatedAt: now),
      Category(id: 'shopping', name: '购物', icon: '🛍️',
        kind: TransactionKind.expense, sortOrder: 2,
        createdAt: now, updatedAt: now),
      Category(id: 'entertainment', name: '娱乐', icon: '🎮',
        kind: TransactionKind.expense, sortOrder: 3,
        createdAt: now, updatedAt: now),
      Category(id: 'housing', name: '居住', icon: '🏠',
        kind: TransactionKind.expense, sortOrder: 4,
        createdAt: now, updatedAt: now),
      Category(id: 'medical', name: '医疗', icon: '💊',
        kind: TransactionKind.expense, sortOrder: 5,
        createdAt: now, updatedAt: now),
      Category(id: 'salary', name: '工资', icon: '💰',
        kind: TransactionKind.income, sortOrder: 0,
        createdAt: now, updatedAt: now),
      Category(id: 'other_income', name: '其他', icon: '📦',
        kind: TransactionKind.income, sortOrder: 1,
        createdAt: now, updatedAt: now),
    ];
    for (final c in defaults) {
      categories[c.id] = c;
    }
    return const Ok(null);
  }

  Result<void> addTransaction(Transaction t) {
    if (t.amount <= 0) {
      return const Err(ValidationFailure(message: '金额必须 > 0'));
    }
    if (!categories.containsKey(t.categoryId)) {
      return Err(NotFoundFailure(message: '分类不存在: ${t.categoryId}'));
    }
    transactions[t.id] = t;
    return const Ok(null);
  }

  Result<void> addCategory(Category c) {
    if (c.name.trim().isEmpty) {
      return const Err(ValidationFailure(message: '分类名称不能为空'));
    }
    if (c.name.length > _maxCategoryNameLength) {
      return Err(ValidationFailure(
        message: '分类名称最多 $_maxCategoryNameLength 字',
      ));
    }
    if (categories.containsKey(c.id)) {
      return Err(BusinessRuleFailure(
        message: '分类ID已存在: ${c.id}',
        code: 'DUPLICATE_ID',
      ));
    }
    categories[c.id] = c;
    return const Ok(null);
  }

  Result<void> deleteCategory(String id, {bool force = false}) {
    if (!categories.containsKey(id)) return const Ok(null);
    final count = transactions.values.where((t) => t.categoryId == id).length;
    if (count > 0 && !force) {
      return Err(CategoryInUseFailure(recordCount: count));
    }
    categories.remove(id);
    return const Ok(null);
  }

  _Stats computeMonthlyStats(DateTime now) {
    double expense = 0, income = 0;
    final byCat = <String, double>{};
    for (final t in transactions.values) {
      if (t.date.year != now.year || t.date.month != now.month) continue;
      if (t.kind == TransactionKind.expense) {
        expense += t.amount;
        byCat[t.categoryId] = (byCat[t.categoryId] ?? 0) + t.amount;
      } else {
        income += t.amount;
      }
    }
    return _Stats(expense, income, byCat);
  }

  // ── 备份/恢复（模拟 BackupService 的 JSON 序列化）──

  String exportToJson() {
    final list = transactions.values.map((t) => {
          'id': t.id, 'amount': t.amount, 'kind': t.kind.name,
          'categoryId': t.categoryId, 'date': t.date.toIso8601String(),
          'note': t.note,
          'createdAt': t.createdAt.toIso8601String(),
          'updatedAt': t.updatedAt.toIso8601String(),
        }).toList();
    return jsonEncode({'version': 1, 'transactions': list});
  }

  Result<void> importFromJson(String json) {
    // 用 jsonDecode 替代手写 regex 解析
    final dynamic decoded = jsonDecode(json);
    final List<dynamic> list = decoded['transactions'] as List<dynamic>;
    for (final e in list) {
      final m = e as Map<String, dynamic>;
      final t = Transaction(
        id: m['id'] as String,
        amount: (m['amount'] as num).toDouble(),
        kind: TransactionKind.fromName(m['kind'] as String),
        categoryId: m['categoryId'] as String,
        date: DateTime.parse(m['date'] as String),
        note: m['note'] as String? ?? '',
        createdAt: DateTime.parse(m['createdAt'] as String),
        updatedAt: DateTime.parse(m['updatedAt'] as String),
      );
      transactions[t.id] = t;
    }
    return const Ok(null);
  }

  void clearAll() {
    categories.clear();
    transactions.clear();
  }
}

class _Stats {
  final double totalExpense;
  final double totalIncome;
  final Map<String, double> expenseByCategory;
  double get balance => totalIncome - totalExpense;
  _Stats(this.totalExpense, this.totalIncome, this.expenseByCategory);
}
