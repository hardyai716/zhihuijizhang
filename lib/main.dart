/// 智慧记账 - 应用入口
///
/// 启动流程（全部在 runApp 之前同步完成）：
/// 1. Flutter 绑定初始化
/// 2. Hive 初始化 + 打开所有 Box
/// 3. 数据完整性校验
/// 4. 启动 Flutter UI（主题由 Provider 控制）

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/utils/error_guard.dart';
import 'core/utils/app_log.dart';
import 'data/sources/local/hive_local_data_source.dart';
import 'providers/providers.dart';
import 'domain/entities/app_settings.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';

void main() async {
  // 1. 错误捕获必须最先
  ErrorGuard.install();

  // 2. Flutter 绑定
  WidgetsFlutterBinding.ensureInitialized();

  // 3. Hive 初始化（同步等待，确保完成后再进入 UI）
  final dataSource = HiveLocalDataSource.instance;
  var initOk = false;
  String? initError;

  try {
    await dataSource.init();
    AppLog.i('Main', '✓ Hive 初始化完成');

    final integrityError = dataSource.validateIntegrity();
    if (integrityError != null) {
      initError = integrityError.message;
      AppLog.e('Main', '数据校验失败: $initError');
    } else {
      initOk = true;
      AppLog.i('Main', '✓ 数据完整性校验通过');
    }
  } catch (e, st) {
    initError = e.toString();
    AppLog.e('Main', 'Hive 初始化失败', e, st);
  }

  AppLog.i('Main', '═══ 启动完成，进入 UI ═══');

  // 4. 启动 UI（主题由 settingsNotifierProvider 驱动）
  ErrorGuard.runGuarded(() {
    runApp(
      ProviderScope(
        child: SmartLedgerApp(
          initOk: initOk,
          initError: initError,
        ),
      ),
    );
  });
}

class SmartLedgerApp extends ConsumerWidget {
  final bool initOk;
  final String? initError;

  const SmartLedgerApp({
    super.key,
    required this.initOk,
    this.initError,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!initOk) {
      return MaterialApp(
        title: '智慧记账',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: _BootErrorScreen(message: initError ?? '未知错误'),
      );
    }

    // 监听设置变化，驱动主题切换
    final settings = ref.watch(settingsNotifierProvider);
    final isDark = toFlutterTheme(settings.themeMode) == ThemeMode.dark ||
        (toFlutterTheme(settings.themeMode) == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    // 触发数据加载
    ref.read(categoryNotifierProvider.notifier).load();
    ref.read(transactionNotifierProvider.notifier).load();

    return MaterialApp(
      title: '智慧记账',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const MainShell(),
    );
  }
}

/// 启动失败屏
class _BootErrorScreen extends StatelessWidget {
  final String message;
  const _BootErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: AppTheme.expense),
              const SizedBox(height: 16),
              const Text('应用启动失败',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
