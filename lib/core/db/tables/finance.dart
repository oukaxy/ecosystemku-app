import 'package:drift/drift.dart';

class Books extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class BookAccounts extends Table {
  TextColumn get bookId => text()();
  TextColumn get accountId => text()();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {bookId, accountId};
}

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get type => text().withDefault(const Constant('cash'))();
  IntColumn get balance => integer().withDefault(const Constant(0))();
  IntColumn get openingBalance => integer().withDefault(const Constant(0))();
  TextColumn get icon => text().withDefault(const Constant(''))();
  TextColumn get notes => text().withDefault(const Constant(''))();
  BoolColumn get useInBook => boolean().withDefault(const Constant(true))();
  BoolColumn get includeAsset => boolean().withDefault(const Constant(true))();
  BoolColumn get isSavings => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class CategoriesFinance extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text().withDefault(const Constant(''))();
  TextColumn get type => text().withDefault(const Constant('both'))();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class FinanceTransactions extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  TextColumn get title => text()();
  IntColumn get amount => integer().withDefault(const Constant(0))();
  TextColumn get direction => text().withDefault(const Constant('out'))();
  TextColumn get categoryId => text().withDefault(const Constant(''))();
  TextColumn get accountId => text().withDefault(const Constant(''))();
  TextColumn get date => text()();
  TextColumn get memberId => text().withDefault(const Constant(''))();
  IntColumn get createdAt => integer()();
  TextColumn get transferPair => text().nullable()();
  TextColumn get savingsPot => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  String get tableName => 'transactions';
}

class Members extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get emoji => text().withDefault(const Constant(''))();
  IntColumn get sort => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

class MasterBudgets extends Table {
  TextColumn get id => text()();
  TextColumn get bookId => text()();
  IntColumn get month => integer()();
  IntColumn get year => integer()();
  IntColumn get limitAmount => integer().withDefault(const Constant(0))();
  TextColumn get startDate => text().nullable()();
  TextColumn get endDate => text().nullable()();
  TextColumn get note => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class BudgetsLegacy extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get payload => text()();
}

class SavingsPots extends Table {
  TextColumn get wishId => text()();
  IntColumn get saved => integer().withDefault(const Constant(0))();
  TextColumn get snapTitle => text().withDefault(const Constant(''))();
  IntColumn get snapPrice => integer().withDefault(const Constant(0))();
  TextColumn get snapImage => text().nullable()();
  IntColumn get realizedAt => integer().nullable()();
  IntColumn get realizedAmount => integer().nullable()();

  @override
  Set<Column> get primaryKey => {wishId};
}

class SavingsEvents extends Table {
  TextColumn get id => text()();
  TextColumn get wishId => text()();
  TextColumn get type => text()();
  TextColumn get kind => text()();
  IntColumn get amount => integer().withDefault(const Constant(0))();
  TextColumn get date => text()();
  TextColumn get accountId => text().nullable()();
  TextColumn get accountName => text().nullable()();
  IntColumn get ts => integer()();
  TextColumn get trxIds => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
