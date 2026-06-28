/// Category Repository —— 分类仓储
///
/// 关键业务规则：
/// - 删除分类时，若该分类下有记录，禁止直接删除（返回 CategoryInUseFailure）
/// - 提供"冻结"语义：删除分类时记录仍保留原 categoryId 字符串（不级联）
///   UI 层应将找不到分类的记录显示为"未分类"

import '../../core/errors/result.dart';
import '../../core/failures/failure.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_log.dart';
import '../../domain/entities/category.dart';
import '../sources/local/hive_local_data_source.dart';
import '../models/category_model.dart';
import 'transaction_repository.dart';

class CategoryRepository {
  CategoryRepository(this._local, this._txRepo);
  final HiveLocalDataSource _local;
  final TransactionRepository _txRepo;

  // ══════════════════════════════════
  // 读取
  // ══════════════════════════════════

  Result<List<Category>> getAll() {
    try {
      final list = _local.categories.values.map((m) => m.toEntity()).toList()
        ..sort((a, b) {
          // 先按类型排（支出在前），再按 sortOrder
          final kindCmp = a.kind.index.compareTo(b.kind.index);
          if (kindCmp != 0) return kindCmp;
          return a.sortOrder.compareTo(b.sortOrder);
        });
      return Ok(list);
    } catch (e) {
      return Err(StorageFailure(message: '读取分类失败', cause: e));
    }
  }

  Result<List<Category>> getByKind(TransactionKind kind) {
    final all = getAll();
    if (all.isErr) return all;
    return Ok(all.valueOrNull!
        .where((c) => c.kind == kind)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)));
  }

  Result<Category?> findById(String id) {
    try {
      final m = _local.categories.get(id);
      return Ok(m?.toEntity());
    } catch (e) {
      return Err(StorageFailure(message: '查找分类失败', cause: e));
    }
  }

  // ══════════════════════════════════
  // 写入
  // ══════════════════════════════════

  Result<Category> add(Category c) {
    final v = _validate(c);
    if (v != null) return Err(v);

    if (_local.categories.containsKey(c.id)) {
      return Err(BusinessRuleFailure(
        message: '分类ID已存在: ${c.id}',
        code: 'DUPLICATE_ID',
      ));
    }

    try {
      _local.categories.put(c.id, CategoryModel.fromEntity(c));
      AppLog.repo('新增分类 ${c.id} (${c.name})');
      return Ok(c);
    } catch (e) {
      return Err(StorageFailure(message: '保存分类失败', cause: e));
    }
  }

  Result<Category> update(Category c) {
    final v = _validate(c);
    if (v != null) return Err(v);

    if (!_local.categories.containsKey(c.id)) {
      return Err(NotFoundFailure(message: '分类不存在: ${c.id}'));
    }

    try {
      _local.categories.put(c.id, CategoryModel.fromEntity(c));
      AppLog.repo('更新分类 ${c.id}');
      return Ok(c);
    } catch (e) {
      return Err(StorageFailure(message: '更新分类失败', cause: e));
    }
  }

  /// 删除分类
  ///
  /// 业务规则：
  /// - 若该分类下有记录，默认拒绝（返回 CategoryInUseFailure）
  /// - 调用方需先迁移记录到其他分类才能删除
  /// - "force=true" 可绕过检查（用于特殊场景：导入数据清理等）
  Result<void> delete(String id, {bool force = false}) {
    if (!_local.categories.containsKey(id)) {
      return const Ok(null);
    }

    // 检查该分类下是否有记录
    final txResult = _txRepo.findByCategoryId(id);
    if (txResult.isErr) return Err(txResult.failureOrNull!);

    final count = txResult.valueOrNull!.length;
    if (count > 0 && !force) {
      return Err(CategoryInUseFailure(recordCount: count));
    }

    try {
      _local.categories.delete(id);
      AppLog.repo('删除分类 $id (关联记录: $count, force=$force)');
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(message: '删除分类失败', cause: e));
    }
  }

  /// 重新排序
  Result<void> reorder(List<String> orderedIds) {
    try {
      for (int i = 0; i < orderedIds.length; i++) {
        final m = _local.categories.get(orderedIds[i]);
        if (m == null) continue;
        m.sortOrder = i;
        m.save();
      }
      AppLog.repo('重新排序 ${orderedIds.length} 个分类');
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(message: '排序失败', cause: e));
    }
  }

  /// 初始化预设分类（首次启动时调用）
  Result<void> seedDefaultsIfEmpty() {
    if (_local.categories.isNotEmpty) {
      return const Ok(null);
    }
    try {
      final now = DateTime.now();
      final defaults = <Category>[
        // 支出
        Category(
          id: 'food', name: '餐饮', icon: '🍜', kind: TransactionKind.expense,
          sortOrder: 0, createdAt: now, updatedAt: now,
        ),
        Category(
          id: 'transport', name: '交通', icon: '🚗', kind: TransactionKind.expense,
          sortOrder: 1, createdAt: now, updatedAt: now,
        ),
        Category(
          id: 'shopping', name: '购物', icon: '🛍️', kind: TransactionKind.expense,
          sortOrder: 2, createdAt: now, updatedAt: now,
        ),
        Category(
          id: 'entertainment', name: '娱乐', icon: '🎮', kind: TransactionKind.expense,
          sortOrder: 3, createdAt: now, updatedAt: now,
        ),
        Category(
          id: 'housing', name: '居住', icon: '🏠', kind: TransactionKind.expense,
          sortOrder: 4, createdAt: now, updatedAt: now,
        ),
        Category(
          id: 'medical', name: '医疗', icon: '💊', kind: TransactionKind.expense,
          sortOrder: 5, createdAt: now, updatedAt: now,
        ),
        // 收入
        Category(
          id: 'salary', name: '工资', icon: '💰', kind: TransactionKind.income,
          sortOrder: 0, createdAt: now, updatedAt: now,
        ),
        Category(
          id: 'other_income', name: '其他', icon: '📦', kind: TransactionKind.income,
          sortOrder: 1, createdAt: now, updatedAt: now,
        ),
      ];

      for (final c in defaults) {
        _local.categories.put(c.id, CategoryModel.fromEntity(c));
      }
      AppLog.repo('初始化预设分类 ${defaults.length} 个');
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(message: '初始化分类失败', cause: e));
    }
  }

  // ══════════════════════════════════
  // 业务校验
  // ══════════════════════════════════

  ValidationFailure? _validate(Category c) {
    if (c.name.trim().isEmpty) {
      return const ValidationFailure(message: '分类名称不能为空');
    }
    if (c.name.length > AppConstants.maxCategoryNameLength) {
      return ValidationFailure(
        message: '分类名称最多 ${AppConstants.maxCategoryNameLength} 字',
      );
    }
    if (c.icon.isEmpty) {
      return const ValidationFailure(message: '请选择图标');
    }
    if (c.id.isEmpty) {
      return const ValidationFailure(message: '分类ID无效');
    }
    return null;
  }
}
