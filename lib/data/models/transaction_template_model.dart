/// 记账模板 - Hive 持久化模型

import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/transaction_template.dart';
import '../../domain/entities/category.dart';

part 'transaction_template_model.g.dart';

@HiveType(typeId: AppConstants.typeIdTemplate)
class TransactionTemplateModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final String kind;

  @HiveField(4)
  final String categoryId;

  @HiveField(5)
  final String note;

  @HiveField(6)
  final int sortOrder;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  TransactionTemplateModel({
    required this.id,
    required this.name,
    required this.amount,
    required this.kind,
    required this.categoryId,
    required this.note,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  TransactionTemplate toEntity() => TransactionTemplate(
        id: id,
        name: name,
        amount: amount,
        kind: TransactionKind.values.byName(kind),
        categoryId: categoryId,
        note: note,
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory TransactionTemplateModel.fromEntity(TransactionTemplate t) =>
      TransactionTemplateModel(
        id: t.id,
        name: t.name,
        amount: t.amount,
        kind: t.kind.name,
        categoryId: t.categoryId,
        note: t.note,
        sortOrder: t.sortOrder,
        createdAt: t.createdAt,
        updatedAt: t.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'kind': kind,
        'categoryId': categoryId,
        'note': note,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory TransactionTemplateModel.fromJson(Map<String, dynamic> json) =>
      TransactionTemplateModel(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        kind: json['kind'] as String,
        categoryId: json['categoryId'] as String,
        note: (json['note'] as String?) ?? '',
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
