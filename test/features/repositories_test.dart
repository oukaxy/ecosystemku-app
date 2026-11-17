import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:ecosystemku/core/db/daos/daily_os_dao.dart';
import 'package:ecosystemku/core/db/daos/finance_dao.dart';
import 'package:ecosystemku/core/db/daos/ideku_dao.dart';
import 'package:ecosystemku/core/db/daos/kronik_dao.dart';
import 'package:ecosystemku/core/db/daos/linkku_dao.dart';
import 'package:ecosystemku/core/db/database.dart';
import 'package:ecosystemku/features/cucimoney/data/finance_repository.dart';
import 'package:ecosystemku/features/daily_os/data/daily_os_repository.dart';
import 'package:ecosystemku/features/ideku/data/ideku_repository.dart';
import 'package:ecosystemku/features/kronik/data/kronik_repository.dart';
import 'package:ecosystemku/features/linkku/data/linkku_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  final day = DateTime(2026, 11, 17);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  test('empty database returns zero summaries', () async {
    final daily = await DailyOsRepository(DailyOsDao(db)).summary(day);
    expect(daily.habitsTotal, 0);
    expect(daily.streak, 0);

    final finance = await FinanceRepository(FinanceDao(db)).summary(day);
    expect(finance.balance, 0);
    expect(finance.expenseToday, 0);
    expect((await IdekuRepository(IdekuDao(db)).summary()).total, 0);
    expect((await KronikRepository(KronikDao(db)).summary(day)).isEmpty, isTrue);
    expect((await LinkkuRepository(LinkkuDao(db)).summary()).total, 0);
  });

  test('finance excludes transfer pairs and other days', () async {
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            id: 'acc-1',
            name: 'Tunai',
            balance: const Value(100000),
          ),
        );
    Future<void> addTrx(
      String id,
      int amount,
      String direction,
      String date, {
      String? pair,
    }) =>
        db.into(db.financeTransactions).insert(
              FinanceTransactionsCompanion.insert(
                id: id,
                bookId: 'book-1',
                title: id,
                amount: Value(amount),
                direction: Value(direction),
                date: date,
                createdAt: 1,
                transferPair: Value(pair),
              ),
            );

    await addTrx('out-1', 10000, 'out', '2026-11-17');
    await addTrx('out-transfer', 5000, 'out', '2026-11-17', pair: 'in-1');
    await addTrx('in-1', 20000, 'in', '2026-11-17');
    await addTrx('out-yesterday', 7000, 'out', '2026-11-16');

    final summary = await FinanceRepository(FinanceDao(db)).summary(day);
    expect(summary.balance, 100000);
    expect(summary.expenseToday, 10000);
    expect(summary.incomeToday, 20000);
  });

  test('habit summary counts active habits and streak across days', () async {
    await db.into(db.habits).insert(
          HabitsCompanion.insert(
            id: 'habit-1',
            name: 'Baca',
            createdAt: 1,
          ),
        );
    await db.into(db.habits).insert(
          HabitsCompanion.insert(
            id: 'habit-archived',
            name: 'Lama',
            createdAt: 1,
            archived: const Value(true),
          ),
        );

    final repo = DailyOsRepository(DailyOsDao(db));
    for (var offset = 0; offset < 3; offset++) {
      final date = day.subtract(Duration(days: offset));
      await db.into(db.habitChecks).insert(
            HabitChecksCompanion.insert(
              habitId: 'habit-1',
              date:
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              subtaskId: 'sub-1',
              completedAt: 1,
            ),
          );
    }

    final summary = await repo.summary(day);
    expect(summary.habitsTotal, 1);
    expect(summary.habitsDone, 1);
    expect(summary.streak, 3);
  });

  test('streak keeps yesterday when today is not done yet', () async {
    await db.into(db.habits).insert(
          HabitsCompanion.insert(id: 'habit-1', name: 'Baca', createdAt: 1),
        );
    for (var offset = 1; offset <= 2; offset++) {
      final date = day.subtract(Duration(days: offset));
      await db.into(db.habitChecks).insert(
            HabitChecksCompanion.insert(
              habitId: 'habit-1',
              date:
                  '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
              subtaskId: 'sub-1',
              completedAt: 1,
            ),
          );
    }

    final summary = await DailyOsRepository(DailyOsDao(db)).summary(day);
    expect(summary.habitsDone, 0);
    expect(summary.streak, 2);
  });

  test('kronik prefers today over a newer other-day entry', () async {
    await db.into(db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            id: 'today',
            date: '2026-11-17',
            title: const Value('Hari ini'),
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await db.into(db.journalEntries).insert(
          JournalEntriesCompanion.insert(
            id: 'older',
            date: '2026-11-10',
            title: const Value('Minggu lalu'),
            createdAt: 1,
            updatedAt: 99,
          ),
        );

    final summary = await KronikRepository(KronikDao(db)).summary(day);
    expect(summary.title, 'Hari ini');
  });

  test('ideku and linkku summaries count correctly', () async {
    await db.into(db.ideas).insert(
          IdeasCompanion.insert(
            id: 'i1',
            title: 'Satu',
            status: const Value('Selesai'),
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await db.into(db.ideas).insert(
          IdeasCompanion.insert(
            id: 'i2',
            title: 'Dua',
            createdAt: 1,
            updatedAt: 2,
          ),
        );

    await db.into(db.savedLinks).insert(
          SavedLinksCompanion.insert(
            id: 'l1',
            url: 'https://a.test',
            ts: 1,
            isPrivate: const Value(true),
          ),
        );
    await db.into(db.savedLinks).insert(
          SavedLinksCompanion.insert(
            id: 'l2',
            url: 'https://b.test',
            ts: 2,
          ),
        );

    final ideas = await IdekuRepository(IdekuDao(db)).summary();
    expect(ideas.total, 2);
    expect(ideas.open, 1);
    expect(ideas.latestTitle, 'Dua');

    final links = await LinkkuRepository(LinkkuDao(db)).summary();
    expect(links.total, 2);
    expect(links.privateCount, 1);
  });
}
