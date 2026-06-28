/// 预算 - Hive 持久化模型

import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/budget.dart';

part 'budget_model.g.dart';

@HiveType(typeId: AppConstants.typeIdBudget)
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String month; // "yyyy-MM"

  @HiveField(2)
  final String categoryId;

  @HiveField(3)
  final double limitAmount;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime updatedAt;

  BudgetModel({
    required this.id,
    required this.month,
    required this.categoryId,
    required this.limitAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  Budget toEntity() => Budget(
        id: id,
        month: month,
        categoryId: categoryId,
        limitAmount: limitAmount,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory BudgetModel.fromEntity(Budget b) => BudgetModel(
        id: b.id,
        month: b.month,
        categoryId: b.categoryId,
        limitAmount: b.limitAmount,
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'month': month,
        'categoryId': categoryId,
        'limitAmount': limitAmount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory BudgetModel.fromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        month: json['month'] as String,
        categoryId: json['categoryId'] as String,
        limitAmount: (json['limitAmount'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
