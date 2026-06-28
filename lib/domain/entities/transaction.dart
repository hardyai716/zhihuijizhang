/// 领域实体：收支记录

import 'category.dart';

class Transaction {
  final String id;
  final double amount; // 始终为正数，由 kind 区分正负
  final TransactionKind kind;
  final String categoryId;
  final DateTime date; // 用户可调整（不是创建时间）
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Transaction({
    required this.id,
    required this.amount,
    required this.kind,
    required this.categoryId,
    required this.date,
    this.note = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// 带正负号的金额：支出为负，收入为正
  /// 用于统计聚合时直接 sum
  double get signedAmount =>
      kind == TransactionKind.expense ? -amount : amount;

  Transaction copyWith({
    double? amount,
    TransactionKind? kind,
    String? categoryId,
    DateTime? date,
    String? note,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id,
      amount: amount ?? this.amount,
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
      date: date ?? this.date,
      note: note ?? this.note,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Transaction && other.id == id);

  @override
  int get hashCode => id.hashCode;
}

// ══════════════════════════════════
// 筛选 / 排序 —— 用于搜索 + 列表过滤
// ══════════════════════════════════

class TransactionFilter {
  final String keyword;
  final DateTime? startDate;
  final DateTime? endDate;
  final TransactionKind? kind;
  final String? categoryId;
  final double? minAmount;
  final double? maxAmount;
  final SortBy sortBy;
  final int offset;
  final int limit;

  const TransactionFilter({
    this.keyword = '',
    this.startDate,
    this.endDate,
    this.kind,
    this.categoryId,
    this.minAmount,
    this.maxAmount,
    this.sortBy = SortBy.dateDesc,
    this.offset = 0,
    this.limit = 50,
  });

  TransactionFilter copyWith({
    String? keyword,
    DateTime? startDate,
    DateTime? endDate,
    TransactionKind? kind,
    String? categoryId,
    double? minAmount,
    double? maxAmount,
    SortBy? sortBy,
    int? offset,
    int? limit,
  }) {
    return TransactionFilter(
      keyword: keyword ?? this.keyword,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      kind: kind ?? this.kind,
      categoryId: categoryId ?? this.categoryId,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      sortBy: sortBy ?? this.sortBy,
      offset: offset ?? this.offset,
      limit: limit ?? this.limit,
    );
  }

  bool get isEmpty =>
      keyword.isEmpty &&
      startDate == null &&
      endDate == null &&
      kind == null &&
      categoryId == null &&
      minAmount == null &&
      maxAmount == null;
}

enum SortBy {
  dateDesc,
  dateAsc,
  amountDesc,
  amountAsc;
}
