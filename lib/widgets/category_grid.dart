import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/utils/theme_utils.dart';
import '../domain/entities/category.dart';

/// 分类选择网格
/// 设计稿位置: 记账-选分类 3:6
class CategoryGrid extends StatelessWidget {
  final List<Category> categories;
  final void Function(Category) onSelect;
  final VoidCallback onAddNew;

  const CategoryGrid({
    super.key,
    required this.categories,
    required this.onSelect,
    required this.onAddNew,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            '选择分类',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: c.textPrimary,
              fontFamily: AppTheme.fontFamilyText,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ...categories.map((cat) => _CategoryTile(
                    category: cat,
                    onTap: () => onSelect(cat),
                  )),
              _AddCategoryTile(onTap: onAddNew),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryTile({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: c.shadow,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.icon, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 6),
            Text(
              category.name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
                fontFamily: AppTheme.fontFamilyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCategoryTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddCategoryTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 78,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          border: Border.all(
            color: c.divider,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, size: 28, color: c.textTertiary),
            const SizedBox(height: 6),
            Text(
              '新建',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: c.textTertiary,
                fontFamily: AppTheme.fontFamilyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
