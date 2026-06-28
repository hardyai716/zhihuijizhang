/// Transaction State Notifier —— 收支记录状态管理
///
/// 关键能力：
/// - 按时间倒序的全量列表
/// - 按月分组
/// - 搜索/筛选（组合 TransactionFilter）
/// - 最近 N 条
/// - 增删改（带分类联动）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/result.dart';
import '../../core/failures/failure.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import '../../data/repositories/transaction_repository.dart';
import '../categories/category_notifier.dart';

class TransactionState {
  final List<Transaction> all;          // 全部记录（倒序）
  final TransactionFilter filter;        // 当前筛选
  final List<Transaction> filtered;      // 筛选后
  final bool isLoading;
  final String? errorMessage;

  const TransactionState({
    this.all = const [],
    this.filter = const TransactionFilter(),
    this.filtered = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  TransactionState copyWith({
    List<Transaction>? all,
    TransactionFilter? filter,
    List<Transaction>? filtered,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TransactionState(
      all: all ?? this.all,
      filter: filter ?? this.filter,
      filtered: filtered ?? this.filtered,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  // ══════════════════════════════════
  // 计算属性
  // ══════════════════════════════════

  /// 最近 N 条
  List<Transaction> recent(int n) => all.take(n).toList();

  /// 按月分组的记录
  Map<String, List<Transaction>> get groupedByMonth {
    final map = <String, List<Transaction>>{};
    for (final t in all) {
      final key = Formatters.monthKey(t.date);
      map.putIfAbsent(key, () => []);
      map[key]!.add(t);
    }
    for (final list in map.values) {
      list.sort((a, b) => b.date.compareTo(a.date));
    }
    return map;
  }

  /// 本月统计
  double get monthlyExpense {
    final now = DateTime.now();
    return all
        .where((t) =>
            t.kind == TransactionKind.expense &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyIncome {
    final now = DateTime.now();
    return all
        .where((t) =>
            t.kind == TransactionKind.income &&
            t.date.year == now.year &&
            t.date.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double get monthlyBalance => monthlyIncome - monthlyExpense;
}

class TransactionNotifier extends StateNotifier<TransactionState> {
  TransactionNotifier(this._repo, this._catNotifier) : super(const TransactionState()) {
    load();
    // 监听分类变化，自动重新筛选
    _removeCatListener = _catNotifier.addListener(_onCategoryChanged);
  }

  final TransactionRepository _repo;
  final CategoryNotifier _catNotifier;
  late final void Function() _removeCatListener;

  @override
  void dispose() {
    _removeCatListener();
    super.dispose();
  }

  void _onCategoryChanged(CategoryState _) {
    // 分类变化时重新应用筛选（分类名变化会影响搜索结果）
    if (state.filter.keyword.isNotEmpty) {
      applyFilter(state.filter);
    }
  }

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
      all: result.valueOrNull!,
      filtered: result.valueOrNull!,
      isLoading: false,
    );
    AppLog.service('交易加载完成: ${result.valueOrNull!.length} 笔');
  }

  // ══════════════════════════════════
  // CRUD
  // ══════════════════════════════════

  Failure? add(Transaction t) {
    final result = _repo.add(t);
    if (result.isErr) {
      state = state.copyWith(errorMessage: result.failureOrNull!.message);
      return result.failureOrNull;
    }
    final newAll = [t, ...state.all]
      ..sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(all: newAll, filtered: _applyFilterInMemory(newAll, state.filter));
    return null;
  }

  Failure? update(Transaction t) {
    final result = _repo.update(t);
    if (result.isErr) {
      state = state.copyWith(errorMessage: result.failureOrNull!.message);
      return result.failureOrNull;
    }
    final newAll = state.all
        .map((existing) => existing.id == t.id ? t : existing)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    state = state.copyWith(all: newAll, filtered: _applyFilterInMemory(newAll, state.filter));
    return null;
  }

  Failure? delete(String id) {
    final result = _repo.delete(id);
    if (result.isErr) {
      state = state.copyWith(errorMessage: result.failureOrNull!.message);
      return result.failureOrNull;
    }
    final newAll = state.all.where((t) => t.id != id).toList();
    state = state.copyWith(all: newAll, filtered: _applyFilterInMemory(newAll, state.filter));
    return null;
  }

  /// 批量删除（用于清理/重置）
  Failure? deleteMany(List<String> ids) {
    final result = _repo.deleteMany(ids);
    if (result.isErr) {
      state = state.copyWith(errorMessage: result.failureOrNull!.message);
      return result.failureOrNull;
    }
    final idSet = ids.toSet();
    final newAll = state.all.where((t) => !idSet.contains(t.id)).toList();
    state = state.copyWith(all: newAll, filtered: _applyFilterInMemory(newAll, state.filter));
    return null;
  }

  /// 分类被删除时，将记录迁移到新分类
  Failure? migrateCategory(String fromCategoryId, String toCategoryId) {
    final affected = state.all.where((t) => t.categoryId == fromCategoryId).toList();
    for (final t in affected) {
      final result = _repo.update(t.copyWith(categoryId: toCategoryId));
      if (result.isErr) return result.failureOrNull;
    }
    load(); // 重新加载
    return null;
  }

  // ══════════════════════════════════
  // 筛选
  // ══════════════════════════════════

  void applyFilter(TransactionFilter filter) {
    final filtered = _applyFilterInMemory(state.all, filter);
    state = state.copyWith(filter: filter, filtered: filtered);
  }

  void clearFilter() {
    applyFilter(const TransactionFilter());
  }

  /// 内存筛选（避免对每个筛选项都查 Hive）
  List<Transaction> _applyFilterInMemory(List<Transaction> txs, TransactionFilter f) {
    Iterable<Transaction> result = txs;

    if (f.keyword.isNotEmpty) {
      final lower = f.keyword.toLowerCase();
      // 分类名 → ID 集合
      final catIds = <String>{};
      for (final c in _catNotifier.state.categories) {
        if (c.name.toLowerCase().contains(lower)) catIds.add(c.id);
      }
      result = result.where((t) {
        if (t.note.toLowerCase().contains(lower)) return true;
        if (catIds.contains(t.categoryId)) return true;
        if (t.amount.toStringAsFixed(2).contains(lower)) return true;
        return false;
      });
    }

    if (f.startDate != null) {
      result = result.where((t) => !t.date.isBefore(f.startDate!));
    }
    if (f.endDate != null) {
      result = result.where((t) => !t.date.isAfter(f.endDate!));
    }
    if (f.kind != null) {
      result = result.where((t) => t.kind == f.kind);
    }

    final list = result.toList();
    list.sort((a, b) {
      int cmp;
      switch (f.sortBy) {
        case SortBy.dateDesc: cmp = b.date.compareTo(a.date); break;
        case SortBy.dateAsc:  cmp = a.date.compareTo(b.date); break;
        case SortBy.amountDesc: cmp = b.amount.compareTo(a.amount); break;
        case SortBy.amountAsc:  cmp = a.amount.compareTo(b.amount); break;
      }
      return cmp;
    });

    // 分页
    if (f.offset >= list.length) return const [];
    final end = (f.offset + f.limit).clamp(0, list.length);
    return list.sublist(f.offset, end);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
