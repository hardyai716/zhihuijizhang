/// 领域实体：月度预算
import 'category.dart';

class Budget {
  final String id;
  /// "yyyy-MM" 格式的月份
  final String month;
  final String categoryId;
  final double limitAmount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Budget({
    required this.id,
    required this.month,
    required this.categoryId,
    required this.limitAmount,
    required this.createdAt,
    required this.updatedAt,
  });

  Budget copyWith({
    double? limitAmount,
    DateTime? updatedAt,
  }) {
    return Budget(
      id: id,
      month: month,
      categoryId: categoryId,
      limitAmount: limitAmount ?? this.limitAmount,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}

/// 预算执行情况（计算结果，非持久化）
class BudgetStatus {
  final Budget budget;
  final double spent;
  final double remaining;
  final double progress; // 0.0 ~ 1.0+

  const BudgetStatus({
    required this.budget,
    required this.spent,
    required this.remaining,
    required this.progress,
  });

  /// 是否已超预算
  bool get isOverBudget => spent > budget.limitAmount;

  /// 是否需要预警（>=80%）
  bool get isWarning => progress >= 0.8 && !isOverBudget;
}
