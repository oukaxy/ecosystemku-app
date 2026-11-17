class DailyOsSummary {
  const DailyOsSummary({
    required this.habitsDone,
    required this.habitsTotal,
    required this.streak,
    required this.todosDone,
    required this.todosTotal,
  });

  const DailyOsSummary.empty()
      : habitsDone = 0,
        habitsTotal = 0,
        streak = 0,
        todosDone = 0,
        todosTotal = 0;

  final int habitsDone;
  final int habitsTotal;
  final int streak;
  final int todosDone;
  final int todosTotal;
}
