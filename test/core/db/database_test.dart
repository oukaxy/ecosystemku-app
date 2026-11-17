import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:ecosystemku/core/db/daos/daily_os_dao.dart';
import 'package:ecosystemku/core/db/daos/finance_dao.dart';
import 'package:ecosystemku/core/db/daos/ideku_dao.dart';
import 'package:ecosystemku/core/db/daos/kronik_dao.dart';
import 'package:ecosystemku/core/db/daos/linkku_dao.dart';
import 'package:ecosystemku/core/db/daos/meta_dao.dart';
import 'package:ecosystemku/core/db/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('schema version is 1', () async {
    final row = await db.customSelect('PRAGMA user_version').getSingle();
    expect(row.data.values.first, 1);
  });

  test('ideas round-trip', () async {
    await db.into(db.ideas).insert(
          IdeasCompanion.insert(
            id: 'idea-1',
            title: 'Aplikasi kebun',
            createdAt: 1,
            updatedAt: 2,
          ),
        );

    final ideas = await IdekuDao(db).ideas();
    expect(ideas, hasLength(1));
    expect(ideas.single.title, 'Aplikasi kebun');
  });

  test('habit check is scoped to date', () async {
    await db.into(db.habits).insert(
          HabitsCompanion.insert(id: 'habit-1', name: 'Baca', createdAt: 1),
        );
    await db.into(db.habitChecks).insert(
          HabitChecksCompanion.insert(
            habitId: 'habit-1',
            date: '2026-11-17',
            subtaskId: 'sub-1',
            completedAt: 1,
          ),
        );

    final dao = DailyOsDao(db);
    expect(await dao.checksForDate('2026-11-17'), hasLength(1));
    expect(await dao.checksForDate('2026-11-18'), isEmpty);
  });

  test('journal entry round-trip', () async {
    await db.into(db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            id: 'entry-1',
            date: '2026-11-17',
            title: const Value('Pagi'),
            createdAt: 1,
            updatedAt: 2,
          ),
        );

    final entries = await KronikDao(db).entries();
    expect(entries.single.title, 'Pagi');
  });

  test('transaction stores integer rupiah', () async {
    await db.into(db.books).insert(
          BooksCompanion.insert(id: 'book-1', name: 'Utama'),
        );
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(id: 'acc-1', name: 'Tunai'),
        );
    await db
        .into(db.financeTransactions)
        .insert(
          FinanceTransactionsCompanion.insert(
            id: 'trx-1',
            bookId: 'book-1',
            title: 'Makan',
            amount: const Value(15000),
            date: '2026-11-17',
            createdAt: 1,
          ),
        );

    final tx = await FinanceDao(db).transactions();
    expect(tx.single.amount, 15000);
  });

  test('link round-trip', () async {
    await db.into(db.savedLinks).insert(
          SavedLinksCompanion.insert(
            id: 'link-1',
            url: 'https://example.test',
            title: const Value('Contoh'),
            ts: 1,
          ),
        );

    final links = await LinkkuDao(db).links();
    expect(links.single.url, 'https://example.test');
  });

  test('meta string round-trip', () async {
    final dao = MetaDao(db);
    await dao.setString('profile.name', 'Rani');

    expect(await dao.getString('profile.name'), 'Rani');
    expect(await dao.getString('missing'), isNull);
  });
}
