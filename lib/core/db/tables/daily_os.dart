import 'package:drift/drift.dart';

class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get color => text().withDefault(const Constant(''))();
  TextColumn get icon => text().withDefault(const Constant(''))();
  TextColumn get activeDays => text().withDefault(const Constant('[]'))();
  BoolColumn get collapsed => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class HabitSubtasks extends Table {
  TextColumn get id => text()();
  TextColumn get habitId => text()();
  TextColumn get text => text()();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class HabitChecks extends Table {
  TextColumn get habitId => text()();
  TextColumn get date => text()();
  TextColumn get subtaskId => text()();
  TextColumn get text => text().withDefault(const Constant(''))();
  IntColumn get completedAt => integer()();

  @override
  Set<Column> get primaryKey => {habitId, date, subtaskId};
}

class Todos extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get priority => text().withDefault(const Constant('normal'))();
  TextColumn get deadline => text().nullable()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get completedAt => integer().nullable()();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class TodoSubtasks extends Table {
  TextColumn get id => text()();
  TextColumn get todoId => text()();
  TextColumn get text => text()();
  BoolColumn get done => boolean().withDefault(const Constant(false))();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
