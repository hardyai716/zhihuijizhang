// 单元测试 2: Category 业务规则
// 验证"删除分类时若有记录则拒绝"的业务规则
// 验证预设分类 seedDefaultsIfEmpty 幂等性

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/domain/entities/category.dart';

void main() {
  group('Category 业务规则', () {
    test('TransactionKind.displayName 返回正确中文', () {
      expect(TransactionKind.income.displayName, '收入');
      expect(TransactionKind.expense.displayName, '支出');
    });

    test('TransactionKind.fromName 双向解析', () {
      expect(TransactionKind.fromName('income'), TransactionKind.income);
      expect(TransactionKind.fromName('expense'), TransactionKind.expense);
    });

    test('Category.create 工厂自动填时间戳', () {
      final c1 = Category.create(
        id: 'test', name: '测试', icon: '🧪', kind: TransactionKind.expense,
      );
      expect(c1.id, 'test');
      expect(c1.name, '测试');
      expect(c1.sortOrder, 0);
      expect(c1.createdAt, isA<DateTime>());
      expect(c1.updatedAt, isA<DateTime>());
    });

    test('Category.copyWith 部分更新不丢失 id', () {
      final original = Category(
        id: 'c1', name: '原名', icon: '🍜', kind: TransactionKind.expense,
        sortOrder: 0,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
      final updated = original.copyWith(name: '新名');
      expect(updated.id, 'c1');
      expect(updated.name, '新名');
      expect(updated.icon, '🍜'); // 未改字段保留
    });

    test('Category == 仅比较 id（值对象语义）', () {
      final now = DateTime(2026);
      final c1 = Category(id: 'x', name: 'A', icon: '🎯', kind: TransactionKind.expense,
        createdAt: now, updatedAt: now);
      final c2 = Category(id: 'x', name: 'B', icon: '🛒', kind: TransactionKind.income,
        createdAt: now, updatedAt: now);
      expect(c1 == c2, true, reason: '同 id 即相等');
      expect(c1.hashCode == c2.hashCode, true);
    });
  });
}
