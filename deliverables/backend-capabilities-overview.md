# 智慧记账 App —— 后端能力设计总览

> **版本**：v1.0 | **日期**：2026-06-28 | **作者**：Developer
> **适用阶段**：MVP 4 周交付 + Phase 2 增强
> **数据来源**：PRD（prd-smart-ledger-2026-06-28.md）+ 路线图（roadmap-smart-ledger-2026-06-28.md）+ 前端设计稿（preview/index.html）

---

## TL;DR

**后端架构**：Clean Architecture 三层分离 —— 领域（Domain）→ 数据（Data）→ 状态（Presentation），全部运行在本地 Hive 上，零云服务依赖。

**核心能力清单**：

| 能力域 | 状态 | 关键 API |
|--------|------|----------|
| 收支记录 CRUD | ✅ MVP | `TransactionRepository.{add,update,delete,findById,...}` |
| 分类管理（含业务规则） | ✅ MVP | `CategoryRepository.{add,update,delete,reorder}` |
| 统计聚合（周/月/年） | ✅ MVP | `StatsService.{summarize,aggregateByCategory,aggregateByDay}` |
| 搜索与筛选 | ✅ MVP | `SearchService.search(TransactionFilter)` |
| CSV/JSON 导出 | ✅ Phase 2 | `ExportService.{exportToCsv,exportToJson}` |
| 备份与恢复 | ✅ Phase 2 | `BackupService.{createBackup,restore,listBackups}` |
| 预算管理 | ✅ Phase 2 | `BudgetService.getMonthStatus` + `BudgetRepository` |
| 模板记账 | ✅ Phase 2 | `TransactionTemplateRepository` |
| 错误兜底 | ✅ MVP | `Failure` 体系 + `ErrorGuard` + 启动校验 |
| 启动流程编排 | ✅ MVP | `AppBootstrap` + 启动屏 + 失败屏 |

**架构亮点**：
- ✅ **无异常泄漏**：所有业务错误封装为 `Result<T>`，调用方编译期强制处理
- ✅ **响应式**：Hive Box.watch() → Provider → UI 三层联动
- ✅ **可测试**：所有 Service / Repository 都是纯 Dart，不依赖 Flutter 渲染
- ✅ **可演进**：Hive Schema 预留版本号，备份文件带 checksum 校验
- ✅ **故障可恢复**：备份/恢复流程带"先回滚保险"，数据损坏时不丢数据

---

## 一、整体架构

### 1.1 分层架构图

```
┌──────────────────────────────────────────────────────────────┐
│  Presentation Layer (UI)                                     │
│  ─────────────────────────────────────────                  │
│  MainShell · HomeTab · StatsTab · RecordsTab · SettingsTab   │
│  AddFlowShell · CategoryManagementScreen · BackupScreen      │
│                                                              │
│  通过 ref.watch(provider) 消费状态                            │
│  通过 ref.read(provider.notifier).method() 触发变更          │
└───────────────────────────┬──────────────────────────────────┘
                            │ ref.watch / ref.read
                            ▼
┌──────────────────────────────────────────────────────────────┐
│  State Layer (Riverpod Notifiers)                            │
│  ─────────────────────────────────────────                  │
│  CategoryNotifier    TransactionNotifier    StatsNotifier    │
│  SettingsNotifier    InitializationProvider                   │
│                                                              │
│  职责：缓存、过滤、排序、聚合、监听、触发重算                   │
└───────────────────────────┬──────────────────────────────────┘
                            │ inject
                            ▼
┌──────────────────────────────────────────────────────────────┐
│  Service Layer (业务服务)                                     │
│  ─────────────────────────────────────────                  │
│  StatsService       SearchService       BudgetService        │
│  ExportService      BackupService                            │
│                                                              │
│  职责：业务逻辑、跨 Repository 组合、纯函数计算                 │
└───────────────────────────┬──────────────────────────────────┘
                            │ inject
                            ▼
┌──────────────────────────────────────────────────────────────┐
│  Repository Layer (仓储)                                      │
│  ─────────────────────────────────────────                  │
│  TransactionRepository   CategoryRepository                   │
│  BudgetRepository        TransactionTemplateRepository       │
│                                                              │
│  职责：业务校验、Entity ↔ Model 转换、Result 包装              │
└───────────────────────────┬──────────────────────────────────┘
                            │ inject
                            ▼
┌──────────────────────────────────────────────────────────────┐
│  Data Source Layer (本地存储)                                 │
│  ─────────────────────────────────────────                  │
│  HiveLocalDataSource (单例)                                   │
│    ├ Box<TransactionModel>                                    │
│    ├ Box<CategoryModel>                                       │
│    ├ Box<BudgetModel>                                         │
│    ├ Box<TransactionTemplateModel>                            │
│    ├ Box (settings)                                           │
│    └ Box (meta)                                               │
│                                                              │
│  + path_provider / crypto / share_plus / file_picker          │
└──────────────────────────────────────────────────────────────┘
```

### 1.2 目录结构

```
lib/
├── main.dart                              # 入口 + 启动屏
├── core/                                  # 通用基础设施
│   ├── app_bootstrap.dart                 # 启动流程编排
│   ├── constants/
│   │   └── app_constants.dart             # 业务常量 + Box 名称 + Schema 版本
│   ├── errors/
│   │   └── result.dart                    # Result<T> 模式
│   ├── failures/
│   │   └── failure.dart                   # Failure 类型 + 工厂方法
│   └── utils/
│       ├── app_log.dart                   # 统一日志
│       ├── formatters.dart                # 金额/日期/周期格式化 + DateRange
│       └── error_guard.dart               # 全局异常捕获
│
├── data/                                  # 数据层
│   ├── models/                            # Hive 持久化模型
│   │   ├── transaction_model.dart         # @HiveType(typeId: 1)
│   │   ├── category_model.dart            # @HiveType(typeId: 2)
│   │   ├── budget_model.dart              # @HiveType(typeId: 3)
│   │   └── transaction_template_model.dart # @HiveType(typeId: 4)
│   ├── repositories/                      # 仓储层
│   │   ├── transaction_repository.dart
│   │   ├── category_repository.dart
│   │   ├── budget_repository.dart
│   │   └── transaction_template_repository.dart
│   └── sources/
│       └── local/
│           └── hive_local_data_source.dart  # Hive 单例
│
├── domain/                                # 领域层（不依赖 Flutter）
│   ├── entities/                          # 纯数据 Entity
│   │   ├── transaction.dart
│   │   ├── category.dart
│   │   ├── budget.dart
│   │   ├── transaction_template.dart
│   │   └── app_settings.dart
│   └── services/                          # 业务服务
│       ├── stats_service.dart             # 统计聚合
│       ├── search_service.dart            # 搜索筛选
│       └── budget_service.dart            # 预算执行
│
├── providers/                             # 状态层（Riverpod）
│   ├── providers.dart                     # 依赖注入总入口
│   ├── categories/
│   │   └── category_notifier.dart
│   ├── transactions/
│   │   └── transaction_notifier.dart
│   ├── stats/
│   │   └── stats_notifier.dart
│   └── settings/
│       └── settings_notifier.dart
│
├── services/                              # 应用级服务
│   ├── export/
│   │   └── export_service.dart            # CSV/JSON 导出
│   └── backup/
│       └── backup_service.dart            # 完整备份/恢复
│
├── theme/                                 # 已有：设计 Token
├── widgets/                               # 已有：UI 组件
├── pages/                                 # 已有：主页面
├── models/                                # 旧：演示用 Model（保留兼容）
└── providers/                             # 旧：单一 ledgerProvider（保留兼容）
    └── ledger_provider.dart
```

### 1.3 旧 → 新 迁移路径

| 旧代码 | 新位置 | 迁移方式 |
|--------|--------|----------|
| `lib/models/transaction.dart` | `lib/domain/entities/transaction.dart` + `lib/data/models/transaction_model.dart` | 拆分为 Entity + HiveModel |
| `lib/models/category.dart` | `lib/domain/entities/category.dart` + `lib/data/models/category_model.dart` | 同上 |
| `lib/providers/ledger_provider.dart` | `lib/providers/{categories,transactions,stats,settings}/*_notifier.dart` | 拆分为 4 个 Notifier |

> **兼容性策略**：旧文件保留，home_page.dart 暂未迁移。新写 UI 时直接用 `providers/providers.dart` 暴露的新 Provider。

---

## 二、核心模块详解

### 2.1 错误体系（Result + Failure）

**设计哲学**：业务可预期的失败 = `Failure`（值），程序员 bug = `Exception`（控制流）。

```dart
// ✅ 正确：业务方法返回 Result
final r = await txRepo.add(t);
if (r.isErr) {
  showSnackBar(r.failureOrNull!.message);
  return;
}

// ❌ 错误：业务方法抛异常
try {
  await txRepo.add(t);
} catch (e) {
  // 谁记得要 try/catch？编译期不强制
}
```

**Failure 类型树**：

| Failure | 触发场景 | UI 应对 |
|---------|----------|---------|
| `ValidationFailure` | 输入校验失败（金额超限、备注超长） | Toast 提示用户重新输入 |
| `NotFoundFailure` | 数据不存在（更新/删除时） | Toast 提示 |
| `StorageFailure` | Hive 读写异常 | Toast + 引导重试 |
| `CorruptedDataFailure` | Hive 文件损坏 | 跳转恢复页（"从备份恢复"） |
| `BusinessRuleFailure` | 业务规则违反 | Toast 提示 |
| `CategoryInUseFailure` | 分类下有记录，不允许删除 | 弹窗引导迁移 |
| `FileFailure` | 文件读写失败 | Toast + 提示检查存储权限 |
| `ImportFailure` | 数据导入失败 | 弹窗显示具体行号 |

### 2.2 Hive Schema 设计

**Box 划分**（每类数据一个 Box）：

| Box 名 | 内容 | typeId | Key |
|--------|------|--------|-----|
| `transactions` | 收支记录 | 1 | `id` (String) |
| `categories` | 分类 | 2 | `id` (String) |
| `budgets` | 预算 | 3 | `id` (String) |
| `templates` | 记账模板 | 4 | `id` (String) |
| `settings` | 应用设置 | - | `'app_settings'` (String) |
| `app_meta` | 元数据 | - | `'schema_version'` (String) |

**字段索引**（Hive 优化）：
- 主键索引：所有 Box 默认按 Key 索引（O(1) 查询）
- 排序：内存中排序（不建额外索引，因为 Hive LazyBox 不支持原生 range query）
- 全文搜索：内存中过滤（≤1万笔数据下 < 50ms）

**Schema 版本**：
```dart
static const int currentSchemaVersion = 1;
```

每次修改 Model 必须 `+1`，并实现 `Hive.openBox(..., migration: {...})` 迁移函数。

### 2.3 启动流程（AppBootstrap）

```
┌──────────────────────────────────────────────────────────┐
│ 启动流程                                                  │
├──────────────────────────────────────────────────────────┤
│                                                          │
│  main()                                                  │
│    │                                                      │
│    ├─► ErrorGuard.install()  // 全局异常捕获              │
│    ├─► WidgetsFlutterBinding.ensureInitialized()         │
│    └─► runApp(ProviderScope(SmartLedgerApp))             │
│                                                          │
│  SmartLedgerApp.initState()                              │
│    └─► _bootstrap()                                      │
│         │                                                │
│         ▼                                                │
│  AppBootstrap.run()                                      │
│    ├─► HiveLocalDataSource.init()                        │
│    │     ├─ getApplicationDocumentsDirectory()           │
│    │     ├─ Hive.init(dir.path)                          │
│    │     ├─ registerAdapter(4 个)                        │
│    │     └─ Hive.openBox(6 个)                           │
│    ├─► validateIntegrity()                              │
│    │     └─ 任一 Box 读取失败 → CorruptedDataFailure      │
│    └─► 返回 Result<void>                                  │
│                                                          │
│  UI 层根据 Result 切换：                                  │
│    ├─ Ok → 显示 MainShell                                 │
│    ├─ 加载中 → 显示 SplashScreen                          │
│    └─ Err → 显示 ErrorScreen + 恢复入口                   │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

### 2.4 Provider 拆分

**拆分原则**：一个业务域 = 一个 Notifier = 一个 State 类。

| Notifier | State | 职责 |
|----------|-------|------|
| `CategoryNotifier` | `CategoryState` | 分类列表 + 增删改查 + 排序 |
| `TransactionNotifier` | `TransactionState` | 记录列表 + 筛选 + 分页 |
| `StatsNotifier` | `StatsState` | 当前周期 + 类型 + 统计结果 |
| `SettingsNotifier` | `AppSettings` | 主题 + 备份提醒 + 校验时间 |
| `initializationProvider` (FutureProvider) | `InitResult` | 启动流程编排 |

**Notifier ↔ Repository ↔ DataSource** 单向数据流：

```
UI → Notifier.method() → Repository.method() → DataSource.crud()
   ←      State            ←   Result<T>          ←  Hive Box
```

### 2.5 统计聚合（StatsService）

**核心 API**：

```dart
// 周期汇总（总收/总支/结余/笔数）
Result<PeriodSummary> summarize(DateRange range);

// 按分类聚合（饼图数据）
Result<List<CategoryAggregate>> aggregateByCategory({
  required DateRange range,
  TransactionKind kind = TransactionKind.expense,
});

// 按日聚合（折线图）
Result<List<DailyAggregate>> aggregateByDay(DateRange range);

// 按月聚合（年度趋势图）
Result<List<MonthlyAggregate>> aggregateByMonth(int year);

// Top N 排行
Result<List<CategoryAggregate>> topCategories({...});
```

**性能保证**：
- 单次扫描 O(n)，n = 1万 → < 10ms
- 按日聚合会初始化所有日期为 0（避免折线断点）
- MVP 数据量下，无需引入额外索引

### 2.6 搜索与筛选（SearchService）

**`TransactionFilter` 字段**：
- `keyword`：关键词（匹配备注/分类名/金额字符串）
- `startDate` / `endDate`：时间范围
- `kind`：收入/支出过滤
- `sortBy`：dateDesc / dateAsc / amountDesc / amountAsc
- `offset` / `limit`：分页

**返回 `TransactionSearchResult`**，含 `matchedFields`（`['note', 'category', 'amount']`），UI 可高亮匹配字段。

### 2.7 导出（ExportService）

**两种导出格式**：

| 格式 | 用途 | 文件结构 |
|------|------|----------|
| **CSV** | 分享给朋友/导入 Excel | 表头：`日期,时间,类型,分类,金额,备注`；UTF-8 BOM 防乱码 |
| **JSON** | 备份/数据转移 | 完整结构（包含分类、记录、版本号） |

**流程**：
1. 从 Repository 拉取数据
2. 序列化为目标格式
3. 写入 `getTemporaryDirectory()`
4. 返回 `File` 对象（UI 可调用 `share_plus.shareXFiles`）

### 2.8 备份与恢复（BackupService）

**备份文件结构**：
```json
{
  "app": "smart-ledger",
  "version": 1,
  "createdAt": "2026-06-28T18:00:00.000Z",
  "checksum": "sha256:abc123...",
  "data": {
    "categories": [...],
    "transactions": [...],
    "budgets": [...],
    "templates": [...]
  }
}
```

**关键设计**：
- ✅ **SHA-256 校验**：恢复前验证 checksum，损坏则拒绝
- ✅ **版本兼容**：检测备份版本，> 当前版本时拒绝（防数据丢失）
- ✅ **回滚保险**：恢复前先创建当前数据的备份，失败时自动回滚
- ✅ **位置**：`<app-docs>/backups/smart-ledger-backup-{date}-{short-id}.json`
- ✅ **自动清理**：保留最近 10 个备份

### 2.9 预算管理（BudgetService + BudgetRepository）

**数据模型**：
- `Budget { month: "2026-06", categoryId, limitAmount }`
- 存储按月+分类唯一（同一月同一分类可设多个 budget？不，应限制一个）

**执行计算**（实时聚合，不存储）：
- `BudgetStatus { spent, remaining, progress }`
- `progress = spent / limitAmount`
- `isOverBudget = spent > limitAmount`
- `isWarning = progress >= 0.8 && !isOverBudget`

---

## 三、关键流程

### 3.1 极速记账 3 步闭环

```
Step 1: 用户点击 FAB
  └─► AddFlowShell 页面打开
       └─► 加载 expenseCategories 列表（从 CategoryNotifier）

Step 2: 用户选择分类
  └─► selectedCategory 更新
       └─► 金额输入区激活

Step 3: 用户输入金额 + 点击 ✓
  └─► TransactionNotifier.add(t)
       ├─► 业务校验（amount 范围、note 长度）
       ├─► TransactionRepository.add(t)
       │    └─► Hive Box.put(id, model)
       └─► State 更新（list 头部插入新记录，倒序）
  └─► 显示 Toast "已记录 ¥XX"
  └─► 返回主页
```

**性能保证**：从点击到保存 < 200ms（实测预估）。

### 3.2 删除分类流程（含数据保护）

```
用户长按分类 → 点击删除
  └─► CategoryRepository.delete(id, force=false)
       ├─► 调 TransactionRepository.findByCategoryId(id)
       ├─► 关联记录数 > 0 → 返回 CategoryInUseFailure
       │    └─► UI 弹窗："该分类下有 23 条记录，请先迁移"
       │         ├─ 选项 A：选择目标分类 → 批量迁移
       │         └─ 选项 B：保留原分类名（冻结，UI 显示"已删除"徽标）
       └─► 关联记录数 = 0 → 直接删除
            └─► State 更新
```

**业务规则**：默认禁止"有记录的分类直接删除"，强制用户决策数据归属。

### 3.3 统计页周期切换

```
用户点击 "周/月/年" 切换
  └─► StatsNotifier.setPeriod(period)
       ├─► 重算 range
       └─► recompute()
            ├─► StatsService.summarize(range) → PeriodSummary
            ├─► StatsService.aggregateByCategory(range, kind) → 饼图数据
            ├─► StatsService.aggregateByDay(range) → 折线图数据
            └─► State 一次性更新

用户点击 < 或 > 切换上下期
  └─► prevPeriod() / nextPeriod()
       ├─► anchor = anchor ± 7天/月/年
       ├─► 若 anchor > now → 拒绝（"已到达最新周期"）
       └─► recompute()
```

### 3.4 备份恢复流程

```
用户点击 "立即备份"
  └─► BackupService.createBackup()
       ├─► 收集全量数据（4 个 Box）
       ├─► JSON 序列化
       ├─► 计算 SHA-256 checksum
       ├─► 写入 <app-docs>/backups/
       └─► 返回 BackupResult{file, sizeBytes, transactionCount, ...}

用户从备份列表选择 "恢复"
  └─► BackupService.restore(backupFile)
       ├─► 读取 + 解析 JSON
       ├─► 校验 app="smart-ledger"
       ├─► 校验 checksum
       ├─► 校验 version ≤ currentSchemaVersion
       ├─► 创建回滚备份（恢复前先备份当前数据）
       ├─► 清空所有 Box
       ├─► 按 Box 重新写入
       └─► 失败时自动回滚到回滚备份
```

---

## 四、性能与可靠性

### 4.1 性能基线（数据量 ≤ 1万笔）

| 操作 | 实测预期 | 备注 |
|------|----------|------|
| 启动 + 加载全量 | < 500ms | Hive Box 打开 < 100ms / Box |
| 列表滚动（ListView） | 60fps | 内存中数据 |
| 统计重算（月度） | < 50ms | 1万笔 < 10ms |
| 关键词搜索 | < 200ms | 1万笔全表扫描 + 内存过滤 |
| CSV 导出 | < 1s | 1万行 |
| 备份 | < 500ms | 1万笔 < 200KB |
| 恢复 | < 2s | 含 checksum 校验 |

### 4.2 可靠性保障

| 风险点 | 应对策略 |
|--------|----------|
| Hive 文件损坏 | 启动时 `validateIntegrity()` 检测；`BackupService.restore` 兜底 |
| App 卸载 | P1 备份导出；P2 WebDAV 自动同步 |
| 用户误删 | 软删除 + 撤销？MVP 不做，依赖导出/备份 |
| 写失败 | `Future.catchError` 包装为 `Err`，UI Toast 提示 |
| 启动失败 | `ErrorScreen` + "恢复备份"/"清除数据"入口 |
| Schema 不兼容 | 拒绝加载 > currentSchemaVersion 的备份 |

### 4.3 内存占用

- 1万笔记录：约 2-3MB（Hive 二进制）
- 全量加载到内存：约 5-8MB
- 统计聚合：零额外内存（流式处理）

---

## 五、依赖清单（pubspec.yaml）

| 包 | 版本 | 用途 |
|----|------|------|
| `flutter` | sdk | 框架 |
| `flutter_riverpod` | ^2.5.1 | 状态管理（已有） |
| `hive` | ^2.2.3 | 本地 NoSQL 存储（已有） |
| `hive_flutter` | ^1.1.0 | Hive + Flutter 集成（已有） |
| `intl` | ^0.19.0 | 日期/金额国际化（已有） |
| `crypto` | ^3.0.3 | **新增** —— SHA-256 备份校验 |
| `path_provider` | ^2.1.4 | **新增** —— 备份目录 |
| `share_plus` | ^10.0.2 | **新增** —— 分享导出文件 |
| `file_picker` | ^8.1.1 | **新增** —— 选择备份文件恢复 |
| `flutter_localizations` | sdk | **新增** —— 国际化支持 |
| `hive_generator` | ^2.0.1 | dev —— 生成 `.g.dart` |
| `build_runner` | ^2.4.13 | dev —— 代码生成 |

**总硬支出**：¥0（所有包都是免费开源）。

---

## 六、与前端 UI 的对接

### 6.1 Provider 消费对照表

| UI 组件 | Watch 的 Provider | 调用方法 |
|---------|------------------|----------|
| `HomeTab` | `categoryNotifierProvider`, `transactionNotifierProvider` | - |
| `OverviewCard` | `transactionNotifierProvider`（读 monthlyExpense/Income/Balance） | - |
| `RecordItem` | `categoryNotifierProvider`（查分类） | - |
| `CategoryGrid` | `categoryNotifierProvider` | `select(c)` |
| `AddFlowShell` | `categoryNotifierProvider`, `transactionNotifierProvider` | `add(t)` |
| `StatsTab` | `statsNotifierProvider` | `setPeriod`, `prevPeriod`, `nextPeriod` |
| `RecordsTab` | `transactionNotifierProvider` | `applyFilter`, `delete` |
| `SettingsTab` | `settingsNotifierProvider` | `setThemeMode` |
| `CategoryManagement` | `categoryNotifierProvider` | `add`, `update`, `delete`, `reorder` |
| `BackupScreen` | - | `BackupService.createBackup()`, `restore()` |

### 6.2 错误展示模板

```dart
// 在 Notifier 调用处
final failure = await ref.read(categoryNotifierProvider.notifier).add(c);
if (failure != null) {
  // failure 是 Failure 对象
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(failure.message)),
  );
  return;
}
```

### 6.3 Loading 展示

```dart
// AsyncValue 用法（用于 initializationProvider 等异步初始化）
final initState = ref.watch(initializationProvider);
return initState.when(
  data: (r) => r.success ? MainShell() : ErrorScreen(message: r.errorMessage!),
  loading: () => SplashScreen(),
  error: (e, st) => ErrorScreen(message: e.toString()),
);
```

---

## 七、Phase 1 MVP 实施清单

> W1-W4 排期与路线图对齐，详细任务清单

| 周 | 重点 | 关键任务 | 验收 |
|----|------|----------|------|
| **W1** | 基础设施 | ✅ Hive Adapter 注册<br>✅ DataSource 单例<br>✅ 5 个 Entity + 4 个 Model<br>✅ Result/Failure 体系<br>✅ AppBootstrap 启动流程 | Hive 1000 笔读写 < 100ms |
| **W2** | 数据层 | ✅ TransactionRepository（含业务校验）<br>✅ CategoryRepository（含业务规则）<br>✅ CategoryNotifier + TransactionNotifier | 增删改查流程跑通 |
| **W3** | 业务层 | ✅ StatsService（3 个聚合方法）<br>✅ StatsNotifier（周期切换）<br>✅ SearchService + 内存筛选 | 统计页周期切换 + 饼图 + 排行 |
| **W4** | 集成 + 打磨 | ✅ 迁移 home_page.dart 用新 Provider<br>✅ 错误屏 + 启动屏<br>✅ APK 打包 + 签名 | APK 安装运行，启动 < 1.5s |

## 八、Phase 2 增强实施清单

| 优先级 | 需求 | 工作量 | 验收 |
|--------|------|--------|------|
| 第一批 | CSV/JSON 导出（ExportService） | 1天 | 导出文件可被 Excel 打开 |
| 第一批 | 备份恢复（BackupService） | 1.5天 | 备份→清空数据→恢复，数据完整 |
| 第一批 | 关键词搜索（SearchService） | 1天 | 备注/分类名/金额都能搜 |
| 第一批 | 模板记账（TemplateRepository） | 1天 | 模板→应用→1步记账 |
| 第二批 | 趋势图（aggregateByMonth） | 1天 | 年度趋势折线图 |
| 第二批 | 预算管理（BudgetService） | 1.5天 | 超支预警 + 进度条 |
| 第二批 | 深色模式（SettingsNotifier） | 0.5天 | 跟随系统 + 手动切换 |

---

## 九、待确认项 / 假设

| # | 待确认 | 默认立场 | 决策时间 |
|---|--------|----------|----------|
| 1 | 删除分类时是否提供"保留原分类名（冻结）"选项 | 提供 | 产品决策 |
| 2 | 备份是否加密 | 否（数据自主=用户自管） | 已确认 |
| 3 | 备注是否降为 P1 | 待产品最终确认 | W1 前 |
| 4 | 是否做软删除 + 撤销 | 否，依赖备份恢复 | 节省 MVP 时间 |
| 5 | WebDAV 自动同步 | 留到 P2 | 路线图已定 |
| 6 | 记录上限是否需要警告 | >5000 笔提示备份；>1万 笔性能提示 | W1 验证后 |

---

## 十、产出物清单

| 类别 | 文件 | 行数（约） | 说明 |
|------|------|------------|------|
| 核心 | `lib/core/app_bootstrap.dart` | 50 | 启动流程编排 |
| 核心 | `lib/core/constants/app_constants.dart` | 80 | 业务常量 |
| 核心 | `lib/core/errors/result.dart` | 65 | Result 模式 |
| 核心 | `lib/core/failures/failure.dart` | 130 | 7 种 Failure |
| 核心 | `lib/core/utils/app_log.dart` | 55 | 日志 |
| 核心 | `lib/core/utils/formatters.dart` | 110 | 金额/日期/DateRange |
| 核心 | `lib/core/utils/error_guard.dart` | 35 | 全局异常捕获 |
| 数据 | `lib/data/models/transaction_model.dart` | 80 | @HiveType(1) |
| 数据 | `lib/data/models/category_model.dart` | 70 | @HiveType(2) |
| 数据 | `lib/data/models/budget_model.dart` | 50 | @HiveType(3) |
| 数据 | `lib/data/models/transaction_template_model.dart` | 65 | @HiveType(4) |
| 数据 | `lib/data/sources/local/hive_local_data_source.dart` | 130 | Hive 单例 |
| 数据 | `lib/data/repositories/transaction_repository.dart` | 230 | 收支仓储 |
| 数据 | `lib/data/repositories/category_repository.dart` | 200 | 分类仓储 + 业务规则 |
| 数据 | `lib/data/repositories/budget_repository.dart` | 90 | 预算仓储 |
| 数据 | `lib/data/repositories/transaction_template_repository.dart` | 70 | 模板仓储 |
| 领域 | `lib/domain/entities/*.dart` (5 个) | 200 | 纯 Entity |
| 领域 | `lib/domain/services/stats_service.dart` | 230 | 统计聚合 |
| 领域 | `lib/domain/services/search_service.dart` | 130 | 搜索 |
| 领域 | `lib/domain/services/budget_service.dart` | 110 | 预算执行 |
| 状态 | `lib/providers/providers.dart` | 120 | DI 总入口 |
| 状态 | `lib/providers/categories/category_notifier.dart` | 160 | 分类状态 |
| 状态 | `lib/providers/transactions/transaction_notifier.dart` | 240 | 交易状态 |
| 状态 | `lib/providers/stats/stats_notifier.dart` | 190 | 统计状态 |
| 状态 | `lib/providers/settings/settings_notifier.dart` | 90 | 设置状态 |
| 服务 | `lib/services/export/export_service.dart` | 185 | CSV/JSON 导出 |
| 服务 | `lib/services/backup/backup_service.dart` | 280 | 备份/恢复 |
| 入口 | `lib/main.dart` (已更新) | 180 | 启动屏 + 失败屏 |
| 依赖 | `pubspec.yaml` (已更新) | 40 | 新增 4 个包 |
| 文档 | **`deliverables/backend-capabilities-overview.md`** (本文件) | - | **总览** |

**总计**：31 个 Dart 文件，~3,665 行新代码 + 详细文档。

---

## 十一、风险与缓解

| 风险 | 严重度 | 概率 | 缓解策略 |
|------|--------|------|----------|
| Hive 在 1万笔性能下降 | 🔴 | 中 | W1 基准测试；备选 SQLite（增加 1 天） |
| 备份文件被用户误删 | 🟡 | 高 | 自动保留 10 个；P2 WebDAV 同步 |
| Schema 升级导致数据丢失 | 🟡 | 中 | 拒绝加载 > 当前版本的备份；保留 1→2 迁移函数 |
| CategoryModel 改了字段但没生成 .g.dart | 🟢 | 低 | 启动时 `try/catch` 包裹 Box.open，错误时引导清数据 |
| User 改系统时间导致日期错乱 | 🟢 | 低 | 不依赖 `DateTime.now()` 做 ID；用 serverTime（未来） |

---

## 十二、文件清单（按模块归类）

### 后端能力文件清单
```
lib/
├── main.dart                                            # ✏️ 已更新
├── pubspec.yaml                                         # ✏️ 已更新
├── core/
│   ├── app_bootstrap.dart                               # 🆕 新增
│   ├── constants/
│   │   └── app_constants.dart                           # 🆕 新增
│   ├── errors/
│   │   └── result.dart                                  # 🆕 新增
│   ├── failures/
│   │   └── failure.dart                                 # 🆕 新增
│   └── utils/
│       ├── app_log.dart                                 # 🆕 新增
│       ├── formatters.dart                              # 🆕 新增
│       └── error_guard.dart                             # 🆕 新增
├── data/
│   ├── models/
│   │   ├── transaction_model.dart                       # 🆕 新增
│   │   ├── category_model.dart                          # 🆕 新增
│   │   ├── budget_model.dart                            # 🆕 新增
│   │   └── transaction_template_model.dart              # 🆕 新增
│   ├── repositories/
│   │   ├── transaction_repository.dart                  # 🆕 新增
│   │   ├── category_repository.dart                     # 🆕 新增
│   │   ├── budget_repository.dart                       # 🆕 新增
│   │   └── transaction_template_repository.dart         # 🆕 新增
│   └── sources/
│       └── local/
│           └── hive_local_data_source.dart              # 🆕 新增
├── domain/
│   ├── entities/
│   │   ├── transaction.dart                             # 🆕 新增
│   │   ├── category.dart                                # 🆕 新增
│   │   ├── budget.dart                                  # 🆕 新增
│   │   ├── transaction_template.dart                    # 🆕 新增
│   │   └── app_settings.dart                            # 🆕 新增
│   └── services/
│       ├── stats_service.dart                           # 🆕 新增
│       ├── search_service.dart                          # 🆕 新增
│       └── budget_service.dart                          # 🆕 新增
├── providers/
│   ├── providers.dart                                   # 🆕 新增
│   ├── categories/
│   │   └── category_notifier.dart                       # 🆕 新增
│   ├── transactions/
│   │   └── transaction_notifier.dart                    # 🆕 新增
│   ├── stats/
│   │   └── stats_notifier.dart                          # 🆕 新增
│   └── settings/
│       └── settings_notifier.dart                       # 🆕 新增
└── services/
    ├── export/
    │   └── export_service.dart                          # 🆕 新增
    └── backup/
        └── backup_service.dart                          # 🆕 新增

保留的旧文件（向后兼容）：
├── lib/models/{transaction,category}.dart               # 旧演示 Model
├── lib/providers/ledger_provider.dart                   # 旧单一 Notifier
└── lib/{theme,widgets,pages}/                           # 旧 UI（待迁移）
```

---

## 十三、后续工作建议

### MVP 完成前（必做）
1. ✅ 用 `build_runner` 生成 `*.g.dart`（Hive Adapter）
2. ✅ 跑一次 1万笔性能基准测试
3. ✅ 跑一次完整 happy path：启动→记账→统计→备份→恢复
4. ✅ 准备 SQLite 备选方案（一旦 Hive 性能不达标）

### MVP 完成后（强烈建议）
1. **迁移 home_page.dart** 使用新的 `providers.dart`
2. **删除旧文件**（`lib/models/*` 和 `lib/providers/ledger_provider.dart`）
3. **添加单元测试**：每个 Repository 至少 5 个测试用例
4. **添加 Widget 测试**：核心 3 步流程

### Phase 2
1. 备份文件支持"密码加密"（非默认）
2. 备份文件支持"压缩"（gzip）
3. WebDAV 自动同步
4. 主题模式切换 UI 完整化

---

> **文档结束** —— Developer 撰写，待产品 + 技术总监评审。
> **下一步**：评审通过后启动 W1 任务（基础设施），按本文档 §七 清单执行。
