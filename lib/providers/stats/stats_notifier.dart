/// Stats Notifier —— 统计状态
///
/// 核心设计：
/// - 统计页 Tab 切换时（周/月/年），通过 setPeriod 触发重算
/// - 当前选中的周期 + 类型 缓存在 state
/// - 重算基于 StatsService，结果保存到 state

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/errors/result.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/app_log.dart';
import '../../domain/services/stats_service.dart';
import '../../domain/entities/category.dart';

enum StatsPeriod { week, month, year }

class StatsState {
  final StatsPeriod period;
  final DateTime anchor; // 当前选中的时间锚点
  final TransactionKind filterKind; // 仅支出 / 仅收入 / 全部（用 null）
  final DateRange range;
  final PeriodSummary? summary;
  final List<CategoryAggregate> byCategory;
  final List<DailyAggregate> byDay;
  final List<MonthlyAggregate> byMonth;
  final bool isLoading;
  final String? errorMessage;

  const StatsState({
    this.period = StatsPeriod.month,
    required this.anchor,
    this.filterKind = TransactionKind.expense,
    required this.range,
    this.summary,
    this.byCategory = const [],
    this.byDay = const [],
    this.byMonth = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  StatsState copyWith({
    StatsPeriod? period,
    DateTime? anchor,
    TransactionKind? filterKind,
    DateRange? range,
    PeriodSummary? summary,
    List<CategoryAggregate>? byCategory,
    List<DailyAggregate>? byDay,
    List<MonthlyAggregate>? byMonth,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StatsState(
      period: period ?? this.period,
      anchor: anchor ?? this.anchor,
      filterKind: filterKind ?? this.filterKind,
      range: range ?? this.range,
      summary: summary ?? this.summary,
      byCategory: byCategory ?? this.byCategory,
      byDay: byDay ?? this.byDay,
      byMonth: byMonth ?? this.byMonth,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class StatsNotifier extends StateNotifier<StatsState> {
  StatsNotifier(this._service)
      : super(StatsState(
          anchor: DateTime.now(),
          range: DateRange.thisMonth(),
        )) {
    recompute();
  }

  final StatsService _service;

  // ══════════════════════════════════
  // 周期切换
  // ══════════════════════════════════

  void setPeriod(StatsPeriod period) {
    final range = _rangeFor(period, state.anchor);
    state = state.copyWith(period: period, range: range, anchor: DateTime.now());
    recompute();
  }

  /// 上一周期（周/月/年）
  void prevPeriod() {
    DateTime newAnchor;
    switch (state.period) {
      case StatsPeriod.week:
        newAnchor = state.anchor.subtract(const Duration(days: 7));
        break;
      case StatsPeriod.month:
        newAnchor = DateTime(state.anchor.year, state.anchor.month - 1, 1);
        break;
      case StatsPeriod.year:
        newAnchor = DateTime(state.anchor.year - 1, 1, 1);
        break;
    }
    state = state.copyWith(anchor: newAnchor, range: _rangeFor(state.period, newAnchor));
    recompute();
  }

  /// 下一周期
  void nextPeriod() {
    DateTime newAnchor;
    switch (state.period) {
      case StatsPeriod.week:
        newAnchor = state.anchor.add(const Duration(days: 7));
        break;
      case StatsPeriod.month:
        newAnchor = DateTime(state.anchor.year, state.anchor.month + 1, 1);
        break;
      case StatsPeriod.year:
        newAnchor = DateTime(state.anchor.year + 1, 1, 1);
        break;
    }
    // 不允许超过当前
    final now = DateTime.now();
    if (newAnchor.isAfter(now)) {
      AppLog.service('已到达最新周期，无法继续');
      return;
    }
    state = state.copyWith(anchor: newAnchor, range: _rangeFor(state.period, newAnchor));
    recompute();
  }

  /// 跳转到指定时间（自定义）
  void goTo(DateTime anchor) {
    state = state.copyWith(anchor: anchor, range: _rangeFor(state.period, anchor));
    recompute();
  }

  /// 跳到今天
  void goToToday() {
    final now = DateTime.now();
    state = state.copyWith(anchor: now, range: _rangeFor(state.period, now));
    recompute();
  }

  // ══════════════════════════════════
  // 类型切换（支出/收入）
  // ══════════════════════════════════

  void setKind(TransactionKind kind) {
    state = state.copyWith(filterKind: kind);
    recompute();
  }

  // ══════════════════════════════════
  // 重算（核心）
  // ══════════════════════════════════

  void recompute() {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summary = _service.summarize(state.range);
      if (summary.isErr) {
        state = state.copyWith(isLoading: false, errorMessage: summary.failureOrNull!.message);
        return;
      }

      final byCategory = _service.aggregateByCategory(
        range: state.range, kind: state.filterKind,
      );
      if (byCategory.isErr) {
        state = state.copyWith(isLoading: false, errorMessage: byCategory.failureOrNull!.message);
        return;
      }

      final byDay = _service.aggregateByDay(state.range);
      final byMonth = _service.aggregateByMonth(state.anchor.year);

      state = state.copyWith(
        summary: summary.valueOrNull,
        byCategory: byCategory.valueOrNull ?? [],
        byDay: byDay.valueOrNull ?? [],
        byMonth: byMonth.valueOrNull ?? [],
        isLoading: false,
      );
    } catch (e, st) {
      AppLog.e('StatsNotifier', '重算失败', e, st);
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  // ══════════════════════════════════
  // 工具
  // ══════════════════════════════════

  DateRange _rangeFor(StatsPeriod period, DateTime anchor) {
    switch (period) {
      case StatsPeriod.week:
        return DateRange.thisWeek(anchor);
      case StatsPeriod.month:
        return DateRange.thisMonth(anchor);
      case StatsPeriod.year:
        return DateRange(
          start: Formatters.startOfYear(anchor),
          end: Formatters.endOfYear(anchor),
        );
    }
  }
}
