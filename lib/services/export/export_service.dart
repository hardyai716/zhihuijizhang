/// ExportService —— 数据导出（CSV / JSON）
///
/// 导出流程：
/// 1. 从 Repository 拉取数据
/// 2. 序列化为目标格式
/// 3. 写入临时目录
/// 4. 返回文件路径（供 share_plus 分享）
///
/// 关键点：
/// - CSV 用于 Excel/Numbers 打开
/// - JSON 用于备份/恢复（保留完整结构）
/// - BOM 头确保 Excel 中文不乱码

import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../core/errors/result.dart';
import '../../core/failures/failure.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_log.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/transaction.dart';
import '../../data/repositories/transaction_repository.dart';
import '../../data/repositories/category_repository.dart';
import '../../data/models/transaction_model.dart';
import '../../data/models/category_model.dart';

class ExportService {
  ExportService({
    required TransactionRepository txRepo,
    required CategoryRepository catRepo,
  })  : _txRepo = txRepo,
        _catRepo = catRepo;

  final TransactionRepository _txRepo;
  final CategoryRepository _catRepo;

  // ══════════════════════════════════
  // CSV 导出
  // ══════════════════════════════════

  Result<ExportResult> exportToCsv({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // 1. 取数据
      final Result<List<Transaction>> txResult;
      if (startDate != null && endDate != null) {
        txResult = _txRepo.findByDateRange(startDate, endDate);
      } else {
        txResult = _txRepo.getAll();
      }
      if (txResult.isErr) return Err(txResult.failureOrNull!);

      final cats = _catRepo.getAll();
      if (cats.isErr) return Err(cats.failureOrNull!);
      final catMap = {
        for (final c in cats.valueOrNull!) c.id: c,
      };

      // 2. 生成 CSV 内容
      final buffer = StringBuffer();
      // UTF-8 BOM（Excel 打开不乱码）
      buffer.write('﻿');
      // 表头
      buffer.writeln('日期,时间,类型,分类,金额,备注');
      // 数据行
      for (final t in txResult.valueOrNull!) {
        final cat = catMap[t.categoryId];
        buffer.writeln([
          Formatters.date(t.date),
          Formatters.dateTime(t.date).split(' ').last,
          t.kind.displayName,
          cat?.name ?? '未分类',
          t.amount.toStringAsFixed(2),
          _csvEscape(t.note),
        ].join(','));
      }

      // 3. 写文件
      final filename = '${AppConstants.csvFilePrefix}-'
          '${Formatters.date(DateTime.now())}.csv';
      final file = await _writeToTemp(buffer.toString(), filename);
      AppLog.export('CSV 导出完成: ${txResult.valueOrNull!.length} 行, $file');

      return Ok(ExportResult(
        file: file,
        filename: filename,
        rowCount: txResult.valueOrNull!.length,
        format: ExportFormat.csv,
      ));
    } catch (e, st) {
      AppLog.e(AppConstants.logTagExport, 'CSV 导出失败', e, st);
      return Err(FileFailure(message: 'CSV 导出失败', cause: e));
    }
  }

  String _csvEscape(String s) {
    if (s.contains(',') || s.contains('"') || s.contains('\n')) {
      return '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  // ══════════════════════════════════
  // JSON 导出（完整结构，含分类）
  // ══════════════════════════════════

  Result<ExportResult> exportToJson() async {
    try {
      final txResult = _txRepo.getAll();
      if (txResult.isErr) return Err(txResult.failureOrNull!);

      final cats = _catRepo.getAll();
      if (cats.isErr) return Err(cats.failureOrNull!);

      final payload = {
        'app': 'smart-ledger',
        'version': AppConstants.currentSchemaVersion,
        'exportedAt': DateTime.now().toIso8601String(),
        'categories': cats.valueOrNull!
            .map((c) => CategoryModel.fromEntity(c).toJson())
            .toList(),
        'transactions': txResult.valueOrNull!
            .map((t) => TransactionModel.fromEntity(t).toJson())
            .toList(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(payload);

      final filename = '${AppConstants.jsonFilePrefix}-'
          '${Formatters.date(DateTime.now())}.json';
      final file = await _writeToTemp(json, filename);
      AppLog.export('JSON 导出完成: '
          '${txResult.valueOrNull!.length} 笔记录, ${cats.valueOrNull!.length} 分类');

      return Ok(ExportResult(
        file: file,
        filename: filename,
        rowCount: txResult.valueOrNull!.length,
        format: ExportFormat.json,
      ));
    } catch (e, st) {
      AppLog.e(AppConstants.logTagExport, 'JSON 导出失败', e, st);
      return Err(FileFailure(message: 'JSON 导出失败', cause: e));
    }
  }

  // ══════════════════════════════════
  // 工具方法
  // ══════════════════════════════════

  Future<File> _writeToTemp(String content, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(content, flush: true);
    return file;
  }
}

// ══════════════════════════════════
// 导出结果
// ══════════════════════════════════

enum ExportFormat { csv, json }

class ExportResult {
  final File file;
  final String filename;
  final int rowCount;
  final ExportFormat format;

  const ExportResult({
    required this.file,
    required this.filename,
    required this.rowCount,
    required this.format,
  });

  String get mimeType => switch (format) {
        ExportFormat.csv => 'text/csv',
        ExportFormat.json => 'application/json',
      };
}
