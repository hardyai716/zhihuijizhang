import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../core/utils/theme_utils.dart';

/// 数字键盘组件
/// 设计稿位置: 记账-输金额 3:7
class NumberPad extends StatelessWidget {
  final ValueChanged<String> onKeyTap;
  final VoidCallback onConfirm;
  final VoidCallback onDelete;

  const NumberPad({
    super.key,
    required this.onKeyTap,
    required this.onConfirm,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      children: [
        _buildRow(context, ['1', '2', '3']),
        const SizedBox(height: 1),
        _buildRow(context, ['4', '5', '6']),
        const SizedBox(height: 1),
        _buildRow(context, ['7', '8', '9']),
        const SizedBox(height: 1),
        Row(
          children: [
            _buildKey(context, '.', flex: 1),
            const SizedBox(width: 1),
            _buildKey(context, '0', flex: 1),
            const SizedBox(width: 1),
            Expanded(
              flex: 1,
              child: _ActionKey(
                onTap: onDelete,
                color: c.surface,
                child: Icon(Icons.backspace_outlined,
                    size: 26, color: c.textSecondary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1),
          child: _ActionKey(
            onTap: onConfirm,
            height: 56,
            color: AppTheme.primary,
            child: const Icon(Icons.check, size: 30, color: AppTheme.textOnPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(BuildContext context, List<String> keys) {
    return Row(
      children: [
        for (int i = 0; i < keys.length; i++) ...[
          _buildKey(context, keys[i], flex: 1),
          if (i < keys.length - 1) const SizedBox(width: 1),
        ],
      ],
    );
  }

  Widget _buildKey(BuildContext context, String value, {int flex = 1}) {
    final c = context.colors;
    return Expanded(
      flex: flex,
      child: _ActionKey(
        onTap: () => onKeyTap(value),
        color: c.surface,
        child: Text(
          value,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w500,
            color: c.textPrimary,
            fontFamily: AppTheme.fontFamilyNumber,
          ),
        ),
      ),
    );
  }
}

class _ActionKey extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final double? height;
  final Color? color;

  const _ActionKey({
    required this.onTap,
    required this.child,
    this.height = 64,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Material(
        color: color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          child: Center(child: child),
        ),
      ),
    );
  }
}
