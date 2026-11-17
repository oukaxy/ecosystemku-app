import 'package:drift/drift.dart';

import '../database.dart';

class DailyOsDao {
  DailyOsDao(this.db);

  final AppDatabase db;

  Future<List<Habit>> habits() => db.select(db.habits).get();

  Future<List<HabitSubtask>> subtasks() => db.select(db.habitSubtasks).get();

  Future<List<HabitCheck>> checksForDate(String date) =>
      (db.select(db.habitChecks)..where((t) => t.date.equals(date))).get();

  Future<List<HabitCheck>> allChecks() => db.select(db.habitChecks).get();

  Future<List<Todo>> todos() => db.select(db.todos).get();

  Future<List<TodoSubtask>> todoSubtasks() =>
      db.select(db.todoSubtasks).get();

  Future<void> upsertHabit(HabitsCompanion habit) =>
      db.into(db.habits).insertOnConflictUpdate(habit);

  Future<void> upsertTodo(TodosCompanion todo) =>
      db.into(db.todos).insertOnConflictUpdate(todo);

  Future<void> deleteHabit(String id) async {
    await (db.delete(db.habitChecks)..where((t) => t.habitId.equals(id))).go();
    await (db.delete(db.habitSubtasks)..where((t) => t.habitId.equals(id))).go();
    await (db.delete(db.habits)..where((t) => t.id.equals(id))).go();
  }

  Future<void> deleteTodo(String id) async {
    await (db.delete(db.todoSubtasks)..where((t) => t.todoId.equals(id))).go();
    await (db.delete(db.todos)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearAll() async {
    await db.delete(db.habitChecks).go();
    await db.delete(db.habitSubtasks).go();
    await db.delete(db.habits).go();
    await db.delete(db.todoSubtasks).go();
    await db.delete(db.todos).go();
  }
}
