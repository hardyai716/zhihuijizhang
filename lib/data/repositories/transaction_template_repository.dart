/// TransactionTemplate Repository —— 记账模板仓储

import '../../core/errors/result.dart';
import '../../core/failures/failure.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/app_log.dart';
import '../../domain/entities/transaction_template.dart';
import '../sources/local/hive_local_data_source.dart';
import '../models/transaction_template_model.dart';

class TransactionTemplateRepository {
  TransactionTemplateRepository(this._local);
  final HiveLocalDataSource _local;

  Result<List<TransactionTemplate>> getAll() {
    try {
      final list = _local.templates.values.map((m) => m.toEntity()).toList()
        ..sort((a, b) {
          final kindCmp = a.kind.index.compareTo(b.kind.index);
          if (kindCmp != 0) return kindCmp;
          return a.sortOrder.compareTo(b.sortOrder);
        });
      return Ok(list);
    } catch (e) {
      return Err(StorageFailure(message: '读取模板失败', cause: e));
    }
  }

  Result<TransactionTemplate> add(TransactionTemplate t) {
    final v = _validate(t);
    if (v != null) return Err(v);
    try {
      _local.templates.put(t.id, TransactionTemplateModel.fromEntity(t));
      AppLog.repo('新增模板 ${t.name}');
      return Ok(t);
    } catch (e) {
      return Err(StorageFailure(message: '保存模板失败', cause: e));
    }
  }

  Result<TransactionTemplate> update(TransactionTemplate t) {
    final v = _validate(t);
    if (v != null) return Err(v);
    try {
      _local.templates.put(t.id, TransactionTemplateModel.fromEntity(t));
      return Ok(t);
    } catch (e) {
      return Err(StorageFailure(message: '更新模板失败', cause: e));
    }
  }

  Result<void> delete(String id) {
    try {
      _local.templates.delete(id);
      return const Ok(null);
    } catch (e) {
      return Err(StorageFailure(message: '删除模板失败', cause: e));
    }
  }

  ValidationFailure? _validate(TransactionTemplate t) {
    if (t.name.trim().isEmpty) {
      return const ValidationFailure(message: '模板名称不能为空');
    }
    if (t.amount <= 0) {
      return const ValidationFailure(message: '金额必须大于0');
    }
    return null;
  }
}
