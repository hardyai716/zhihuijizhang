/// Providers 总入口
///
/// 拆分原则：
/// - 每个业务域一个 Notifier（Category/Transaction/Stats/Settings/Backup）
/// - 业务服务（StatsService/SearchService/ExportService）也用 Provider 暴露
/// - DataSource 单例 + Repository 通过 Provider 注入
///
/// AsyncNotifier vs StateNotifier：
/// - 启动时初始化（loadAll）→ 用 AsyncNotifier
/// - 纯计算 → 用 Provider（不变化）
/// - 用户操作驱动 → AsyncNotifier（含 loading/error 状态）

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/app_log.dart';
import '../data/sources/local/hive_local_data_source.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/transaction_template_repository.dart';
import '../domain/entities/app_settings.dart';
import '../domain/services/stats_service.dart';
import '../domain/services/search_service.dart';
import '../domain/services/budget_service.dart';
import '../services/export/export_service.dart';
import '../services/backup/backup_service.dart';
import 'categories/category_notifier.dart';
import 'transactions/transaction_notifier.dart';
import 'stats/stats_notifier.dart';
import 'settings/settings_notifier.dart';

// ══════════════════════════════════
// Data Layer
// ══════════════════════════════════

/// Hive 数据源（单例）
final hiveDataSourceProvider = Provider<HiveLocalDataSource>((ref) {
  return HiveLocalDataSource.instance;
});

// ══════════════════════════════════
// Repositories
// ══════════════════════════════════

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository(ref.watch(hiveDataSourceProvider));
});

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    ref.watch(hiveDataSourceProvider),
    ref.watch(transactionRepositoryProvider),
  );
});

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository(ref.watch(hiveDataSourceProvider));
});

final templateRepositoryProvider = Provider<TransactionTemplateRepository>((ref) {
  return TransactionTemplateRepository(ref.watch(hiveDataSourceProvider));
});

// ══════════════════════════════════
// Services（业务层）
// ══════════════════════════════════

final statsServiceProvider = Provider<StatsService>((ref) {
  return StatsService(
    txRepo: ref.watch(transactionRepositoryProvider),
    catRepo: ref.watch(categoryRepositoryProvider),
  );
});

final searchServiceProvider = Provider<SearchService>((ref) {
  return SearchService(
    txRepo: ref.watch(transactionRepositoryProvider),
    catRepo: ref.watch(categoryRepositoryProvider),
  );
});

final budgetServiceProvider = Provider<BudgetService>((ref) {
  return BudgetService(
    budgetRepo: ref.watch(budgetRepositoryProvider),
    txRepo: ref.watch(transactionRepositoryProvider),
    statsService: ref.watch(statsServiceProvider),
  );
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    txRepo: ref.watch(transactionRepositoryProvider),
    catRepo: ref.watch(categoryRepositoryProvider),
  );
});

final backupServiceProvider = Provider<BackupService>((ref) {
  return BackupService(ref.watch(hiveDataSourceProvider));
});

// ══════════════════════════════════
// Notifiers（状态层）
// ══════════════════════════════════

final categoryNotifierProvider =
    StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(ref.watch(categoryRepositoryProvider));
});

final transactionNotifierProvider =
    StateNotifierProvider<TransactionNotifier, TransactionState>((ref) {
  return TransactionNotifier(
    ref.watch(transactionRepositoryProvider),
    ref.watch(categoryNotifierProvider.notifier),
  );
});

final statsNotifierProvider =
    StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(ref.watch(statsServiceProvider));
});

final settingsNotifierProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref.watch(hiveDataSourceProvider));
});

/// 启动初始化 Provider —— 在 main() Hive 初始化完成后触发业务逻辑初始化
final initializationProvider = FutureProvider<InitResult>((ref) async {
  final hive = ref.read(hiveDataSourceProvider);

  // Hive 已在 main() 里初始化完成，这里无需再调用 init()

  // 校验数据完整性
  final integrityError = hive.validateIntegrity();
  if (integrityError != null) {
    return InitResult.failed(integrityError.message);
  }

  // 初始化预设数据
  final catRepo = ref.read(categoryRepositoryProvider);
  final seedResult = catRepo.seedDefaultsIfEmpty();
  if (seedResult.isErr) {
    return InitResult.failed(seedResult.failureOrNull!.message);
  }

  // 触发数据加载
  await ref.read(categoryNotifierProvider.notifier).load();
  await ref.read(transactionNotifierProvider.notifier).load();

  AppLog.i('Init', '应用初始化完成');
  return InitResult.ok();
});

class InitResult {
  final bool success;
  final String? errorMessage;
  const InitResult._({required this.success, this.errorMessage});

  factory InitResult.ok() => const InitResult._(success: true);
  factory InitResult.failed(String msg) =>
      InitResult._(success: false, errorMessage: msg);
}
