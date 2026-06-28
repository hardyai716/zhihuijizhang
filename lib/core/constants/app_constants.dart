/// 业务常量集中管理
/// 避免 magic number 散落各处

class AppConstants {
  AppConstants._();

  // ══════════════════════════════════
  // Hive Box 名称（统一管理，避免拼写错误）
  // ══════════════════════════════════

  static const String boxTransactions = 'transactions';
  static const String boxCategories = 'categories';
  static const String boxBudgets = 'budgets';
  static const String boxTemplates = 'templates';
  static const String boxSettings = 'settings';
  static const String boxMeta = 'app_meta'; // 应用元数据（最后备份时间、Schema 版本等）

  // ══════════════════════════════════
  // Hive TypeAdapter typeId
  // ══════════════════════════════════

  static const int typeIdTransaction = 1;
  static const int typeIdCategory = 2;
  static const int typeIdBudget = 3;
  static const int typeIdTemplate = 4;
  static const int typeIdSettings = 5;

  // ══════════════════════════════════
  // Schema 版本（用于数据迁移）
  // ══════════════════════════════════

  /// 当前 schema 版本，每次修改模型必须 +1
  /// 配合 Hive.openBox(..., migration: ...) 使用
  static const int currentSchemaVersion = 1;

  // ══════════════════════════════════
  // 业务规则
  // ══════════════════════════════════

  /// 金额上限（与 HTML 端对齐：9,999,999.99）
  static const double maxAmount = 9999999.99;

  /// 金额下限
  static const double minAmount = 0.01;

  /// 备注最大长度
  static const int maxNoteLength = 200;

  /// 分类名称最大长度
  static const int maxCategoryNameLength = 12;

  /// 一次性批量导入最大行数（防止 OOM）
  static const int maxImportRows = 50000;

  // ══════════════════════════════════
  // 性能相关
  // ══════════════════════════════════

  /// 列表分页大小
  static const int pageSize = 50;

  /// 搜索防抖延迟
  static const Duration searchDebounce = Duration(milliseconds: 250);

  // ══════════════════════════════════
  // 文件名
  // ══════════════════════════════════

  static const String backupFilePrefix = 'smart-ledger-backup';
  static const String csvFilePrefix = 'smart-ledger';
  static const String jsonFilePrefix = 'smart-ledger';

  // ══════════════════════════════════
  // 日志 Tag（便于定位）
  // ══════════════════════════════════

  static const String logTagStorage = 'Storage';
  static const String logTagRepo = 'Repository';
  static const String logTagService = 'Service';
  static const String logTagExport = 'Export';
  static const String logTagImport = 'Import';
  static const String logTagBackup = 'Backup';
}
