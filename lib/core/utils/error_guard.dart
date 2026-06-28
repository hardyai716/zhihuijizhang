/// 全局错误捕获 —— 兜底异常转 Failure
///
/// 设计：
/// - FlutterError.onError 捕获所有 Flutter 框架异常
/// - PlatformDispatcher.instance.onError 捕获所有异步异常
/// - runZonedGuarded 提供最外层 try-catch
///
/// 避免：
/// - 直接打印 stack trace（已通过 AppLog 处理）
/// - 静默吞掉异常（必须记录）

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'app_log.dart';

class ErrorGuard {
  ErrorGuard._();

  /// 安装全局错误捕获
  static void install() {
    // Flutter 框架错误
    FlutterError.onError = (FlutterErrorDetails details) {
      AppLog.e(
        'FlutterError',
        details.exceptionAsString(),
        details.exception,
        details.stack,
      );
    };

    // 异步/平台层错误
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLog.e('PlatformError', '异步异常', error, stack);
      return true; // 已处理
    };
  }

  /// 在指定 zone 中运行（带 try-catch 兜底）
  static void runGuarded(void Function() body) {
    runZonedGuarded(body, (error, stack) {
      AppLog.e('ZoneError', '未捕获异常', error, stack);
    });
  }
}
