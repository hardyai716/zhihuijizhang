/// 收支记录 - Hive 持久化模型
///
/// 与领域实体的区别：
/// - 包含 HiveType 注解 + typeId
/// - toEntity() / fromEntity() 做转换
/// - 防止领域变更直接破坏存储

import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';

part 'transaction_model.g.dart';

@HiveType(typeId: AppConstants.typeIdTransaction)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double amount;

  @HiveField(2)
  final String kind; // 'income' | 'expense'

  @HiveField(3)
  final String categoryId;

  @HiveField(4)
  final DateTime date;

  @HiveField(5)
  final String note;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.kind,
    required this.categoryId,
    required this.date,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  // ══════════════════════════════════
  // 转换方法
  // ══════════════════════════════════

  Transaction toEntity() => Transaction(
        id: id,
        amount: amount,
        kind: TransactionKind.values.byName(kind),
        categoryId: categoryId,
        date: date,
        note: note,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory TransactionModel.fromEntity(Transaction t) => TransactionModel(
        id: t.id,
        amount: t.amount,
        kind: t.kind.name,
        categoryId: t.categoryId,
        date: t.date,
        note: t.note,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      );

  /// 导入/导出 JSON 格式（与备份文件兼容）
  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'kind': kind,
        'categoryId': categoryId,
        'date': date.toIso8601String(),
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        amount: (json['amount'] as num).toDouble(),
        kind: json['kind'] as String,
        categoryId: json['categoryId'] as String,
        date: DateTime.parse(json['date'] as String),
        note: (json['note'] as String?) ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
