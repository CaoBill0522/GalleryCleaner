import 'package:flutter_test/flutter_test.dart';
import 'package:gallery_cleaner/utils/format.dart';

void main() {
  test('formatBytes', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1536), '1.5 KB');
    expect(formatBytes(250 * 1024 * 1024), '250 MB');
    expect(formatBytes(3 * 1024 * 1024 * 1024), '3.0 GB');
  });

  test('formatDuration', () {
    expect(formatDuration(const Duration(seconds: 7)), '00:07');
    expect(formatDuration(const Duration(minutes: 3, seconds: 5)), '03:05');
    expect(
      formatDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
  });
}
