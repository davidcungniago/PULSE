import 'package:flutter_test/flutter_test.dart';
import 'package:pulse/models/date_time_utils.dart';

void main() {
  final now = DateTime(2026, 10, 29, 12);

  test('relative time covers every bucket', () {
    expect(
        relativeTimeLabel(now.subtract(const Duration(seconds: 20)), now: now),
        'baru saja');
    expect(
        relativeTimeLabel(now.subtract(const Duration(minutes: 5)), now: now),
        '5 menit lalu');
    expect(relativeTimeLabel(now.subtract(const Duration(hours: 3)), now: now),
        '3 jam lalu');
    expect(relativeTimeLabel(now.subtract(const Duration(days: 1)), now: now),
        'kemarin');
    expect(relativeTimeLabel(now.subtract(const Duration(days: 3)), now: now),
        '3 hari lalu');
    expect(relativeTimeLabel(now.subtract(const Duration(days: 10)), now: now),
        '1 minggu lalu');
  });

  test('future timestamps are treated as just now', () {
    expect(relativeTimeLabel(now.add(const Duration(minutes: 2)), now: now),
        'baru saja');
  });
}
