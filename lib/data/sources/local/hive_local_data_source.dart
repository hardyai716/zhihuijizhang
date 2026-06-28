/// Hive 本地数据源 —— 所有 Box 操作的唯一入口
///
/// 职责：
/// - 封装 Box 的打开/关闭
/// - 提供原子的 CRUD
/// - 暴露 Stream 用于响应式监听
///
/// 不在这里放业务逻辑！业务逻辑在 Repository / Service

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/failures/failure.dart';
import '../../../core/utils/app_log.dart';
import '../../models/transaction_model.dart';
import '../../models/category_model.dart';
import '../../models/budget_model.dart';
import '../../models/transaction_template_model.dart';

class HiveLocalDataSource {
  HiveLocalDataSource._();
  static final HiveLocalDataSource instance = HiveLocalDataSource._();

  // ══════════════════════════════════
  // Box 句柄
  // ══════════════════════════════════

  late final Box<TransactionModel> _txBox;
  late final Box<CategoryModel> _catBox;
  late final Box<BudgetModel> _budgetBox;
  late final Box<TransactionTemplateModel> _tplBox;
  late final Box _settingsBox;
  late final Box _metaBox;

  bool _initialized = false;

  // ══════════════════════════════════
  // 初始化
  // ══════════════════════════════════

  /// 启动时调用一次
  Future<void> init() async {
    if (_initialized) return;

    try {
      // 1. 初始化 Flutter 绑定
      await _initHive();
      AppLog.storage('Hive 初始化完成');

      // 2. 注册 Adapter
      if (!Hive.isAdapterRegistered(AppConstants.typeIdTransaction)) {
        Hive.registerAdapter(TransactionModelAdapter());
      }
      if (!Hive.isAdapterRegistered(AppConstants.typeIdCategory)) {
        Hive.registerAdapter(CategoryModelAdapter());
      }
      if (!Hive.isAdapterRegistered(AppConstants.typeIdBudget)) {
        Hive.registerAdapter(BudgetModelAdapter());
      }
      if (!Hive.isAdapterRegistered(AppConstants.typeIdTemplate)) {
        Hive.registerAdapter(TransactionTemplateModelAdapter());
      }
      AppLog.storage('Adapter 注册完成');

      // 3. 打开所有 Box
      _txBox = await Hive.openBox<TransactionModel>(
        AppConstants.boxTransactions,
      );
      _catBox = await Hive.openBox<CategoryModel>(
        AppConstants.boxCategories,
      );
      _budgetBox = await Hive.openBox<BudgetModel>(
        AppConstants.boxBudgets,
      );
      _tplBox = await Hive.openBox<TransactionTemplateModel>(
        AppConstants.boxTemplates,
      );
      _settingsBox = await Hive.openBox(AppConstants.boxSettings);
      _metaBox = await Hive.openBox(AppConstants.boxMeta);

      _initialized = true;
      AppLog.storage('所有 Box 打开完成');
    } catch (e, st) {
      AppLog.e(AppConstants.logTagStorage, 'Hive 初始化失败', e, st);
      rethrow;
    }
  }

  Future<void> _initHive() async {
    final dir = await getApplicationDocumentsDirectory();
    Hive.init(dir.path);
  }

  /// 完全清理（用于卸载/重置）
  Future<void> clearAll() async {
    if (!_initialized) return;
    await _txBox.clear();
    await _catBox.clear();
    await _budgetBox.clear();
    await _tplBox.clear();
    await _settingsBox.clear();
    await _metaBox.clear();
    AppLog.storage('所有数据已清空');
  }

  /// 关闭所有 Box
  Future<void> close() async {
    if (!_initialized) return;
    await Hive.close();
    _initialized = false;
  }

  /// 数据完整性校验 —— 启动时调用
  /// 返回 null 表示正常；返回 CorruptedDataFailure 表示损坏
  Failure? validateIntegrity() {
    try {
      // 触发一次读，确保文件不损坏
      _txBox.values.length;
      _catBox.values.length;
      _budgetBox.values.length;
      _tplBox.values.length;
      return null;
    } catch (e, st) {
      AppLog.e(AppConstants.logTagStorage, '数据完整性校验失败', e, st);
      return CorruptedDataFailure(cause: e);
    }
  }

  // ══════════════════════════════════
  // 公共 Getter（供 Repository 使用）
  // ══════════════════════════════════

  Box<TransactionModel> get transactions => _txBox;
  Box<CategoryModel> get categories => _catBox;
  Box<BudgetModel> get budgets => _budgetBox;
  Box<TransactionTemplateModel> get templates => _tplBox;
  Box get settings => _settingsBox;
  Box get meta => _metaBox;
}
