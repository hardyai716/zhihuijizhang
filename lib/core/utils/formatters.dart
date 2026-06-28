/// 通用工具：日期、金额格式化

import 'package:intl/intl.dart';

class Formatters {
  Formatters._();

  // ══════════════════════════════════
  // 金额
  // ══════════════════════════════════

  /// 格式化为展示金额：整数显示无小数，否则保留2位
  /// 例: 100.0 → "100"; 100.5 → "100.50"
  static String amount(double v) {
    if (v == v.truncateToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(2);
  }

  /// 带千分位 + 2位小数（用于大额展示）
  static String amountWithThousands(double v) {
    final f = NumberFormat('#,##0.00');
    return f.format(v);
  }

  /// 金额显示文本（含 ¥ 符号）
  static String amountWithSymbol(double v) => '¥${amount(v)}';

  // ══════════════════════════════════
  // 日期
  // ══════════════════════════════════

  /// "2026-06-28" 格式
  static String date(DateTime d) =>
      DateFormat('yyyy-MM-dd').format(d);

  /// "2026-06-28 14:30" 格式
  static String dateTime(DateTime d) =>
      DateFormat('yyyy-MM-dd HH:mm').format(d);

  /// "6月28日 周日" 格式（首页副标题）
  static String dateFriendly(DateTime d) {
    final weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];
    // weekday: 1=Mon, 7=Sun
    final wd = weekdays[(d.weekday - 1) % 7];
    return '${d.month}月${d.day}日 $wd';
  }

  /// "2026年6月" 格式
  static String month(DateTime d) => DateFormat('yyyy年M月').format(d);

  /// "06月28日" 格式
  static String monthDay(DateTime d) =>
      DateFormat('MM月dd日').format(d);

  /// 月份分组 key: "2026-06"
  static String monthKey(DateTime d) =>
      DateFormat('yyyy-MM').format(d);

  /// 友好时间（"刚刚"/"X分钟前"/"今天 HH:mm"/"昨天 HH:mm"/"MM-dd"）
  static String timeAgo(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);

    if (diff.inSeconds < 60) return '刚刚';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分钟前';
    if (_isSameDay(d, now)) return '今天 ${DateFormat('HH:mm').format(d)}';
    if (_isSameDay(d, now.subtract(const Duration(days: 1)))) {
      return '昨天 ${DateFormat('HH:mm').format(d)}';
    }
    if (diff.inDays < 7) {
      return DateFormat('EEEE HH:mm', 'zh_CN').format(d);
    }
    return DateFormat('MM-dd').format(d);
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ══════════════════════════════════
  // 周期
  // ══════════════════════════════════

  /// 周一为一周开始（中国习惯）
  static DateTime startOfWeek(DateTime d) {
    final wd = d.weekday; // 1=Mon, 7=Sun
    final monday = d.subtract(Duration(days: wd - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  static DateTime endOfWeek(DateTime d) {
    final start = startOfWeek(d);
    return DateTime(start.year, start.month, start.day + 6, 23, 59, 59);
  }

  static DateTime startOfMonth(DateTime d) =>
      DateTime(d.year, d.month, 1);

  static DateTime endOfMonth(DateTime d) =>
      DateTime(d.year, d.month + 1, 0, 23, 59, 59);

  static DateTime startOfYear(DateTime d) =>
      DateTime(d.year, 1, 1);

  static DateTime endOfYear(DateTime d) =>
      DateTime(d.year, 12, 31, 23, 59, 59);
}

/// 日期范围 —— 用于统计查询
class DateRange {
  final DateTime start;
  final DateTime end;

  const DateRange({required this.start, required this.end});

  bool contains(DateTime d) =>
      !d.isBefore(start) && !d.isAfter(end);

  /// 与另一区间是否重叠
  bool overlaps(DateRange other) =>
      !start.isAfter(other.end) && !end.isBefore(other.start);

  /// 本月
  factory DateRange.thisMonth([DateTime? base]) {
    final b = base ?? DateTime.now();
    return DateRange(
      start: Formatters.startOfMonth(b),
      end: Formatters.endOfMonth(b),
    );
  }

  /// 本周
  factory DateRange.thisWeek([DateTime? base]) {
    final b = base ?? DateTime.now();
    return DateRange(
      start: Formatters.startOfWeek(b),
      end: Formatters.endOfWeek(b),
    );
  }

  /// 今年
  factory DateRange.thisYear([DateTime? base]) {
    final b = base ?? DateTime.now();
    return DateRange(
      start: Formatters.startOfYear(b),
      end: Formatters.endOfYear(b),
    );
  }

  /// 自定义
  factory DateRange.between(DateTime start, DateTime end) {
    return DateRange(
      start: DateTime(start.year, start.month, start.day),
      end: DateTime(end.year, end.month, end.day, 23, 59, 59),
    );
  }
}
