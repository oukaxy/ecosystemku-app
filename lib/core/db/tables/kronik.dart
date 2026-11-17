import 'package:drift/drift.dart';

class JournalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get date => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();
  TextColumn get moodStatus => text().nullable()();
  TextColumn get moodSvgKey => text().nullable()();
  TextColumn get source => text().withDefault(const Constant(''))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get archivedAt => integer().nullable()();
  IntColumn get generatedAt => integer().nullable()();
  IntColumn get completedAt => integer().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class JournalHabitLogs extends Table {
  TextColumn get entryId => text()();
  TextColumn get habitName => text()();
  TextColumn get category => text().withDefault(const Constant(''))();
  IntColumn get completedAt => integer()();

  @override
  Set<Column> get primaryKey => {entryId, habitName, completedAt};
}
