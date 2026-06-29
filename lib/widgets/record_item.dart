import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/utils/theme_utils.dart';
import '../domain/entities/transaction.dart';
import '../domain/entities/category.dart';

/// 记录列表项
/// 设计稿位置: 记录列表 3:5
///
/// categories 由父级通过 ref.watch(categoryNotifierProvider) 注入，
/// 避免组件自己再读 Provider 造成重复订阅。
class RecordItem extends StatelessWidget {
  final Transaction transaction;
  final List<Category> categories;

  const RecordItem({
    super.key,
    required this.transaction,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    final category = _findCategory(categories, transaction.categoryId);
    final isExpense = transaction.kind == TransactionKind.expense;
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: c.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // 分类图标
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: c.surfaceSecondary,
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
            alignment: Alignment.center,
            child: Text(
              category?.icon ?? '📌',
              style: const TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          // 名称和备注
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category?.name ?? '未分类',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: c.textPrimary,
                    fontFamily: AppTheme.fontFamilyText,
                  ),
                ),
                if (transaction.note.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    transaction.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textTertiary,
                      fontFamily: AppTheme.fontFamilyText,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 金额
          Text(
            isExpense
                ? '-¥${_format(transaction.amount)}'
                : '+¥${_format(transaction.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isExpense ? c.textPrimary : AppTheme.income,
              fontFamily: AppTheme.fontFamilyNumber,
            ),
          ),
        ],
      ),
    );
  }

  static Category? _findCategory(List<Category> categories, String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  String _format(double v) =>
      v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(2);
}
