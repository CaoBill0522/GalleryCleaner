import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_cleaner/models/year_month.dart';

void main() {
  test('月份起止包含整月', () {
    const m = YearMonth(2024, 2);
    expect(m.start, DateTime(2024, 2, 1));
    expect(m.end, DateTime(2024, 2, 29, 23, 59, 59, 999));
    expect(
      const YearMonth(2024, 12).end,
      DateTime(2024, 12, 31, 23, 59, 59, 999),
    );
  });

  test('上个月跨年', () {
    expect(const YearMonth(2024, 1).previous, const YearMonth(2023, 12));
    expect(const YearMonth(2024, 5).previous, const YearMonth(2024, 4));
  });

  test('比较和标签', () {
    expect(
      const YearMonth(2023, 12).compareTo(const YearMonth(2024, 1)) < 0,
      true,
    );
    expect(YearMonth.of(DateTime(2024, 3, 15)), const YearMonth(2024, 3));
    expect(const YearMonth(2024, 3).label, '2024年3月');
  });
}
