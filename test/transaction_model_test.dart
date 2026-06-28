// 单元测试 1: Transaction 实体 + 转换
// 验证领域模型在 Entity ↔ Model 转换时的字段保真度
//
// 这是手写测试，可由 `flutter test` 直接执行（如果环境装好 Flutter）
// 也可以人工 review 验证逻辑正确性

import 'package:flutter_test/flutter_test.dart';
import 'package:smart_ledger/data/models/transaction_model.dart';
import 'package:smart_ledger/domain/entities/transaction.dart';
import 'package:smart_ledger/domain/entities/category.dart';

void main() {
  group('Transaction Entity ↔ Model', () {
    test('往返转换字段保真', () {
      final now = DateTime(2026, 6, 28, 12, 30, 0);
      final entity = Transaction(
        id: 'tx-1',
        amount: 35.5,
        kind: TransactionKind.expense,
        categoryId: 'food',
        date: now,
        note: '午餐',
        createdAt: now,
        updatedAt: now,
      );

      // Entity → Model
      final model = TransactionModel.fromEntity(entity);
      expect(model.id, 'tx-1');
      expect(model.amount, 35.5);
      expect(model.kind, 'expense');
      expect(model.categoryId, 'food');
      expect(model.note, '午餐');

      // Model → Entity
      final back = model.toEntity();
      expect(back, entity);
      expect(back.kind, TransactionKind.expense);
    });

    test('JSON 序列化往返保真', () {
      final now = DateTime(2026, 6, 28, 12, 30, 0);
      final original = Transaction(
        id: 'tx-2',
        amount: 100.0,
        kind: TransactionKind.income,
        categoryId: 'salary',
        date: now,
        note: '工资',
        createdAt: now,
        updatedAt: now,
      );

      final model = TransactionModel.fromEntity(original);
      final json = model.toJson();
      final restored = TransactionModel.fromJson(json);
      final back = restored.toEntity();

      expect(back.id, original.id);
      expect(back.amount, original.amount);
      expect(back.kind, original.kind);
      expect(back.categoryId, original.categoryId);
      expect(back.note, original.note);
    });

    test('signedAmount 正负号正确', () {
      final now = DateTime(2026);
      final expense = Transaction(
        id: 'e1', amount: 50, kind: TransactionKind.expense,
        categoryId: 'food', date: now,
        createdAt: now, updatedAt: now,
      );
      final income = Transaction(
        id: 'i1', amount: 50, kind: TransactionKind.income,
        categoryId: 'salary', date: now,
        createdAt: now, updatedAt: now,
      );
      expect(expense.signedAmount, -50);
      expect(income.signedAmount, 50);
    });
  });
}
