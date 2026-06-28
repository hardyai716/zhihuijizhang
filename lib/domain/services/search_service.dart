/// SearchService —— 搜索与筛选
///
/// 关键设计：
/// - 在 Repository 基础上组合（关键字+时间+分类名）
/// - 提供统一的筛选入参 Filter 对象（使用 domain/entities/transaction.dart 中的 TransactionFilter）
/// - 结果带高亮信息（matches）供 UI 渲染

import '../../core/errors/result.dart';
import '../../core/failures/failure.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/entities/category.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';

class SearchService {
  SearchService({
    required TransactionRepository txRepo,
    required CategoryRepository catRepo,
  })  : _txRepo = txRepo,
        _catRepo = catRepo;

  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;

  /// 复合搜索
  Result<List<TransactionSearchResult>> search(TransactionFilter filter) {
    // 1. 分类名搜索 -> 转分类ID集合
    Set<String>? categoryIds;
    if (filter.keyword.isNotEmpty) {
      final cats = _catRepo.getAll();
      if (cats.isErr) return Err(cats.failureOrNull!);
      final lower = filter.keyword.toLowerCase();
      categoryIds = {
        for (final c in cats.valueOrNull!)
          if (c.name.toLowerCase().contains(lower)) c.id,
      };
    }

    // 2. 基础搜索（用 Repository 的 search 方法）
    final baseResult = _txRepo.search(
      keyword: filter.keyword,
      startDate: filter.startDate,
      endDate: filter.endDate,
      kind: filter.kind,
    );
    if (baseResult.isErr) return Err(baseResult.failureOrNull!);

    // 3. 二次过滤（分类名）
    var txs = baseResult.valueOrNull!.where((t) {
      if (categoryIds == null) return true;
      return categoryIds.contains(t.categoryId);
    });

    // 4. 分类ID精确过滤
    if (filter.categoryId != null) {
      txs = txs.where((t) => t.categoryId == filter.categoryId);
    }

    // 5. 金额范围过滤
    if (filter.minAmount != null) {
      txs = txs.where((t) => t.amount >= filter.minAmount!);
    }
    if (filter.maxAmount != null) {
      txs = txs.where((t) => t.amount <= filter.maxAmount!);
    }

    final txsList = txs.toList();

    // 6. 排序
    txsList.sort((a, b) {
      int cmp;
      switch (filter.sortBy) {
        case SortBy.dateDesc:    cmp = b.date.compareTo(a.date); break;
        case SortBy.dateAsc:     cmp = a.date.compareTo(b.date); break;
        case SortBy.amountDesc:  cmp = b.amount.compareTo(a.amount); break;
        case SortBy.amountAsc:   cmp = a.amount.compareTo(b.amount); break;
      }
      return cmp;
    });

    // 7. 分页
    final paged = txsList.length > filter.offset
        ? txsList.sublist(
            filter.offset,
            (filter.offset + filter.limit).clamp(0, txsList.length),
          )
        : <Transaction>[];

    // 8. 包装为带高亮信息的结果
    final cats = _catRepo.getAll();
    final catMap = cats.isOk
        ? {for (final c in cats.valueOrNull!) c.id: c}
        : <String, Category>{};

    final results = paged.map((t) {
      return TransactionSearchResult(
        transaction: t,
        category: catMap[t.categoryId],
        matchedFields: _matchFields(t, filter.keyword, catMap[t.categoryId]),
      );
    }).toList();

    return Ok(results);
  }

  /// 完整结果数（不应用分页）
  Result<int> count(TransactionFilter filter) {
    final result = search(filter.copyWith(limit: 1000000, offset: 0));
    if (result.isErr) return Err(result.failureOrNull!);
    return Ok(result.valueOrNull!.length);
  }

  List<String> _matchFields(Transaction t, String keyword, Category? c) {
    if (keyword.isEmpty) return [];
    final lower = keyword.toLowerCase();
    final fields = <String>[];
    if (t.note.toLowerCase().contains(lower)) fields.add('note');
    if (c != null && c.name.toLowerCase().contains(lower)) fields.add('category');
    if (t.amount.toStringAsFixed(2).contains(lower)) fields.add('amount');
    return fields;
  }
}

// ══════════════════════════════════
// 搜索结果（含分类 + 高亮信息）
// ══════════════════════════════════

class TransactionSearchResult {
  final Transaction transaction;
  final Category? category;
  final List<String> matchedFields; // ['note', 'category', 'amount']

  const TransactionSearchResult({
    required this.transaction,
    required this.category,
    required this.matchedFields,
  });
}
