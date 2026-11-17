import 'package:ecosystemku/core/db/clock.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock implements Clock {
  _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

void main() {
  test('dateString pads month and day', () {
    expect(dateString(DateTime(2026, 1, 5)), '2026-01-05');
  });

  test('todayString uses local clock date', () {
    final clock = _FixedClock(DateTime(2026, 11, 17, 23, 59));
    expect(todayString(clock), '2026-11-17');
  });
}
