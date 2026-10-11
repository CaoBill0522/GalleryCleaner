/// 某年某月，用来按月筛选照片。
class YearMonth implements Comparable<YearMonth> {
  const YearMonth(this.year, this.month);

  factory YearMonth.of(DateTime t) => YearMonth(t.year, t.month);

  final int year;
  final int month;

  /// 本月第一天 0 点（本地时间）。
  DateTime get start => DateTime(year, month);

  /// 本月最后一毫秒。
  DateTime get end =>
      DateTime(year, month + 1).subtract(const Duration(milliseconds: 1));

  String get key => '$year-${month.toString().padLeft(2, '0')}';

  String get label => '$year年$month月';

  YearMonth get previous =>
      month == 1 ? YearMonth(year - 1, 12) : YearMonth(year, month - 1);

  @override
  int compareTo(YearMonth other) => year != other.year
      ? year.compareTo(other.year)
      : month.compareTo(other.month);

  @override
  bool operator ==(Object other) =>
      other is YearMonth && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);
}
