# 智慧记账（Smart Ledger）

> 个人自用、零成本、极速、纯净的本地记账 App。

## 项目特点

- 🚀 **极速 3 步记账**：点 → 选分类 → 输金额 → 备注 → 完事，< 200ms 完成一次录入
- 🧘 **纯净体验**：0 广告、0 推送、0 注册、0 后台
- 🔒 **100% 本地**：数据完全在你手机上，可导出 CSV/JSON
- 🛠️ **零成本实现**：Flutter + Hive 单 APK，Android 直接安装

## 技术栈

| 层级 | 技术 |
|------|------|
| 框架 | Flutter 3.44+ / Dart 3.12+ |
| 状态管理 | Riverpod (flutter_riverpod 2.6) |
| 本地存储 | Hive 5 个 Box（5.x） |
| 架构 | Clean Architecture 三层（core / data / domain / providers） |
| 错误体系 | `Result<T>` sealed class + 7 种 `Failure` |

## 目录结构

```
lib/
├── core/              # 核心：错误体系(Result/Failure)、启动、格式化、日志
├── data/              # 数据层：Hive Model、Repository、DataSource
├── domain/            # 领域层：Entity（纯 Dart）、Service（统计/搜索/预算）
├── providers/         # 状态层：按业务域拆分的 Notifier
├── services/          # 应用服务：CSV/JSON 导出、SHA-256 备份
├── pages/             # 8 个 UI 页面（主页/统计/记录/设置/3 步记账流/分类管理）
├── widgets/           # 复用组件（卡片/键盘/分类网格/记录行）
├── theme/             # 设计 Token（颜色/间距/圆角/阴影/字体）
└── main.dart          # AppBootstrap 入口

test/                  # 22 个测试用例（业务规则 + 性能基准 + happy path）
deliverables/          # PRD / 路线图 / 后端总览 / 集成验证报告
preview/               # HTML 高保真预览（8 页面 + 交互）
```

## 快速开始

```bash
# 1. 装 Flutter SDK（3.44+）
# 2. 拉依赖
flutter pub get

# 3. 跑测试
flutter test
# 22/22 全通过；1万笔聚合 0-1ms

# 4. 打 Android APK
flutter build apk --release
# 产物：build/app/outputs/flutter-apk/app-release.apk（约 20 MB）

# 5. 装到手机
adb install build/app/outputs/flutter-apk/app-release.apk
```

## 路线图

| Phase | 重点 | 状态 |
|-------|------|------|
| P0 MVP | Android APK + 6 项核心功能 | ✅ 已完成 |
| P1-A | 模板/导出/备份/搜索 | ⏳ 待启动 |
| P1-B | 趋势/预算/深色模式 | ⏳ 待启动 |
| P2 | WebDAV 同步（坚果云）+ iOS 评估 | ⏳ 待启动 |

## 文档索引

- [PRD 需求规格书](deliverables/product-strategy/prd-smart-ledger-2026-06-28.md)
- [路线图规划报告](deliverables/product-strategy/roadmap-smart-ledger-2026-06-28.md)
- [后端能力总览](deliverables/backend-capabilities-overview.md)
- [集成验证报告](deliverables/integration-verification-report.md)

## 许可

仅供个人自用。
