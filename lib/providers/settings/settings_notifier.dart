/// Settings Notifier —— 应用设置状态
///
/// 简单 key-value 存储，状态变化自动持久化

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/app_settings.dart';
import '../../data/sources/local/hive_local_data_source.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier(this._local) : super(_load(_local));

  final HiveLocalDataSource _local;

  static AppSettings _load(HiveLocalDataSource local) {
    try {
      final raw = local.settings.get('app_settings');
      if (raw == null) return const AppSettings();
      return _parse(raw as Map);
    } catch (_) {
      return const AppSettings();
    }
  }

  static AppSettings _parse(Map m) {
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (e) => e.name == (m['themeMode'] as String? ?? 'system'),
        orElse: () => ThemeMode.system,
      ),
      disclaimerAccepted: m['disclaimerAccepted'] as bool? ?? false,
      lastBackupReminder: m['lastBackupReminder'] as String?,
      lastValidationAt: m['lastValidationAt'] != null
          ? DateTime.parse(m['lastValidationAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> _serialize(AppSettings s) => {
        'themeMode': s.themeMode.name,
        'disclaimerAccepted': s.disclaimerAccepted,
        'lastBackupReminder': s.lastBackupReminder,
        'lastValidationAt': s.lastValidationAt?.toIso8601String(),
      };

  // ══════════════════════════════════
  // 更新方法
  // ══════════════════════════════════

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    _persist();
  }

  void acceptDisclaimer() {
    state = state.copyWith(disclaimerAccepted: true);
    _persist();
  }

  void recordBackup(String message) {
    state = state.copyWith(lastBackupReminder: message);
    _persist();
  }

  void recordValidation() {
    state = state.copyWith(lastValidationAt: DateTime.now());
    _persist();
  }

  void _persist() {
    try {
      _local.settings.put('app_settings', _serialize(state));
    } catch (_) {
      // 静默失败
    }
  }
}
