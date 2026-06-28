import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// 收支概览卡片
/// 设计稿位置: 记账主页 3:3 / 统计页 3:4
class OverviewCard extends StatelessWidget {
  final double expense;
  final double income;
  final double balance;

  const OverviewCard({
    super.key,
    required this.expense,
    required this.income,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowMd,
      ),
      child: Column(
        children: [
          // 本月结余（大字号）
          Text(
            '本月结余',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textOnPrimary.withOpacity(0.8),
              fontFamily: AppTheme.fontFamilyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¥${_formatAmount(balance)}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppTheme.textOnPrimary,
              fontFamily: AppTheme.fontFamilyNumber,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 20),
          // 收入 / 支出 双栏
          Row(
            children: [
              _buildColumn('收入', income, AppTheme.income),
              Container(
                width: 0.5,
                height: 36,
                color: AppTheme.textOnPrimary.withOpacity(0.2),
              ),
              _buildColumn('支出', expense, AppTheme.expense),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildColumn(String label, double amount, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textOnPrimary.withOpacity(0.7),
              fontFamily: AppTheme.fontFamilyText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¥${_formatAmount(amount)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textOnPrimary,
              fontFamily: AppTheme.fontFamilyNumber,
            ),
          ),
        ],
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount == amount.toInt()) {
      return amount.toInt().toString();
    }
    return amount.toStringAsFixed(2);
  }
}

/// 月度汇总条（记录列表顶部）
class MonthSummaryBar extends StatelessWidget {
  final double expense;
  final double income;
  final double balance;

  const MonthSummaryBar({
    super.key,
    required this.expense,
    required this.income,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceSecondary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildItem('支出', '-¥${_fmt(expense)}', AppTheme.expense),
          _buildItem('收入', '+¥${_fmt(income)}', AppTheme.income),
          _buildItem('结余', '¥${_fmt(balance)}', AppTheme.primary),
        ],
      ),
    );
  }

  Widget _buildItem(String label, String amount, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(amount,
          style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w700, color: color,
            fontFamily: AppTheme.fontFamilyNumber,
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
          style: const TextStyle(
            fontSize: 11, color: AppTheme.textTertiary,
            fontFamily: AppTheme.fontFamilyText,
          ),
        ),
      ],
    );
  }

  String _fmt(double v) => v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(2);
}
