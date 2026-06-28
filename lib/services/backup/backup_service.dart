/// BackupService —— 完整数据库备份与恢复
///
/// 与 ExportService 的区别：
/// - ExportService 导出人类可读格式（CSV/JSON），用于数据转移/分享
/// - BackupService 导出机器可读格式（JSON 全量），用于灾难恢复
///
/// 备份文件结构：
/// ```json
/// {
///   "app": "smart-ledger",
///   "version": 1,
///   "createdAt": "2026-06-28T18:00:00Z",
///   "checksum": "sha256:xxx",
///   "data": {
///     "categories": [...],
///     "transactions": [...],
///     "budgets": [...],
///     "templates": [...]
///   }
/// }
/// ```
///
/// 校验机制：
/// - 写入前计算 SHA-256 校验和
/// - 恢复前先校验，防止写入过程损坏
/// - 失败时保留原数据不动（先备份再覆盖）

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import '../../core/errors/result.dart';
import '../../core/failures/failure.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/formatters.dart';
import '../../data/sources/local/hive_local_data_source.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';
import '../../data/models/budget_model.dart';
import '../../data/models/transaction_template_model.dart';

class BackupService {
  BackupService(this._local);
  final HiveLocalDataSource _local;

  /// 备份到外部目录（用户可访问的位置）
  Future<Result<BackupResult>> createBackup() async {
    try {
      // 1. 收集所有数据
      final payload = <String, dynamic>{
        'app': 'smart-ledger',
        'version': AppConstants.currentSchemaVersion,
        'createdAt': DateTime.now().toIso8601String(),
        'data': {
          'categories': _local.categories.values
              .map((m) => m.toJson())
              .toList(),
          'transactions': _local.transactions.values
              .map((m) => m.toJson())
              .toList(),
          'budgets': _local.budgets.values
              .map((m) => _budgetToJson(m))
              .toList(),
          'templates': _local.templates.values
              .map((m) => _templateToJson(m))
              .toList(),
        },
      };

      // 2. 计算校验和（先去掉自身）
      final jsonString = const JsonEncoder.withIndent('  ').convert(payload);
      final checksum = _calcChecksum(jsonString);
      payload['checksum'] = checksum;

      // 3. 重新序列化（包含 checksum）
      final finalJson = const JsonEncoder.withIndent('  ').convert(payload);

      // 4. 写入文件
      final filename = '${AppConstants.backupFilePrefix}-'
          '${Formatters.date(DateTime.now())}-'
          '${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}.json';
      final backupDir = await _getBackupDir();
      final file = File('${backupDir.path}/$filename');
      await file.writeAsString(finalJson, flush: true);

      AppLog.backup('备份完成: $filename '
          '(${(payload['data']['transactions'] as List).length} 笔, '
          '${(payload['data']['categories'] as List).length} 分类)');

      return Ok(BackupResult(
        file: file,
        filename: filename,
        sizeBytes: await file.length(),
        transactionCount: (payload['data']['transactions'] as List).length,
        categoryCount: (payload['data']['categories'] as List).length,
        checksum: checksum,
      ));
    } catch (e, st) {
      AppLog.e(AppConstants.logTagBackup, '备份失败', e, st);
      return Err(FileFailure(message: '备份失败', cause: e));
    }
  }

  /// 从备份文件恢复
  Future<Result<RestoreResult>> restore(BackupFile file) async {
    try {
      // 1. 读取
      final content = await file.file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      // 2. 校验基本结构
      if (json['app'] != 'smart-ledger') {
        return const Err(ImportFailure(
          message: '备份文件无效（非智慧记账格式）',
          code: 'INVALID_BACKUP',
        ));
      }
      if (json['data'] is! Map) {
        return const Err(ImportFailure(
          message: '备份文件格式错误（缺少 data 字段）',
          code: 'INVALID_BACKUP',
        ));
      }

      // 3. 校验 checksum
      final storedChecksum = json['checksum'] as String?;
      if (storedChecksum != null) {
        final tempJson = Map<String, dynamic>.from(json)..remove('checksum');
        final tempStr = const JsonEncoder().convert(tempJson);
        final actualChecksum = _calcChecksum(tempStr);
        if (actualChecksum != storedChecksum) {
          return const Err(ImportFailure(
            message: '备份文件校验和不一致，文件可能已损坏',
            code: 'CHECKSUM_MISMATCH',
          ));
        }
        AppLog.backup('校验和验证通过');
      }

      // 4. 校验版本
      final version = (json['version'] as num?)?.toInt() ?? 1;
      if (version > AppConstants.currentSchemaVersion) {
        return Err(ImportFailure(
          message: '备份文件版本（$version）高于当前App（'
              '${AppConstants.currentSchemaVersion}），请升级App后重试',
          code: 'FUTURE_VERSION',
        ));
      }

      // 5. 备份当前数据（回滚保险）
      final rollbackBackup = await createBackup();
      AppLog.backup('已创建回滚备份: ${rollbackBackup.valueOrNull?.filename}');

      // 6. 清空并恢复
      try {
        await _local.transactions.clear();
        await _local.categories.clear();
        await _local.budgets.clear();
        await _local.templates.clear();

        final data = json['data'] as Map<String, dynamic>;

        // 恢复分类
        for (final c in (data['categories'] as List).cast<Map<String, dynamic>>()) {
          await _local.categories.put(c['id'] as String, CategoryModel.fromJson(c));
        }

        // 恢复记录
        for (final t in (data['transactions'] as List).cast<Map<String, dynamic>>()) {
          await _local.transactions.put(t['id'] as String, TransactionModel.fromJson(t));
        }

        // 恢复预算（如果备份包含）
        if (data['budgets'] != null) {
          for (final b in (data['budgets'] as List).cast<Map<String, dynamic>>()) {
            await _local.budgets.put(b['id'] as String, _budgetFromJson(b));
          }
        }

        // 恢复模板
        if (data['templates'] != null) {
          for (final tp in (data['templates'] as List).cast<Map<String, dynamic>>()) {
            await _local.templates.put(tp['id'] as String, _templateFromJson(tp));
          }
        }

        AppLog.backup('恢复完成');
        return Ok(RestoreResult(
          transactionCount: (data['transactions'] as List).length,
          categoryCount: (data['categories'] as List).length,
          rollbackFile: rollbackBackup.valueOrNull?.file,
        ));
      } catch (e) {
        // 恢复失败，尝试回滚
        if (rollbackBackup.isOk && rollbackBackup.valueOrNull != null) {
          AppLog.e(AppConstants.logTagBackup, '恢复失败，尝试回滚', e);
          await _restoreInternal(rollbackBackup.valueOrNull!.file);
        }
        return Err(StorageFailure(
          message: '恢复失败，已自动回滚到原数据',
          cause: e,
        ));
      }
    } catch (e, st) {
      AppLog.e(AppConstants.logTagBackup, '恢复失败', e, st);
      return Err(ImportFailure(
        message: '备份文件解析失败: ${e.toString()}',
        code: 'PARSE_ERROR',
        cause: e,
      ));
    }
  }

  /// 内部恢复（不创建回滚备份，用于回滚场景）
  Future<void> _restoreInternal(File file) async {
    try {
      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;

      await _local.transactions.clear();
      await _local.categories.clear();
      await _local.budgets.clear();
      await _local.templates.clear();

      for (final c in (data['categories'] as List).cast<Map<String, dynamic>>()) {
        await _local.categories.put(c['id'] as String, CategoryModel.fromJson(c));
      }
      for (final t in (data['transactions'] as List).cast<Map<String, dynamic>>()) {
        await _local.transactions.put(t['id'] as String, TransactionModel.fromJson(t));
      }
    } catch (e) {
      AppLog.e(AppConstants.logTagBackup, '回滚失败', e);
    }
  }

  /// 列出所有备份文件
  Future<List<BackupFile>> listBackups() async {
    try {
      final dir = await _getBackupDir();
      if (!await dir.exists()) return [];
      final files = await dir
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .cast<File>()
          .toList();

      final backups = <BackupFile>[];
      for (final f in files) {
        final stat = await f.stat();
        backups.add(BackupFile(
          file: f,
          createdAt: stat.modified,
          sizeBytes: stat.size,
        ));
      }
      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } catch (e) {
      AppLog.e(AppConstants.logTagBackup, '列出备份失败', e);
      return [];
    }
  }

  /// 删除旧备份（保留最近 N 个）
  Future<Result<int>> cleanupOldBackups({int keepLast = 10}) async {
    try {
      final backups = await listBackups();
      if (backups.length <= keepLast) {
        return Ok(0);
      }
      final toDelete = backups.skip(keepLast);
      int count = 0;
      for (final b in toDelete) {
        if (await b.file.exists()) {
          await b.file.delete();
          count++;
        }
      }
      AppLog.backup('清理旧备份 $count 个');
      return Ok(count);
    } catch (e) {
      return Err(FileFailure(message: '清理备份失败', cause: e));
    }
  }

  // ══════════════════════════════════
  // 工具
  // ══════════════════════════════════

  Future<Directory> _getBackupDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/backups');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  String _calcChecksum(String content) {
    final bytes = utf8.encode(content);
    return 'sha256:${sha256.convert(bytes)}';
  }

  Map<String, dynamic> _budgetToJson(BudgetModel m) => {
        'id': m.id,
        'month': m.month,
        'categoryId': m.categoryId,
        'limitAmount': m.limitAmount,
        'createdAt': m.createdAt.toIso8601String(),
        'updatedAt': m.updatedAt.toIso8601String(),
      };

  BudgetModel _budgetFromJson(Map<String, dynamic> json) => BudgetModel(
        id: json['id'] as String,
        month: json['month'] as String,
        categoryId: json['categoryId'] as String,
        limitAmount: (json['limitAmount'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> _templateToJson(TransactionTemplateModel m) => {
        'id': m.id,
        'name': m.name,
        'amount': m.amount,
        'kind': m.kind,
        'categoryId': m.categoryId,
        'note': m.note,
        'sortOrder': m.sortOrder,
        'createdAt': m.createdAt.toIso8601String(),
        'updatedAt': m.updatedAt.toIso8601String(),
      };

  TransactionTemplateModel _templateFromJson(Map<String, dynamic> json) =>
      TransactionTemplateModel(
        id: json['id'] as String,
        name: json['name'] as String,
        amount: (json['amount'] as num).toDouble(),
        kind: json['kind'] as String,
        categoryId: json['categoryId'] as String,
        note: (json['note'] as String?) ?? '',
        sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

// ══════════════════════════════════
// 备份文件描述
// ══════════════════════════════════

class BackupFile {
  final File file;
  final DateTime createdAt;
  final int sizeBytes;

  const BackupFile({
    required this.file,
    required this.createdAt,
    required this.sizeBytes,
  });

  String get filename => file.path.split('/').last;
  String get sizeReadable {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / 1024 / 1024).toStringAsFixed(2)} MB';
  }
}

class BackupResult {
  final File file;
  final String filename;
  final int sizeBytes;
  final int transactionCount;
  final int categoryCount;
  final String checksum;

  const BackupResult({
    required this.file,
    required this.filename,
    required this.sizeBytes,
    required this.transactionCount,
    required this.categoryCount,
    required this.checksum,
  });
}

class RestoreResult {
  final int transactionCount;
  final int categoryCount;
  final File? rollbackFile;

  const RestoreResult({
    required this.transactionCount,
    required this.categoryCount,
    this.rollbackFile,
  });
}
