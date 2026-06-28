/// 领域实体：记账模板（一键复用）
import 'category.dart';

class TransactionTemplate {
  final String id;
  final String name;
  final double amount;
  final TransactionKind kind;
  final String categoryId;
  final String note;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TransactionTemplate({
    required this.id,
    required this.name,
    required this.amount,
    required this.kind,
    required this.categoryId,
    this.note = '',
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  TransactionTemplate copyWith({
    String? name,
    double? amount,
    TransactionKind? kind,
    String? categoryId,
    String? note,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return TransactionTemplate(
      id: id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
      note: note ?? this.note,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
