import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/providers.dart';
import '../widgets/overview_card.dart';
import '../widgets/record_item.dart';
import '../widgets/category_grid.dart';
import '../widgets/numpad.dart';
import '../domain/entities/transaction.dart';
import '../domain/entities/category.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
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
      floatingActionButton: _tabIndex == 0
          ? SizedBox(
              width: 64, height: 64,
              child: FloatingActionButton(
                onPressed: () => _startAddFlow(context),
                backgroundColor: AppTheme.primary,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                ),
                child: const Icon(Icons.add, size: 32, color: AppTheme.textOnPrimary),
              ),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  void _startAddFlow(BuildContext context) {
    Navigator.push(
      context, MaterialPageRoute(builder: (_) => const AddFlowShell()),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.background,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _nav(Icons.home_rounded, '记账', 0),
              _nav(Icons.pie_chart_rounded, '统计', 1),
              const SizedBox(width: 48),
              _nav(Icons.list_alt_rounded, '记录', 2),
              _nav(Icons.settings_rounded, '设置', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _nav(IconData icon, String label, int idx) {
    final a = idx == _tabIndex;
    return GestureDetector(
      onTap: () => _switchTab(idx),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22,
              color: a ? AppTheme.primary : AppTheme.textTertiary),
            const SizedBox(height: 2),
            Text(label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: a ? FontWeight.w600 : FontWeight.w400,
                color: a ? AppTheme.primary : AppTheme.textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════
// Tab 1: 记账主页 (3:3)
// ══════════════════════════════════

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionNotifierProvider);
    final catState = ref.watch(categoryNotifierProvider);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('智慧记账',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary),
                  ),
                  Text(_today(),
                    style: const TextStyle(fontSize: 12,
                      color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                OverviewCard(
                  expense: txState.monthlyExpense,
                  income: txState.monthlyIncome,
                  balance: txState.monthlyBalance,
                ),
                const SizedBox(height: 24),
                const Text('最近记录',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 8),
                if (txState.recent(3).isEmpty)
                  _empty()
                else
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: txState.recent(3)
                          .map((t) => RecordItem(transaction: t, categories: catState.categories))
                          .toList(),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _empty() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: const Center(
        child: Column(children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.textTertiary),
          SizedBox(height: 12),
          Text('还没有记录', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          SizedBox(height: 4),
          Text('点击下方 + 开始记账', style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
        ]),
      ),
    );
  }

  String _today() {
    final n = DateTime.now();
    const w = ['周一','周二','周三','周四','周五','周六','周日'];
    return '${n.month}月${n.day}日 ${w[n.weekday - 1]}';
  }
}

// ══════════════════════════════════
// Tab 2: 统计页 (3:4)
// ══════════════════════════════════

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionNotifierProvider);
    final catState = ref.watch(categoryNotifierProvider);

    // 按分类汇总本月支出
    final now = DateTime.now();
    final expenseByCat = <String, double>{};
    for (final t in txState.all) {
      if (t.kind == TransactionKind.expense &&
          t.date.year == now.year &&
          t.date.month == now.month) {
        expenseByCat[t.categoryId] = (expenseByCat[t.categoryId] ?? 0) + t.amount;
      }
    }
    final totalExpense = txState.monthlyExpense;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('统计',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OverviewCard(
                  expense: txState.monthlyExpense,
                  income: txState.monthlyIncome,
                  balance: txState.monthlyBalance,
                ),
                const SizedBox(height: 20),
                // 时间段切换
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                  ),
                  child: Row(
                    children: ['本周', '本月', '本年'].map((t) {
                      final active = t == '本月';
                      return Expanded(
                        child: GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: active
                                ? BoxDecoration(
                                    color: AppTheme.surface,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                                    boxShadow: AppTheme.shadowSm,
                                  )
                                : null,
                            child: Text(t, textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                                color: active ? AppTheme.primary : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),
                // 分类饼图（简化版：彩色条 + 百分比）
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    boxShadow: AppTheme.shadowSm,
                  ),
                  child: Column(
                    children: [
                      const Text('支出分类占比',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimary),
                      ),
                      const SizedBox(height: 16),
                      if (totalExpense > 0)
                        ...expenseByCat.entries.take(5).map((e) {
                          final cat = catState.findById(e.key);
                          final pct = (e.value / totalExpense * 100).round();
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 40,
                                  child: Text(cat?.icon ?? '📌',
                                    style: const TextStyle(fontSize: 18)),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(cat?.name ?? '未知',
                                            style: const TextStyle(fontSize: 14,
                                              color: AppTheme.textPrimary)),
                                          Text('¥${_fmt(e.value)}',
                                            style: const TextStyle(fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                              fontFamily: AppTheme.fontFamilyNumber),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(2),
                                        child: LinearProgressIndicator(
                                          value: e.value / totalExpense,
                                          backgroundColor: AppTheme.surfaceSecondary,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            _catColor(e.key),
                                          ),
                                          minHeight: 6,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text('$pct%',
                                        style: const TextStyle(fontSize: 11,
                                          color: AppTheme.textTertiary),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        })
                      else
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text('暂无支出数据',
                            style: TextStyle(color: AppTheme.textTertiary)),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(double v) => v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(2);

  Color _catColor(String id) {
    const colors = [
      AppTheme.primary, AppTheme.income, AppTheme.expense,
      AppTheme.warning, Color(0xFF8B5CF6), Color(0xFFEC4899),
    ];
    return colors[id.hashCode.abs() % colors.length];
  }
}

// ══════════════════════════════════
// Tab 3: 记录列表 (3:5)
// ══════════════════════════════════

class RecordsTab extends ConsumerWidget {
  const RecordsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txState = ref.watch(transactionNotifierProvider);
    final grouped = txState.groupedByMonth;
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('记录',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
            ),
          ),
        ),
        Expanded(
          child: sortedKeys.isEmpty
              ? const Center(
                  child: Text('暂无记录', style: TextStyle(color: AppTheme.textTertiary)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: sortedKeys.length,
                  itemBuilder: (context, idx) {
                    final key = sortedKeys[idx];
                    final items = grouped[key]!;
                    final monthExpense = items
                        .where((t) => t.kind == TransactionKind.expense)
                        .fold(0.0, (s, t) => s + t.amount);
                    final monthIncome = items
                        .where((t) => t.kind == TransactionKind.income)
                        .fold(0.0, (s, t) => s + t.amount);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 月份标题 + 汇总条
                        const SizedBox(height: 8),
                        Text(_monthLabel(key),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceSecondary,
                            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _sum('支出', '-¥${_fmt(monthExpense)}', AppTheme.expense),
                              _sum('收入', '+¥${_fmt(monthIncome)}', AppTheme.income),
                              _sum('结余', '¥${_fmt(monthIncome - monthExpense)}', AppTheme.primary),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // 记录列表
                        Builder(builder: (context) {
                          final catState = ref.watch(categoryNotifierProvider);
                          return Container(
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                              boxShadow: AppTheme.shadowSm,
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: items
                                  .map((t) => RecordItem(
                                        transaction: t,
                                        categories: catState.categories,
                                      ))
                                  .toList(),
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _sum(String label, String amount, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(amount,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: color,
            fontFamily: AppTheme.fontFamilyNumber),
        ),
        const SizedBox(height: 2),
        Text(label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textTertiary),
        ),
      ],
    );
  }

  String _monthLabel(String key) {
    final parts = key.split('-');
    return '${parts[0]}年${int.parse(parts[1])}月';
  }

  String _fmt(double v) => v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ══════════════════════════════════
// Tab 4: 设置 (3:9)
// ══════════════════════════════════

class SettingsTab extends ConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('设置',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                color: AppTheme.textPrimary),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _section('数据管理', [
                _tile(Icons.file_download_outlined, '导出数据', 'CSV / JSON', () {}),
                _tile(Icons.backup_outlined, '备份与恢复', '本地备份', () {}),
              ]),
              const SizedBox(height: 12),
              _section('记账设置', [
                _tile(Icons.category_outlined, '分类管理', '', () {
                  Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CategoryMgmtPage()),
                  );
                }),
                _tile(Icons.dark_mode_outlined, '深色模式', '', () {}),
              ]),
              const SizedBox(height: 12),
              _section('关于', [
                _tile(Icons.info_outline, '版本', 'v1.0.0', () {}),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.shadowSm,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                color: AppTheme.textTertiary),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppTheme.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(title,
                style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
              ),
            ),
            if (subtitle.isNotEmpty)
              Text(subtitle,
                style: const TextStyle(fontSize: 13, color: AppTheme.textTertiary),
              ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 20, color: AppTheme.textTertiary),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════
// 分类管理页 (3:10)
// ══════════════════════════════════

class CategoryMgmtPage extends ConsumerWidget {
  const CategoryMgmtPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catState = ref.watch(categoryNotifierProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('分类管理'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _catGroup(context, ref, '支出分类', catState.expenseCategories),
          const SizedBox(height: 20),
          _catGroup(context, ref, '收入分类', catState.incomeCategories),
          const SizedBox(height: 16),
          // 新增分类按钮
          OutlinedButton.icon(
            onPressed: () => _showAddDialog(context, ref),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('新增分类'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              side: const BorderSide(color: AppTheme.divider),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _catGroup(BuildContext context, WidgetRef ref, String title, List<Category> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: AppTheme.textTertiary),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.shadowSm,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: categories.map((c) => InkWell(
              onTap: () => _showEditDialog(context, ref, c),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Text(c.icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(c.name,
                        style: const TextStyle(fontSize: 15, color: AppTheme.textPrimary),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.textTertiary),
                      onPressed: () => _confirmAndDelete(context, ref, c),
                    ),
                    ReorderableDragStartListener(
                      index: categories.indexOf(c),
                      child: const Icon(Icons.drag_handle, color: AppTheme.textTertiary),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ),
      ],
    );
  }

  void _confirmAndDelete(BuildContext context, WidgetRef ref, Category c) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('删除「${c.name}」？'),
        content: const Text('如果该分类下已有记账记录，删除将失败。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              final notifier = ref.read(categoryNotifierProvider.notifier);
              final failure = notifier.delete(c.id);
              if (failure != null) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failure.message)),
                );
              } else {
                Navigator.pop(ctx);
              }
            },
            child: const Text('删除', style: TextStyle(color: AppTheme.expense)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    TransactionKind kind = TransactionKind.expense;
    String icon = '📌';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('新增分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(hintText: '分类名称'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<TransactionKind>(
                value: kind,
                items: const [
                  DropdownMenuItem(
                    value: TransactionKind.expense,
                    child: Text('支出分类'),
                  ),
                  DropdownMenuItem(
                    value: TransactionKind.income,
                    child: Text('收入分类'),
                  ),
                ],
                onChanged: (v) => setD(() => kind = v ?? TransactionKind.expense),
                decoration: const InputDecoration(labelText: '类型'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
            ElevatedButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) return;
                final newCat = Category(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: name,
                  icon: icon,
                  kind: kind,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
                final failure =
                    ref.read(categoryNotifierProvider.notifier).add(newCat);
                if (failure != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(failure.message)),
                  );
                }
                Navigator.pop(ctx);
              },
              child: const Text('添加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Category cat) {
    final nameCtrl = TextEditingController(text: cat.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑分类'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: '分类名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              final updated = cat.copyWith(name: name);
              final failure =
                  ref.read(categoryNotifierProvider.notifier).update(updated);
              if (failure != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failure.message)),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════
// 记账流程 Shell (3:6→3:7→3:8)
// ══════════════════════════════════

class AddFlowShell extends ConsumerStatefulWidget {
  const AddFlowShell({super.key});

  @override
  ConsumerState<AddFlowShell> createState() => _AddFlowShellState();
}

class _AddFlowShellState extends ConsumerState<AddFlowShell> {
  int _step = 0;
  String? _categoryId;
  double _amount = 0;
  String _note = '';
  TransactionKind _kind = TransactionKind.expense;

  void _next() => setState(() => _step++);
  void _prev() {
    if (_step == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _step--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async { _prev(); return false; },
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: SafeArea(
          child: IndexedStack(
            index: _step,
            children: [
              _StepCategory(
                kind: _kind,
                onSelect: (id) { _categoryId = id; _next(); },
                onBack: _prev,
              ),
              _StepAmount(
                categoryId: _categoryId ?? '',
                kind: _kind,
                onChangeKind: (k) => setState(() => _kind = k),
                onConfirm: (amount) { _amount = amount; _next(); },
                onBack: _prev,
              ),
              _StepNote(
                amount: _amount,
                categoryId: _categoryId ?? '',
                kind: _kind,
                note: _note,
                onNoteChanged: (v) => _note = v,
                onDone: () {
                  final tx = Transaction(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    amount: _amount,
                    kind: _kind,
                    categoryId: _categoryId!,
                    date: DateTime.now(),
                    note: _note,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  );
                  final failure =
                      ref.read(transactionNotifierProvider.notifier).add(tx);
                  if (failure != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(failure.message)),
                    );
                  }
                  Navigator.pop(context);
                },
                onBack: _prev,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Step 1: 选分类 (3:6)
class _StepCategory extends ConsumerWidget {
  final TransactionKind kind;
  final void Function(String) onSelect;
  final VoidCallback onBack;

  const _StepCategory({
    required this.kind,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catState = ref.watch(categoryNotifierProvider);
    final categories = kind == TransactionKind.expense
        ? catState.expenseCategories
        : catState.incomeCategories;

    return Column(
      children: [
        _topBar('选择分类', onBack: onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: CategoryGrid(
              categories: categories,
              onSelect: (c) => onSelect(c.id),
              onAddNew: () => _showAddDialog(context, ref),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('新增分类'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: '分类名称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              final newCat = Category(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: name,
                icon: '📌',
                kind: kind,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              final failure =
                  ref.read(categoryNotifierProvider.notifier).add(newCat);
              if (failure != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(failure.message)),
                );
              }
              Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }
}

// Step 2: 输金额 (3:7)
class _StepAmount extends ConsumerStatefulWidget {
  final String categoryId;
  final TransactionKind kind;
  final ValueChanged<TransactionKind> onChangeKind;
  final void Function(double) onConfirm;
  final VoidCallback onBack;

  const _StepAmount({
    required this.categoryId,
    required this.kind,
    required this.onChangeKind,
    required this.onConfirm,
    required this.onBack,
  });

  @override
  ConsumerState<_StepAmount> createState() => _StepAmountState();
}

class _StepAmountState extends ConsumerState<_StepAmount> {
  String _display = '0';

  void _onKey(String key) {
    setState(() {
      if (key == '.') {
        if (!_display.contains('.')) _display += '.';
      } else {
        if (_display == '0') {
          _display = key;
        } else {
          _display += key;
        }
      }
    });
  }

  void _onDelete() {
    setState(() {
      if (_display.length > 1) {
        _display = _display.substring(0, _display.length - 1);
      } else {
        _display = '0';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final amount = double.tryParse(_display) ?? 0;
    final catState = ref.watch(categoryNotifierProvider);
    final cat = catState.findById(widget.categoryId);

    return Column(
      children: [
        _topBar('输入金额', onBack: widget.onBack),
        // 头部渐变区
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppTheme.primaryGradientStart, AppTheme.primaryGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            children: [
              // 收入/支出切换
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _kindToggle('支出', TransactionKind.expense),
                    _kindToggle('收入', TransactionKind.income),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // 分类
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(cat?.icon ?? '📌', style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(cat?.name ?? '',
                    style: const TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 金额显示
              Text('¥$_display',
                style: const TextStyle(
                  fontSize: 48, fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontFamily: AppTheme.fontFamilyNumber,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ),
        // 数字键盘
        Expanded(
          child: Container(
            color: AppTheme.surface,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: NumberPad(
              onKeyTap: _onKey,
              onDelete: _onDelete,
              onConfirm: () {
                if (amount > 0) widget.onConfirm(amount);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _kindToggle(String label, TransactionKind k) {
    final active = widget.kind == k;
    return GestureDetector(
      onTap: () => widget.onChangeKind(k),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: active
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              )
            : null,
        child: Text(label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? AppTheme.primary : Colors.white70,
          ),
        ),
      ),
    );
  }
}

// Step 3: 备注 (3:8)
class _StepNote extends StatelessWidget {
  final double amount;
  final String categoryId;
  final TransactionKind kind;
  final String note;
  final ValueChanged<String> onNoteChanged;
  final VoidCallback onDone;
  final VoidCallback onBack;

  const _StepNote({
    required this.amount,
    required this.categoryId,
    required this.kind,
    required this.note,
    required this.onNoteChanged,
    required this.onDone,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _topBar('添加备注', onBack: onBack),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 金额回顾
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceSecondary,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                  child: Text('¥${_fmt(amount)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                      fontFamily: AppTheme.fontFamilyNumber,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // 输入框
                TextField(
                  maxLines: 3,
                  maxLength: 200,
                  decoration: const InputDecoration(
                    hintText: '添加备注（选填）',
                  ),
                  onChanged: onNoteChanged,
                ),
                const SizedBox(height: 16),
                // 快捷标签
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ['午餐', '晚餐', '打车', '购物', '日用'].map((t) {
                    return GestureDetector(
                      onTap: () => onNoteChanged(t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceSecondary,
                          borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                        ),
                        child: Text(t,
                          style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 40),
                // 确认按钮
                ElevatedButton(
                  onPressed: onDone,
                  child: const Text('确认记账'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _fmt(double v) => v == v.toInt() ? v.toInt().toString() : v.toStringAsFixed(2);
}

// ══════════════════════════════════
// 通用组件
// ══════════════════════════════════

Widget _topBar(String title, {VoidCallback? onBack}) {
  return Container(
    height: 56,
    padding: const EdgeInsets.symmetric(horizontal: 4),
    decoration: const BoxDecoration(
      color: AppTheme.surface,
      border: Border(bottom: BorderSide(color: AppTheme.divider, width: 0.5)),
    ),
    child: Row(
      children: [
        if (onBack != null)
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: onBack,
          ),
        if (onBack != null) const SizedBox(width: 8),
        Text(title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.close, size: 20, color: AppTheme.textSecondary),
          onPressed: onBack ?? () {},
        ),
      ],
    ),
  );
}
