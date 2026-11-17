import 'package:drift/drift.dart';

class SavedLinks extends Table {
  TextColumn get id => text()();
  TextColumn get url => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get catId => text().withDefault(const Constant(''))();
  TextColumn get privateCatId => text().nullable()();
  TextColumn get tags => text().withDefault(const Constant('[]'))();
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  TextColumn get thumb => text().nullable()();
  IntColumn get ts => integer()();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'links';
}

class LinkCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  BoolColumn get isPrivate => boolean().withDefault(const Constant(false))();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class LinkTags extends Table {
  TextColumn get name => text()();
  TextColumn get mode => text().withDefault(const Constant('normal'))();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {name, mode};
}

class LinkSecurity extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get pinHash => text()();
  IntColumn get saltVersion => integer().withDefault(const Constant(1))();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'link_security';
}
