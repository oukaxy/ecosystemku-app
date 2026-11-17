import 'package:drift/drift.dart';

class Ideas extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();
  TextColumn get category => text().withDefault(const Constant(''))();
  TextColumn get jalur => text().withDefault(const Constant(''))();
  TextColumn get nextStep => text().withDefault(const Constant(''))();
  TextColumn get priority => text().withDefault(const Constant('Nanti'))();
  TextColumn get status => text().withDefault(const Constant('Belum'))();
  TextColumn get type => text().withDefault(const Constant('Idea'))();
  IntColumn get price => integer().withDefault(const Constant(0))();
  TextColumn get image => text().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class IdeaCategories extends Table {
  TextColumn get name => text()();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {name};
}
