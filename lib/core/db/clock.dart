abstract class Clock {
  DateTime now();
}

class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

String dateString(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-$month-$day';
}

String todayString(Clock clock) => dateString(clock.now());
