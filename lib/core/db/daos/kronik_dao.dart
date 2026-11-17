import '../database.dart';

class KronikDao {
  KronikDao(this.db);

  final AppDatabase db;

  Future<List<JournalEntry>> entries() => db.select(db.journalEntries).get();

  Future<void> deleteEntry(String id) async {
    await (db.delete(db.journalHabitLogs)
          ..where((t) => t.entryId.equals(id)))
        .go();
    await (db.delete(db.journalEntries)..where((t) => t.id.equals(id))).go();
  }

  Future<void> clearAll() async {
    await db.delete(db.journalHabitLogs).go();
    await db.delete(db.journalEntries).go();
  }
}
