/// 分类 - Hive 持久化模型

import 'package:hive/hive.dart';
import '../../core/constants/app_constants.dart';
import '../../domain/entities/category.dart';

part 'category_model.g.dart';

@HiveType(typeId: AppConstants.typeIdCategory)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String icon;

  @HiveField(3)
  final String kind; // 'income' | 'expense'

  @HiveField(4)
  final int sortOrder;

  @HiveField(5)
  final DateTime createdAt;

  @HiveField(6)
  final DateTime updatedAt;

  CategoryModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.kind,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  Category toEntity() => Category(
        id: id,
        name: name,
        icon: icon,
        kind: TransactionKind.values.byName(kind),
        sortOrder: sortOrder,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory CategoryModel.fromEntity(Category c) => CategoryModel(
        id: c.id,
        name: c.name,
        icon: c.icon,
        kind: c.kind.name,
        sortOrder: c.sortOrder,
        createdAt: c.createdAt,
        updatedAt: c.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'kind': kind,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory CategoryModel.fromJson(Map<String, dynamic> json) =>
      CategoryModel(
        id: json['id'] as String,
        name: json['name'] as String,
        icon: json['icon'] as String,
        kind: json['kind'] as String,
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
