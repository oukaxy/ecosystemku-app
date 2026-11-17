import 'dart:convert';

import '../../../core/db/clock.dart';
import '../../../core/db/daos/daily_os_dao.dart';
import '../../../core/db/database.dart';
import 'daily_os_summary.dart';

class DailyOsRepository {
  DailyOsRepository(this.dao);

  final DailyOsDao dao;

  Future<DailyOsSummary> summary(DateTime day) async {
    final habits = (await dao.habits()).where((h) => !h.archived).toList();
    final checks = await dao.allChecks();
    final todos = await dao.todos();
    final date = dateString(day);

    final active = habits.where((h) => isActive(h, day)).toList();
    final checkedHabitIds = checks
        .where((c) => c.date == date)
        .map((c) => c.habitId)
        .toSet();
    final done = active.where((h) => checkedHabitIds.contains(h.id)).length;

    return DailyOsSummary(
      habitsDone: done,
      habitsTotal: active.length,
      streak: computeStreak(day, habits, checks),
      todosDone: todos.where((t) => t.done).length,
      todosTotal: todos.length,
    );
  }

  static bool isActive(Habit habit, DateTime day) {
    final raw = habit.activeDays.trim();
    if (raw.isEmpty || raw == '[]') return true;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return true;
      final days = decoded.whereType<num>().map((e) => e.toInt()).toSet();
      if (days.isEmpty) return true;
      return days.contains(day.weekday % 7);
    } on FormatException {
      return true;
    }
  }

  static int computeStreak(
    DateTime day,
    List<Habit> habits,
    List<HabitCheck> checks,
  ) {
    final checkedByDate = <String, Set<String>>{};
    for (final check in checks) {
      checkedByDate.putIfAbsent(check.date, () => <String>{}).add(check.habitId);
    }

    var streak = 0;
    var cursor = DateTime(day.year, day.month, day.day);
    for (var i = 0; i < 365; i++) {
      final active = habits.where((h) => isActive(h, cursor)).toList();
      if (active.isNotEmpty) {
        final checked = checkedByDate[dateString(cursor)] ?? const <String>{};
        final complete = active.every((h) => checked.contains(h.id));
        if (complete) {
          streak++;
        } else if (i == 0) {
          // Today is still open; keep the streak earned through yesterday.
        } else {
          break;
        }
      }
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }
}
