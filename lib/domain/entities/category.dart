/// 领域实体：收支分类
///
/// 位置：domain/entities/
/// - 不依赖任何框架（Hive/Flutter）
/// - 是 UI 和 Repository 之间的通用语言
/// - 持久化由 data/models/ 中的 HiveModel 处理

enum TransactionKind {
  income,
  expense;

  String get displayName => switch (this) {
        TransactionKind.income => '收入',
        TransactionKind.expense => '支出',
      };

  static TransactionKind fromName(String name) =>
      TransactionKind.values.byName(name);
}

class Category {
  final String id;
  final String name;
  final String icon; // emoji
  final TransactionKind kind;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Category({
    required this.id,
    required this.name,
    required this.icon,
    required this.kind,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  /// 便捷工厂：自动填入 createdAt/updatedAt（用于临时构造，如新增分类 UI）
  /// 持久化层会重新写入真实时间戳
  factory Category.create({
    required String id,
    required String name,
    required String icon,
    required TransactionKind kind,
    int sortOrder = 0,
  }) {
    final now = DateTime.now();
    return Category(
      id: id,
      name: name,
      icon: icon,
      kind: kind,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
    );
  }

  Category copyWith({
    String? name,
    String? icon,
    TransactionKind? kind,
    int? sortOrder,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      kind: kind ?? this.kind,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Category && other.id == id);

  @override
  int get hashCode => id.hashCode;
}
