/// Category State Notifier —— 分类状态管理
///
/// 职责：
/// - 加载全部分类
/// - 增删改查（带 Result 错误处理）
/// - 排序
/// - 暴露 loading/error 状态供 UI 反馈

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/result.dart';
import '../../core/failures/failure.dart';
import '../../core/utils/app_log.dart';
import '../../domain/entities/category.dart';
import '../../data/repositories/category_repository.dart';

class CategoryState {
  final List<Category> categories;
  final bool isLoading;
  final String? errorMessage;

  const CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CategoryState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  // ══════════════════════════════════
  // 计算属性
  // ══════════════════════════════════

  List<Category> get expenseCategories => categories
      .where((c) => c.kind == TransactionKind.expense)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  List<Category> get incomeCategories => categories
      .where((c) => c.kind == TransactionKind.income)
      .toList()
    ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  Category? findById(String id) {
    try {
      return categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  CategoryNotifier(this._repo) : super(const CategoryState()) {
    load();
  }

  final CategoryRepository _repo;

  // ══════════════════════════════════
  // 加载
  // ══════════════════════════════════

  Future<void> load() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = _repo.getAll();
    if (result.isErr) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: result.failureOrNull!.message,
      );
      return;
    }
    state = state.copyWith(
      categories: result.valueOrNull!,
      isLoading: false,
    );
    AppLog.service('分类加载完成: ${result.valueOrNull!.length} 个');
  }

  // ══════════════════════════════════
  // CRUD
  // ══════════════════════════════════

  /// 返回 Failure 表示失败（业务校验失败时），UI 层应提示
  Failure? add(Category c) {
    final result = _repo.add(c);
    if (result.isErr) {
      state = state.copyWith(errorMessage: result.failureOrNull!.message);
      return result.failureOrNull;
    }
    state = state.copyWith(
      categories: [...state.categories, result.valueOrNull!],
    );
    return null;
  }

  Failure? update(Category c) {
    final result = _repo.update(c);
    if (result.isErr) {
      state = state.copyWith(errorMessage: result.failureOrNull!.message);
      return result.failureOrNull;
    }
    state = state.copyWith(
      categories: state.categories
          .map((existing) => existing.id == c.id ? c : existing)
          .toList(),
    );
    return null;
  }

  Failure? delete(String id) {
    final result = _repo.delete(id);
    if (result.isErr) {
      state = state.copyWith(errorMessage: result.failureOrNull!.message);
      return result.failureOrNull;
    }
    state = state.copyWith(
      categories: state.categories.where((c) => c.id != id).toList(),
    );
    return null;
  }

  /// 强制删除（先迁移记录到目标分类）
  Failure? deleteAndMigrate(String id, String migrateToCategoryId) {
    // 1. 迁移该分类下所有记录
    final txResult = _repo // 这里需要通过 TransactionRepository
    // 为避免循环依赖，UI 层应先调用 TransactionRepository.migrateCategory()
    return delete(id, force: true);
  }

  /// 强制删除（绕过业务规则）
  Failure? deleteWithForce(String id) {
    final result = _repo.delete(id, force: true);
    if (result.isErr) {
      state = state.copyWith(errorMessage: result.failureOrNull!.message);
      return result.failureOrNull;
    }
    state = state.copyWith(
      categories: state.categories.where((c) => c.id != id).toList(),
    );
    return null;
  }

  void reorder(List<String> orderedIds) {
    _repo.reorder(orderedIds);
    // 重新加载以反映新的 sortOrder
    load();
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
