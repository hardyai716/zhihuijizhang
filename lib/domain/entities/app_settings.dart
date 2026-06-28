/// 应用设置（key-value 形式持久化）
class AppSettings {
  /// 主题模式
  final ThemeMode themeMode;

  /// 是否已同意免责声明
  final bool disclaimerAccepted;

  /// 启动时显示的提示（如最后备份时间）
  final String? lastBackupReminder;

  /// 上次数据校验时间
  final DateTime? lastValidationAt;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.disclaimerAccepted = false,
    this.lastBackupReminder,
    this.lastValidationAt,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
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

enum ThemeMode {
  system,
  light,
  dark;
}
