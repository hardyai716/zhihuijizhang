import 'package:flutter/material.dart';

/// Theme-aware 上下文色值工具
///
/// 解决 widget 内硬编码 `AppTheme.background` / `AppTheme.textPrimary` 等常量
/// 导致深色模式失效的问题。所有 widget 应通过此扩展读取颜色，
/// 而非直接引用 AppTheme 的 light 静态字段。
///
/// 用法：
/// ```dart
/// final c = context.colors;
/// Container(color: c.background, child: Text('hi', style: TextStyle(color: c.textPrimary)))
/// ```
class ContextColors {
  final Color background;
  final Color surface;
  final Color surfaceSecondary;
  final Color divider;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color primary;
  final Color primaryContainer;
  final bool isDark;
  final List<BoxShadow> shadow;

  const ContextColors({
    required this.background,
    required this.surface,
    required this.surfaceSecondary,
    required this.divider,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.primaryContainer,
    required this.isDark,
    required this.shadow,
  });

  /// 从 BuildContext 推断当前主题色值
  factory ContextColors.of(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;
    return ContextColors(
      background: theme.scaffoldBackgroundColor,
      surface: scheme.surface,
      // surfaceSecondary: 浅色=surfaceContainerHigh, 深色=surfaceContainerHighest
      surfaceSecondary: isDark
          ? scheme.surfaceContainerHighest
          : scheme.surfaceContainerHigh,
      divider: isDark
          ? scheme.outlineVariant
          : const Color(0xFFE2E8F0),
      textPrimary: scheme.onSurface,
      textSecondary: isDark
          ? const Color(0xFF94A3B8)
          : const Color(0xFF64748B),
      textTertiary: isDark
          ? const Color(0xFF64748B)
          : const Color(0xFF94A3B8),
      primary: scheme.primary,
      primaryContainer: scheme.primaryContainer,
      isDark: isDark,
      shadow: isDark
          ? [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ]
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
    );
  }
}

extension ContextColorsX on BuildContext {
  ContextColors get colors => ContextColors.of(this);
}
