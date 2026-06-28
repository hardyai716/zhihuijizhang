/// 智慧记账 - 应用入口
///
/// 启动流程：
/// 1. Flutter 绑定初始化
/// 2. 全局错误捕获安装
/// 3. 异步初始化 Hive（AppBootstrap）
/// 4. 启动 Flutter UI（ProviderScope 包裹）
///
/// 启动屏：显示 logo + 加载动画，启动完成后进入 MainShell

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_bootstrap.dart';
import 'core/utils/error_guard.dart';
import 'core/utils/app_log.dart';
import 'data/sources/local/hive_local_data_source.dart';
import 'providers/providers.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';

void main() {
  // 1. 错误捕获必须最先
  ErrorGuard.install();

  // 2. Flutter 绑定
  WidgetsFlutterBinding.ensureInitialized();

  // 3. 同步运行 UI，启动屏展示加载状态
  ErrorGuard.runGuarded(() {
    runApp(
      ProviderScope(
        child: const SmartLedgerApp(),
      ),
    );
  });
}

class SmartLedgerApp extends ConsumerStatefulWidget {
  const SmartLedgerApp({super.key});

  @override
  ConsumerState<SmartLedgerApp> createState() => _SmartLedgerAppState();
}

class _SmartLedgerAppState extends ConsumerState<SmartLedgerApp> {
  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final bootstrap = AppBootstrap(HiveLocalDataSource.instance);
    final result = await bootstrap.run();
    if (result.isErr) {
      AppLog.e('Main', '启动失败: ${result.failureOrNull!.message}');
      // TODO: 显示错误屏 + 提供"清除数据"或"恢复备份"入口
    }
  }

  @override
  Widget build(BuildContext context) {
    final initState = ref.watch(initializationProvider);

    return MaterialApp(
      title: '智慧记账',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: initState.when(
        data: (result) {
          if (result.success) {
            return const MainShell();
          }
          return _BootErrorScreen(message: result.errorMessage ?? '未知错误');
        },
        loading: () => const _SplashScreen(),
        error: (e, st) => _BootErrorScreen(message: e.toString()),
      ),
    );
  }
}

/// 启动屏
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.shadowMd,
              ),
              child: const Icon(Icons.account_balance_wallet_rounded,
                  size: 40, color: AppTheme.textOnPrimary),
            ),
            const SizedBox(height: 24),
            const Text('智慧记账',
              style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text('极速 · 纯净 · 自主',
              style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 24, height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5, color: AppTheme.primary,
              ),
            ),
          ],
        ),
      ),
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
              const Icon(Icons.error_outline,
                  size: 64, color: AppTheme.expense),
              const SizedBox(height: 16),
              const Text('应用启动失败',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
