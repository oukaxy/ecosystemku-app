import 'package:ecosystemku/core/utils/date.dart';
import 'package:ecosystemku/core/utils/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('greeting follows the hour', () {
    expect(greetingForHour(7), 'Selamat Pagi');
    expect(greetingForHour(13), 'Selamat Siang');
    expect(greetingForHour(17), 'Selamat Sore');
    expect(greetingForHour(21), 'Selamat Malam');
    expect(greetingForHour(2), 'Selamat Malam');
  });

  test('date label is Indonesian', () {
    expect(formatDateId(DateTime(2026, 11, 17)), 'Selasa, 17 Nov 2026');
    expect(
      GreetingData(now: DateTime(2026, 11, 17, 20), name: 'Mahfud')
          .headline,
      'Selamat Malam, Mahfud',
    );
  });

  test('rupiah uses dot thousands and no decimals', () {
    expect(formatRupiah(0), 'Rp 0');
    expect(formatRupiah(15000), 'Rp 15.000');
    expect(formatRupiah(3520000), 'Rp 3.520.000');
    expect(formatRupiah(-2500), '-Rp 2.500');
  });

  test('percent clamps empty totals', () {
    expect(formatPercent(0, 0), '0%');
    expect(formatPercent(4, 5), '80%');
  });
}
