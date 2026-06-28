/// AppBootstrap —— 应用启动流程
///
/// 启动顺序：
/// 1. 初始化 Hive
/// 2. 注册所有 Adapter
/// 3. 打开所有 Box
/// 4. 校验数据完整性
/// 5. 触发 Provider 初始化
///
/// 任一环节失败都返回 AppBootError，由 UI 决定如何处理

import 'dart:async';
import 'errors/result.dart';
import 'failures/failure.dart';
import 'utils/app_log.dart';
import 'constants/app_constants.dart';
import '../data/sources/local/hive_local_data_source.dart';

class AppBootError {
  final String stage;
  final String message;
  final Object? cause;
  const AppBootError({required this.stage, required this.message, this.cause});
}

class AppBootstrap {
  AppBootstrap(this._dataSource);
  final HiveLocalDataSource _dataSource;

  /// 完整启动流程
  Future<Result<void>> run() async {
    try {
      AppLog.i('Bootstrap', '═══ 智慧记账启动 ═══');

      // 1. Hive 初始化
      await _dataSource.init();
      AppLog.i('Bootstrap', '✓ Hive 就绪');

      // 2. 数据完整性校验
      final integrityError = _dataSource.validateIntegrity();
      if (integrityError != null) {
        AppLog.e('Bootstrap', '✗ 数据校验失败', integrityError);
        return Err(integrityError);
      }
      AppLog.i('Bootstrap', '✓ 数据完整性校验通过');

      AppLog.i('Bootstrap', '═══ 启动完成 ═══');
      return const Ok(null);
    } catch (e, st) {
      AppLog.e('Bootstrap', '启动异常', e, st);
      return Err(StorageFailure(
        message: '应用启动失败: ${e.toString()}',
        cause: e,
      ));
    }
  }
}
