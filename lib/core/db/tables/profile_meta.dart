import 'package:drift/drift.dart';

class Profiles extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text().nullable()();
  TextColumn get avatarPath => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'profile';
}

class Reminders extends Table {
  TextColumn get id => text()();
  TextColumn get app => text()();
  TextColumn get kind => text()();
  TextColumn get time => text()();
  BoolColumn get enabled => boolean().withDefault(const Constant(true))();
  TextColumn get days => text().withDefault(const Constant('[]'))();
  IntColumn get notificationId => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class AppMeta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().withDefault(const Constant(''))();

  @override
  Set<Column> get primaryKey => {key};
}
