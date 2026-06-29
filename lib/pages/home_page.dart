import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../theme/app_theme.dart';
import '../core/utils/theme_utils.dart';
import '../providers/providers.dart';
import '../widgets/overview_card.dart';
import '../widgets/record_item.dart';
import '../widgets/category_grid.dart';
import '../widgets/numpad.dart';
import '../domain/entities/transaction.dart';
import '../domain/entities/category.dart';
import '../domain/entities/app_settings.dart';
import '../core/errors/result.dart';

// ══════════════════════════════════
// 主入口 — 底部 Tab 导航
// ══════════════════════════════════

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _tabIndex = 0;

  void _switchTab(int i) => setState(() => _tabIndex = i);

  void _openAddFlow() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddFlowShell()));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: IndexedStack(
          index: _tabIndex,
          children: const [
            HomeTab(),
            StatsTab(),
            RecordsTab(),
            SettingsTab(),
          ],
        ),
      ),
      // FAB 在所有 tab 都显示，点击进入记账流程
      floatingActionButton: SizedBox(
        width: 64, height: 64,
        child: FloatingActionButton(
          onPressed: _openAddFlow,
          backgroundColor: AppTheme.primary,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
          child: const Icon(Icons.add, size: 32, color: AppTheme.textOnPrimary),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(c),
    );
  }

  Widget _buildBottomNav(ContextColors c) {
    return Container(
      decoration: BoxDecoration(color: c.surface, boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2)),
      ]),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            _nav(c, Icons.home_rounded, '记账', 0),
            _nav(c, Icons.pie_chart_rounded, '统计', 1),
            const SizedBox(width: 48),
            _nav(c, Icons.list_alt_rounded, '记录', 2),
            _nav(c, Icons.settings_rounded, '设置', 3),
          ]),
        ),
      ),
    );
  }

  Widget _nav(ContextColors c, IconData icon, String label, int idx) {
    final a = idx == _tabIndex;
    final color = a ? c.primary : c.textTertiary;
    return GestureDetector(
      onTap: () => _switchTab(idx), behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: a ? FontWeight.w600 : FontWeight.w400,
              color: color)),
        ]),
      ),
    );
  }
}

// ══════════════════════════════════
// Tab 1: 记账主页
// ══════════════════════════════════

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionNotifierProvider);
    final catState = ref.watch(categoryNotifierProvider);
    final c = context.colors;

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 12, 20, 0), child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('智慧记账', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary)),
            Text(_today(), style: TextStyle(fontSize: 12, color: c.textSecondary)),
          ]),
        ],
      )),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          OverviewCard(expense: txState.monthlyExpense, income: txState.monthlyIncome, balance: txState.monthlyBalance),
          const SizedBox(height: 24),
          Text('最近记录', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 8),
          if (txState.recent(3).isEmpty) _empty(c)
          else Container(decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg), boxShadow: c.shadow),
            clipBehavior: Clip.antiAlias,
            child: Column(children: txState.recent(3).map((t) => RecordItem(transaction: t, categories: catState.categories)).toList())),
          const SizedBox(height: 100),
        ],
      ))),
    ]);
  }

  Widget _empty(ContextColors c) {
    return Container(padding: const EdgeInsets.symmetric(vertical: 40), decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg)),
      child: Center(child: Column(children: [
        Icon(Icons.receipt_long_outlined, size: 48, color: c.textTertiary),
        const SizedBox(height: 12),
        Text('还没有记录', style: TextStyle(fontSize: 14, color: c.textSecondary)),
        const SizedBox(height: 4),
        Text('点击下方 + 开始记账', style: TextStyle(fontSize: 12, color: c.textTertiary)),
      ])));
  }

  String _today() {
    final n = DateTime.now();
    const w = ['周一','周二','周三','周四','周五','周六','周日'];
    return '${n.month}月${n.day}日 ${w[n.weekday - 1]}';
  }
}

// ══════════════════════════════════
// Tab 2: 统计页（按设计稿重做）
// ══════════════════════════════════

enum _StatsPeriod { week, month, year }
enum _ExpenseIncome { expense, income }

class StatsTab extends ConsumerStatefulWidget {
  const StatsTab({super.key});

  @override
  ConsumerState<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends ConsumerState<StatsTab> {
  _StatsPeriod _period = _StatsPeriod.month;
  _ExpenseIncome _eiToggle = _ExpenseIncome.expense;

  DateTime get _now => DateTime.now();

  /// 根据当前 period 获取日期范围
  (DateTime start, DateTime end) get _dateRange {
    switch (_period) {
      case _StatsPeriod.week:
        // 本周一到本周日
        final monday = _now.subtract(Duration(days: _now.weekday - 1));
        return (DateTime(monday.year, monday.month, monday.day),
                DateTime(monday.year, monday.month, monday.day + 6));
      case _StatsPeriod.month:
        return (DateTime(_now.year, _now.month, 1),
                DateTime(_now.year, _now.month + 1, 0));
      case _StatsPeriod.year:
        return (DateTime(_now.year, 1, 1), DateTime(_now.year, 12, 31));
    }
  }

  List<Transaction> _filteredTx(List<Transaction> all) {
    final (start, end) = _dateRange;
    final kind = _eiToggle == _ExpenseIncome.expense ? TransactionKind.expense : TransactionKind.income;
    return all.where((t) =>
      t.kind == kind &&
      !t.date.isBefore(start) && !t.date.isAfter(end.add(const Duration(days: 1)))
    ).toList();
  }

  Map<String, double> _groupByCategory(List<Transaction> txs) {
    final map = <String, double>{};
    for (final t in txs) { map[t.categoryId] = (map[t.categoryId] ?? 0) + t.amount; }
    return map;
  }

  String _periodLabel(DateTime s, DateTime e) => '${s.month}月${s.day}日 — ${e.month}月${e.day}日';

  void _shiftPeriod(int delta) {
    setState(() {
      if (_period == _StatsPeriod.month) {
        // 简化：只切换 month，实际可扩展为任意月份
      } else if (_period == _StatsPeriod.week) {
        // 简化：切换周
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final txState = ref.watch(transactionNotifierProvider);
    final catState = ref.watch(categoryNotifierProvider);
    final c = context.colors;
    final filtered = _filteredTx(txState.all);
    final byCat = _groupByCategory(filtered);
    final total = byCat.values.fold(0.0, (a, b) => a + b);
    final (start, end) = _dateRange;

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Align(alignment: Alignment.centerLeft,
          child: Text('统计', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary)))),
      Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 时间段切换
          Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(
            color: c.surfaceSecondary, borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
            child: Row(children: [
              _periodBtn(c, '周度', _StatsPeriod.week),
              _periodBtn(c, '月度', _StatsPeriod.month),
              _periodBtn(c, '年度', _StatsPeriod.year),
            ])),
          const SizedBox(height: 16),

          // 日期范围行 + 支出/收入切换
          Row(children: [
            IconButton(onPressed: () => _shiftPeriod(-1), icon: Icon(Icons.chevron_left, size: 22, color: c.textSecondary)),
            Expanded(child: Center(child: Text(_periodLabel(start, end), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)))),
            IconButton(onPressed: () => _shiftPeriod(1), icon: Icon(Icons.chevron_right, size: 22, color: c.textSecondary)),
            const SizedBox(width: 8),
            // 支出/收入切换
            Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(
              color: c.surfaceSecondary, borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _eiBtn(c, '支出', _ExpenseIncome.expense),
                _eiBtn(c, '收入', _ExpenseIncome.income),
              ])),
          ]),
          const SizedBox(height: 24),

          // 环形图区域
          Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(
            color: c.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg), boxShadow: c.shadow),
            child: total > 0
              ? Column(children: [
                  SizedBox(height: 200, child: _RingChart(byCat: byCat, total: total, isDark: c.isDark)),
                  const SizedBox(height: 16),
                  Text('¥${total.toInt()}',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFamily: AppTheme.fontFamilyNumber, color: c.textPrimary)),
                  Text(_eiToggle == _ExpenseIncome.expense ? '总支出' : '总收入',
                    style: TextStyle(fontSize: 13, color: c.textTertiary)),
                ])
              : Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 60),
                  Text(_eiToggle == _ExpenseIncome.expense ? '暂无支出数据' : '暂无收入数据',
                    style: TextStyle(color: c.textTertiary)),
                ]))),
          const SizedBox(height: 20),

          // 分类排行列表
          ...byCat.entries.map((e) {
            final cat = catState.findById(e.key);
            final pct = total > 0 ? ((e.value / total * 100)).round() : 0;
            return Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [
              Text(cat?.icon ?? '📌', style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(child: Text(cat?.name ?? '未知', style: TextStyle(fontSize: 14, color: c.textPrimary))),
              Text('¥${e.value.toInt()}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary, fontFamily: AppTheme.fontFamilyNumber)),
            ]));
          }),

          const SizedBox(height: 80),
        ],
      ))),
    ]);
  }

  Widget _periodBtn(ContextColors c, String label, _StatsPeriod p) {
    final active = _period == p;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _period = p),
      child: Container(padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: active ? BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppTheme.radiusFull), boxShadow: c.shadow) : null,
        child: Text(label, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? c.primary : c.textSecondary)))));
  }

  Widget _eiBtn(ContextColors c, String label, _ExpenseIncome ei) {
    final active = _eiToggle == ei;
    return GestureDetector(
      onTap: () => setState(() => _eiToggle = ei),
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: active ? BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppTheme.radiusFull), boxShadow: c.shadow) : null,
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? (_eiToggle == _ExpenseIncome.expense ? AppTheme.expense : AppTheme.income) : c.textSecondary))));
  }
}

// ══════════════════════════════════
// 环形图组件
// ══════════════════════════════════

class _RingChart extends StatelessWidget {
  final Map<String, double> byCat;
  final double total;
  final bool isDark;
  const _RingChart({required this.byCat, required this.total, required this.isDark});

  static const _chartColors = [Color(0xFF014DB2), Color(0xFF10B981), Color(0xFFF59E0B), Color(0xFFEF4444), Color(0xFF8B5CF6), Color(0xFFEC4899), Color(0xFF06B6D4)];

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 200, width: double.infinity,
      child: CustomPaint(painter: _RingPainter(byCat: byCat, total: total, isDark: isDark), size: Size.infinite));
  }
}

class _RingPainter extends CustomPainter {
  final Map<String, double> byCat;
  final double total;
  final bool isDark;
  _RingPainter({required this.byCat, required this.total, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0 || byCat.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.shortestSide / 2) * 0.75;
    final strokeW = radius * 0.35;
    final rect = Rect.fromCircle(center: center, radius: radius);

    var startAngle = -90.0; // 从顶部开始

    final entries = byCat.entries.toList();
    for (var i = 0; i < entries.length; i++) {
      final value = entries[i].value;
      final sweep = (value / total) * 360;
      final paint = Paint()
        ..color = _RingChart._chartColors[i % _RingChart._chartColors.length]
        ..strokeWidth = strokeW
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle * 3.14159 / 180, sweep * 3.14159 / 180, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => old.byCat != byCat || old.total != total || old.isDark != isDark;
}

// ══════════════════════════════════
// Tab 3: 记录列表
// ══════════════════════════════════

class RecordsTab extends ConsumerWidget {
  const RecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionNotifierProvider);
    final grouped = txState.groupedByMonth;
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final c = context.colors;

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Align(alignment: Alignment.centerLeft,
          child: Text('记录', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary)))),
      Expanded(child: sortedKeys.isEmpty
          ? Center(child: Text('暂无记录', style: TextStyle(color: c.textTertiary)))
          : ListView.builder(padding: const EdgeInsets.all(20), itemCount: sortedKeys.length, itemBuilder: (context, idx) {
        final key = sortedKeys[idx];
        final items = grouped[key]!;
        final monthExpense = items.where((t) => t.kind == TransactionKind.expense).fold(0.0, (s, t) => s + t.amount);
        final monthIncome = items.where((t) => t.kind == TransactionKind.income).fold(0.0, (s, t) => s + t.amount);

        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const SizedBox(height: 8),
          Text(_monthLabel(key), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 8),
          Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: c.surfaceSecondary, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _sum(c, '支出', '-¥${_fmt(monthExpense)}', AppTheme.expense),
              _sum(c, '收入', '+¥${_fmt(monthIncome)}', AppTheme.income),
              _sum(c, '结余', '¥${_fmt(monthIncome - monthExpense)}', c.primary),
            ])),
          const SizedBox(height: 4),
          Builder(builder: (ctx) {
            final catState = ref.watch(categoryNotifierProvider);
            return Container(decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg), boxShadow: c.shadow),
              clipBehavior: Clip.antiAlias,
              child: Column(children: items.map((t) => RecordItem(transaction: t, categories: catState.categories)).toList()));
          }),
        ]);
      })),
    ]);
  }

  Widget _sum(ContextColors c, String label, String amount, Color color) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(amount, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color, fontFamily: AppTheme.fontFamilyNumber)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 11, color: c.textTertiary)),
    ]);
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    return '${parts[0]}年${int.parse(parts[1])}月';
  }

  String _fmt(double v) => v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ══════════════════════════════════
// Tab 4: 设置页（功能已接入）
// ══════════════════════════════════

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsNotifierProvider);
    final c = context.colors;
    final isDark = c.isDark;

    return Column(children: [
      Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        child: Align(alignment: Alignment.centerLeft,
          child: Text('设置', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: c.textPrimary)))),
      Expanded(child: ListView(padding: const EdgeInsets.all(20), children: [
        _section(c, '数据管理', [
          _tile(c, Icons.file_download_outlined, '导出数据', 'CSV / JSON', () => _onExport(context, ref)),
          _tile(c, Icons.backup_outlined, '备份与恢复', '本地备份', () => _showToast(context, '备份功能开发中')),
        ]),
        const SizedBox(height: 12),
        _section(c, '记账设置', [
          _tile(c, Icons.category_outlined, '分类管理', '', () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryMgmtPage()));
          }),
          // 深色模式开关（带状态）
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Icon(Icons.dark_mode_outlined, size: 22, color: c.textSecondary),
              const SizedBox(width: 12),
              Expanded(child: Text('深色模式', style: TextStyle(fontSize: 15, color: c.textPrimary))),
              Switch(
                value: isDark,
                onChanged: (v) {
                  ref.read(settingsNotifierProvider.notifier).setThemeMode(v ? AppThemeMode.dark : AppThemeMode.light);
                },
                activeColor: c.primary,
              ),
            ]),
          ),
        ]),
        const SizedBox(height: 12),
        _section(c, '关于', [
          _tile(c, Icons.info_outline, '版本', 'v1.0.0', () => _showVersionDialog(context)),
        ]),
      ])),
    ]);
  }

  Future<void> _onExport(BuildContext context, WidgetRef ref) async {
    showModalBottomSheet(context: context, builder: (ctx) {
      return SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(leading: const Icon(Icons.table_chart, color: AppTheme.primary), title: const Text('导出 CSV'),
          subtitle: const Text('可用 Excel / Numbers 打开'), onTap: () async {
            Navigator.pop(ctx);
            final exportService = ref.read(exportServiceProvider);
            final result = await exportService.exportToCsv();
            if (result.isOk) {
              final r = result.valueOrNull!;
              Share.shareXFiles([XFile(r.file.path)], text: '智慧记账导出数据');
            } else {
              _showToast(context, result.failureOrNull!.message);
            }
          }),
        ListTile(leading: const Icon(Icons.data_object, color: AppTheme.primary), title: const Text('导出 JSON'),
          subtitle: const Text('完整结构，含分类定义'), onTap: () async {
            Navigator.pop(ctx);
            final exportService = ref.read(exportServiceProvider);
            final result = await exportService.exportToJson();
            if (result.isOk) {
              final r = result.valueOrNull!;
              Share.shareXFiles([XFile(r.file.path)], text: '智慧记账导出数据');
            } else {
              _showToast(context, result.failureOrNull!.message);
            }
          }),
        const SizedBox(height: 8),
      ]));
    });
  }

  void _showVersionDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: '智慧记账',
      applicationVersion: 'v1.0.0 (Build 20260628)',
      applicationIcon: Container(width: 64, height: 64, decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd]),
        borderRadius: BorderRadius.circular(16),
      ), child: const Icon(Icons.account_balance_wallet_rounded, size: 36, color: AppTheme.textOnPrimary)),
      children: const [
        Text('一款极速、纯净、自主的记账应用'),
        SizedBox(height: 4),
        Text('\n技术栈: Flutter + Hive + Clean Architecture\n数据存储: 100% 本地，无需注册'),
        Divider(),
        Text('© 2026 智慧记账', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
      ],
    );
  }

  void _showToast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  Widget _section(ContextColors c, String title, List<Widget> children) {
    return Container(decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg), boxShadow: c.shadow),
      clipBehavior: Clip.antiAlias,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c.textTertiary))),
        ...children,
      ]));
  }

  Widget _tile(ContextColors c, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(onTap: onTap, child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Icon(icon, size: 22, color: c.textSecondary),
        const SizedBox(width: 12),
        Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: c.textPrimary))),
        if (subtitle.isNotEmpty) Text(subtitle, style: TextStyle(fontSize: 13, color: c.textTertiary)),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, size: 20, color: c.textTertiary),
      ])));
  }
}

// ══════════════════════════════════
// 分类管理页
// ══════════════════════════════════

class CategoryMgmtPage extends ConsumerWidget {
  const CategoryMgmtPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catState = ref.watch(categoryNotifierProvider);
    final c = context.colors;

    return Scaffold(backgroundColor: c.background, appBar: AppBar(title: const Text('分类管理'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: () => Navigator.pop(context))),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        _catGroup(context, ref, c, '支出分类', catState.expenseCategories),
        const SizedBox(height: 20),
        _catGroup(context, ref, c, '收入分类', catState.incomeCategories),
        const SizedBox(height: 16),
        OutlinedButton.icon(onPressed: () => _showAddDialog(context, ref), icon: const Icon(Icons.add, size: 18),
          label: const Text('新增分类'),
          style: OutlinedButton.styleFrom(foregroundColor: c.textSecondary, side: BorderSide(color: c.divider),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMd)))),
      ]));
  }

  Widget _catGroup(BuildContext context, WidgetRef ref, ContextColors c, String title, List<Category> categories) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textTertiary)),
      const SizedBox(height: 8),
      Container(decoration: BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppTheme.radiusLg), boxShadow: c.shadow),
        clipBehavior: Clip.antiAlias,
        child: Column(children: categories.map((cat) => InkWell(
          onTap: () => _showEditDialog(context, ref, cat),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(children: [
              Text(cat.icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(child: Text(cat.name, style: TextStyle(fontSize: 15, color: c.textPrimary))),
              IconButton(icon: Icon(Icons.delete_outline, size: 20, color: c.textTertiary),
                onPressed: () => _confirmAndDelete(context, ref, cat)),
              ReorderableDragStartListener(index: categories.indexOf(cat), child: Icon(Icons.drag_handle, color: c.textTertiary)),
            ])))).toList())),
    ]);
  }

  void _confirmAndDelete(BuildContext context, WidgetRef ref, Category c) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: Text('删除「${c.name}」？'),
        content: const Text('如果该分类下已有记账记录，删除将失败。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(onPressed: () {
            final failure = ref.read(categoryNotifierProvider.notifier).delete(c.id);
            if (failure != null) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))); } else { Navigator.pop(ctx); }
          }, child: const Text('删除', style: TextStyle(color: AppTheme.expense))),
        ]));
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    TransactionKind kind = TransactionKind.expense;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(title: const Text('新增分类'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: '分类名称')),
          const SizedBox(height: 16),
          DropdownButtonFormField<TransactionKind>(value: kind,
            items: const [DropdownMenuItem(value: TransactionKind.expense, child: Text('支出分类')), DropdownMenuItem(value: TransactionKind.income, child: Text('收入分类'))],
            onChanged: (v) => setD(() => kind = v ?? TransactionKind.expense), decoration: const InputDecoration(labelText: '类型')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () {
            final name = nameCtrl.text.trim(); if (name.isEmpty) return;
            final newCat = Category(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, icon: '📌',
              kind: kind, createdAt: DateTime.now(), updatedAt: DateTime.now());
            final failure = ref.read(categoryNotifierProvider.notifier).add(newCat);
            if (failure != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))); }
            Navigator.pop(ctx);
          }, child: const Text('添加')),
        ])));
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Category cat) {
    final nameCtrl = TextEditingController(text: cat.name);
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('编辑分类'),
        content: TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: '分类名称')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () {
            final name = nameCtrl.text.trim(); if (name.isEmpty) return;
            final failure = ref.read(categoryNotifierProvider.notifier).update(cat.copyWith(name: name));
            if (failure != null) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message))); }
            Navigator.pop(ctx);
          }, child: const Text('保存')),
        ]));
  }
}

// ══════════════════════════════════
// 记账流程 Shell
// ══════════════════════════════════

class AddFlowShell extends ConsumerStatefulWidget {
  const AddFlowShell({super.key});
  @override
  ConsumerState<AddFlowShell> createState() => _AddFlowShellState();
}

class _AddFlowShellState extends ConsumerState<AddFlowShell> {
  int _step = 0; String? _categoryId; double _amount = 0; String _note = ''; TransactionKind _kind = TransactionKind.expense;
  void _next() => setState(() => _step++);
  void _prev() { if (_step == 0) Navigator.pop(context); else setState(() => _step--); }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return WillPopScope(onWillPop: () async { _prev(); return false; },
      child: Scaffold(backgroundColor: c.background, body: SafeArea(child: IndexedStack(index: _step, children: [
        _StepCategory(kind: _kind, onSelect: (id) { _categoryId = id; _next(); }, onBack: _prev, onChangeKind: (k) => setState(() => _kind = k)),
        _StepAmount(categoryId: _categoryId ?? '', kind: _kind, onChangeKind: (k) => setState(() => _kind = k),
            onConfirm: (amount) { _amount = amount; _next(); }, onBack: _prev),
        _StepNote(amount: _amount, categoryId: _categoryId ?? '', kind: _kind, note: _note, onNoteChanged: (v) => _note = v,
            onDone: () {
              final tx = Transaction(id: DateTime.now().millisecondsSinceEpoch.toString(), amount: _amount, kind: _kind,
                categoryId: _categoryId!, date: DateTime.now(), note: _note, createdAt: DateTime.now(), updatedAt: DateTime.now());
              final failure = ref.read(transactionNotifierProvider.notifier).add(tx);
              if (failure != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
              Navigator.pop(context);
            }, onBack: _prev),
      ]))));
  }
}

// Step 1: 选分类（带支出/收入切换 + 新增类目）
class _StepCategory extends ConsumerWidget {
  final TransactionKind kind;
  final void Function(String) onSelect;
  final VoidCallback onBack;
  final ValueChanged<TransactionKind> onChangeKind;

  const _StepCategory({required this.kind, required this.onSelect, required this.onBack, required this.onChangeKind});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catState = ref.watch(categoryNotifierProvider);
    final categories = kind == TransactionKind.expense ? catState.expenseCategories : catState.incomeCategories;
    final c = context.colors;

    return Column(children: [
      _topBar('选择分类', onBack: onBack),
      // 支出/收入切换（显眼）
      Container(padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: c.surfaceSecondary, borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          _expIncBtn(c, '支出', TransactionKind.expense),
          _expIncBtn(c, '收入', TransactionKind.income),
        ])),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: CategoryGrid(
          categories: categories,
          onSelect: (cat) => onSelect(cat.id),
          onAddNew: () => _showAddDialog(context, ref),
        ),
      )),
    ]);
  }

  Widget _expIncBtn(ContextColors c, String label, TransactionKind k) {
    final active = kind == k;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChangeKind(k),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: active
              ? BoxDecoration(color: c.surface, borderRadius: BorderRadius.circular(AppTheme.radiusFull))
              : null,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? c.primary : c.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('新增分类'),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: '分类名称')),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(onPressed: () {
            final name = ctrl.text.trim(); if (name.isEmpty) return;
            final newCat = Category(id: DateTime.now().millisecondsSinceEpoch.toString(), name: name, icon: '📌', kind: kind, createdAt: DateTime.now(), updatedAt: DateTime.now());
            final failure = ref.read(categoryNotifierProvider.notifier).add(newCat);
            if (failure != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failure.message)));
            Navigator.pop(ctx);
          }, child: const Text('添加'))]));
  }
}

// Step 2: 输金额
class _StepAmount extends ConsumerStatefulWidget {
  final String categoryId; final TransactionKind kind; final ValueChanged<TransactionKind> onChangeKind; final void Function(double) onConfirm; final VoidCallback onBack;
  const _StepAmount({required this.categoryId, required this.kind, required this.onChangeKind, required this.onConfirm, required this.onBack});
  @override
  ConsumerState<_StepAmount> createState() => _StepAmountState();
}

class _StepAmountState extends ConsumerState<_StepAmount> {
  String _display = '0';

  void _onKey(String key) {
    setState(() {
      if (key == '.') { if (!_display.contains('.')) _display += '.'; }
      else { if (_display == '0') _display = key; else _display += key; }
    });
  }

  void _onDelete() { setState(() { if (_display.length > 1) _display = _display.substring(0, _display.length - 1); else _display = '0'; }); }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_display) ?? 0;
    final catState = ref.watch(categoryNotifierProvider);
    final cat = catState.findById(widget.categoryId);
    final c = context.colors;

    return Column(children: [
      _topBar('输入金额', onBack: widget.onBack),
      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 32),
        decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(children: [
          Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              _kindToggle('支出', TransactionKind.expense), _kindToggle('收入', TransactionKind.income)])),
          const SizedBox(height: 24),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(cat?.icon ?? '📌', style: const TextStyle(fontSize: 22)), const SizedBox(width: 8),
            Text(cat?.name ?? '', style: const TextStyle(fontSize: 16, color: Colors.white70)),
          ]),
          const SizedBox(height: 12),
          Text('¥$_display', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700, color: Colors.white, fontFamily: AppTheme.fontFamilyNumber, letterSpacing: -1)),
        ])),
      Expanded(child: Container(color: c.surface, padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        child: NumberPad(onKeyTap: _onKey, onDelete: _onDelete, onConfirm: () { if (amount > 0) widget.onConfirm(amount); }))),
    ]);
  }

  Widget _kindToggle(String label, TransactionKind k) {
    final active = widget.kind == k;
    return GestureDetector(onTap: () => widget.onChangeKind(k), child: Container(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: active ? BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppTheme.radiusFull)) : null,
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: active ? AppTheme.primary : Colors.white70))));
  }
}

// Step 3: 备注
class _StepNote extends StatelessWidget {
  final double amount; final String categoryId; final TransactionKind kind; final String note; final ValueChanged<String> onNoteChanged; final VoidCallback onDone; final VoidCallback onBack;
  const _StepNote({required this.amount, required this.categoryId, required this.kind, required this.note, required this.onNoteChanged, required this.onDone, required this.onBack});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(children: [
      _topBar('添加备注', onBack: onBack),
      Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: c.surfaceSecondary, borderRadius: BorderRadius.circular(AppTheme.radiusMd)),
              child: Text('¥${_fmt(amount)}', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: c.textPrimary, fontFamily: AppTheme.fontFamilyNumber)),
            ),
            const SizedBox(height: 20),
            TextField(maxLines: 3, maxLength: 200, decoration: const InputDecoration(hintText: '添加备注（选填）'), onChanged: onNoteChanged),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8,
              children: ['午餐', '晚餐', '打车', '购物', '日用'].map((t) => GestureDetector(
                onTap: () => onNoteChanged(t),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(color: c.surfaceSecondary, borderRadius: BorderRadius.circular(AppTheme.radiusFull)),
                  child: Text(t, style: TextStyle(fontSize: 13, color: c.textSecondary)),
                ),
              )).toList()),
            const SizedBox(height: 40),
            ElevatedButton(onPressed: onDone, child: const Text('确认记账')),
          ],
        ),
      )),
    ]);
  }

  String _fmt(double v) => v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ══════════════════════════════════
// 通用组件
// ══════════════════════════════════

Widget _topBar(String title, {VoidCallback? onBack}) {
  return Builder(builder: (context) {
    final c = context.colors;
    return Container(height: 56, padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(color: c.surface, border: Border(bottom: BorderSide(color: c.divider, width: 0.5))),
      child: Row(children: [
        if (onBack != null) IconButton(icon: const Icon(Icons.arrow_back_ios, size: 18), onPressed: onBack),
        if (onBack != null) const SizedBox(width: 8),
        Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: c.textPrimary)), const Spacer(),
        IconButton(icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary), onPressed: onBack ?? () {}),
      ]));
  });
}
