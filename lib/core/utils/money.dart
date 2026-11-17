String formatRupiah(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return '${negative ? '-' : ''}Rp $buffer';
}

String formatPercent(int done, int total) {
  if (total <= 0) return '0%';
  return '${((done / total) * 100).round()}%';
}
