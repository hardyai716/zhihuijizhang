import 'package:flutter/material.dart' as material;

/// 应用设置（key-value 形式持久化）
class AppSettings {
  /// 主题模式
  final AppThemeMode themeMode;

  /// 是否已同意免责声明
  final bool disclaimerAccepted;

  /// 启动时显示的提示（如最后备份时间）
  final String? lastBackupReminder;

  /// 上次数据校验时间
  final DateTime? lastValidationAt;

  const AppSettings({
    this.themeMode = AppThemeMode.system,
    this.disclaimerAccepted = false,
    this.lastBackupReminder,
    this.lastValidationAt,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? disclaimerAccepted,
    String? lastBackupReminder,
    DateTime? lastValidationAt,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      disclaimerAccepted: disclaimerAccepted ?? this.disclaimerAccepted,
      lastBackupReminder: lastBackupReminder ?? this.lastBackupReminder,
      lastValidationAt: lastValidationAt ?? this.lastValidationAt,
    );
  }
}

/// 应用主题模式（避免与 Flutter ThemeMode 冲突）
enum AppThemeMode {
  system,
  light,
  dark;
}

/// 将 AppThemeMode 转换为 Flutter 的 ThemeMode
material.ThemeMode toFlutterTheme(AppThemeMode mode) {
  switch (mode) {
    case AppThemeMode.system:
      return material.ThemeMode.system;
    case AppThemeMode.light:
      return material.ThemeMode.light;
    case AppThemeMode.dark:
      return material.ThemeMode.dark;
  }
}
