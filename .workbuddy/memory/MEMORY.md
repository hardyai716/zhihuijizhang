# 项目长期记忆

## 项目概述
- **项目名称**：智慧记账（Smart Ledger）
- **项目性质**：个人自用的手机端记账App
- **核心约束**：零成本/低成本实现，能安装到手机上
- **核心功能**：日常收支记录、收支统计、分类管理
- **产品哲学**：极速（≤3步录入）、纯净（0广告0推送）、自主（100%本地+可导出）

## 技术决策
- **技术栈**：Flutter + Hive + Android APK（全链路零成本）
- **存储方案**：Hive本地存储，可选坚果云WebDAV同步（P2阶段）
- **分发方式**：Android直接安装APK，iOS需Apple Developer 688元/年
- **竞品对标**：钱迹（最接近纯净体验）
- **开源参考**：BeeCount（Flutter+Riverpod+Drift+SQLite+AI，最推荐）

## 交付物
- PRD需求规格书：deliverables/product-strategy/prd-smart-ledger-2026-06-28.md
- 路线图规划报告：deliverables/product-strategy/roadmap-smart-ledger-2026-06-28.md
- **后端能力总览**：deliverables/backend-capabilities-overview.md（Clean Architecture 三层）
- 前端Flutter代码：lib/ (42 个 Dart 文件，UI 已迁移至新 Provider，旧兼容层 lib/models/* 与 lib/providers/ledger_provider.dart 已删除)
- 前端HTML预览：preview/index.html（已完成 8 个高保真页面）

## 架构（已实施）
- **错误体系**：Result<T> sealed class + 7 种 Failure（Validation/NotFound/Storage/Corrupted/BusinessRule/CategoryInUse/File/Import）
- **数据层**：5 个 Hive Box（transactions/categories/budgets/templates/settings/meta）
- **领域层**：5 个 Entity（不含 Flutter 依赖） + 3 个 Service（Stats/Search/Budget）
- **状态层**：5 个 Notifier（Category/Transaction/Stats/Settings/Init）
- **应用服务**：ExportService（CSV/JSON） + BackupService（SHA-256 + 回滚）

## 关键决策点
- MVP只做Android，iOS待Phase 3评估
- P0"备注"建议降为P1，MVP聚焦6项核心需求
- Hive≤10000笔性能假设需W1实测验证
- P1分两批交付：第一批（数据安全）模板+导出+备份+搜索，第二批（体验）趋势+预算+深色模式
- **删除分类时默认拒绝**：若有记录需先迁移到其他分类（CategoryInUseFailure）
- **备份不加密**：数据自主=用户自管，加密反而是限制
- **Result<T> 替代异常**：业务方法不抛异常，全部返回 Result 强制编译期处理
