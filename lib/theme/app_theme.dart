import 'package:flutter/material.dart';

/// 智慧记账 App 设计 Token
/// 提取自 Ardot 设计稿 #698076444614039
class AppTheme {
  AppTheme._();

  // ── 颜色系统 ──

  /// 主色调 - 品牌蓝 (设计稿 gradient #004DB2 → #024094)
  static const Color primary = Color(0xFF014DB2);
  static const Color primaryLight = Color(0xFFE8F0FE);
  static const Color primaryGradientStart = Color(0xFF004DB2);
  static const Color primaryGradientEnd = Color(0xFF024094);

  /// 语义色
  static const Color income = Color(0xFF10B981);   // 收入绿
  static const Color expense = Color(0xFFEF4444);  // 支出红
  static const Color warning = Color(0xFFF59E0B);

  /// 中性色 — Light 模式
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceSecondary = Color(0xFFF1F5F9);
  static const Color divider = Color(0xFFE2E8F0);

  /// 文字色 — Light 模式
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textTertiary = Color(0xFF94A3B8);
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  /// 中性色 — Dark 模式
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkSurfaceSecondary = Color(0xFF334155);
  static const Color darkDivider = Color(0xFF334155);

  /// 文字色 — Dark 模式
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // ── 间距系统 (8px 基础单位) ──

  static const double space1 = 4;
  static const double space2 = 8;
  static const double space3 = 12;
  static const double space4 = 16;
  static const double space5 = 20;
  static const double space6 = 24;
  static const double space8 = 32;
  static const double space10 = 40;

  // ── 圆角 ──

  static const double radiusSm = 8;
  static const double radiusMd = 14;
  static const double radiusLg = 20;
  static const double radiusXl = 24;
  static const double radiusFull = 36;

  // ── 字体 ──

  static const String fontFamilyNumber = 'Inter';
  static const String fontFamilyText = 'PingFang SC';

  // ── 阴影 ──

  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.05),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];

  // ── Dark 阴影 ──

  static List<BoxShadow> darkShadowSm = [
    BoxShadow(
      color: Colors.black.withOpacity(0.3),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> darkShadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // ── ThemeData ──

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: textOnPrimary,
        surface: surface,
        onSurface: textPrimary,
        error: expense,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: fontFamilyText,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background,
        selectedItemColor: primary,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: textOnPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamilyText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: divider,
        thickness: 0.5,
        space: 0,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF3B82F6),
        onPrimary: textOnPrimary,
        surface: darkSurface,
        onSurface: darkTextPrimary,
        error: expense,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: darkSurface,
        foregroundColor: darkTextPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: fontFamilyText,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: darkTextPrimary,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkSurface,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: darkTextTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w400),
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusLg),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceSecondary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusMd),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF3B82F6),
          foregroundColor: textOnPrimary,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusMd),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamilyText,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFF3B82F6),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: darkDivider,
        thickness: 0.5,
        space: 0,
      ),
    );
  }

  /// 根据是否深色模式返回对应颜色
  static Color bgColor(bool isDark) => isDark ? darkBackground : background;
  static Color surfaceColor(bool isDark) => isDark ? darkSurface : surface;
  static Color surfaceSecColor(bool isDark) => isDark ? darkSurfaceSecondary : surfaceSecondary;
  static Color textColor(bool isDark) => isDark ? darkTextPrimary : textPrimary;
  static Color textColorSec(bool isDark) => isDark ? darkTextSecondary : textSecondary;
  static Color textColorTer(bool isDark) => isDark ? darkTextTertiary : textTertiary;
  static Color dividerColor(bool isDark) => isDark ? darkDivider : divider;
  static List<BoxShadow> shadowColor(bool isDark) => isDark ? darkShadowSm : shadowSm;
}
