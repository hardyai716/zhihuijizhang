/// 简单日志工具 —— 集中所有 print / debugPrint
///
/// 设计原因：
/// - 后续可一键切换为 flutter_logger / talker
/// - 统一 Tag 格式便于 grep
/// - 提供 `isDebug` 开关，Release 模式可关闭 verbose 输出

import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class AppLog {
  AppLog._();

  /// 是否开启详细日志（Release 关闭）
  static bool _verbose = kDebugMode;
  static bool get verbose => _verbose;

  static void setVerbose(bool v) => _verbose = v;

  /// 通用日志
  static void d(String tag, String message) {
    if (_verbose) {
      // ignore: avoid_print
      print('[$tag] $message');
    }
  }

  /// 信息
  static void i(String tag, String message) {
    // ignore: avoid_print
    print('ℹ️ [$tag] $message');
  }

  /// 警告（可恢复错误）
  static void w(String tag, String message, [Object? error]) {
    // ignore: avoid_print
    print('⚠️ [$tag] $message${error != null ? ' | $error' : ''}');
  }

  /// 错误（不可恢复）
  static void e(String tag, String message, [Object? error, StackTrace? st]) {
    // ignore: avoid_print
    print('❌ [$tag] $message${error != null ? ' | $error' : ''}');
    if (st != null && _verbose) {
      // ignore: avoid_print
      print(st);
    }
  }

  // ══════════════════════════════════
  // 业务模块快捷方法
  // ══════════════════════════════════

  static void storage(String msg) => d(AppConstants.logTagStorage, msg);
  static void repo(String msg) => d(AppConstants.logTagRepo, msg);
  static void service(String msg) => d(AppConstants.logTagService, msg);
  static void export(String msg) => d(AppConstants.logTagExport, msg);
  static void import(String msg) => d(AppConstants.logTagImport, msg);
  static void backup(String msg) => d(AppConstants.logTagBackup, msg);
}
