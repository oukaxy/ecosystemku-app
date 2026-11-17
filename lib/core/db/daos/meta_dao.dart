import 'package:drift/drift.dart';

import '../database.dart';

class MetaDao {
  MetaDao(this.db);

  final AppDatabase db;

  Future<String?> getString(String key) async {
    final row = await (db.select(db.appMeta)..where((t) => t.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setString(String key, String value) =>
      db.into(db.appMeta).insertOnConflictUpdate(
            AppMetaCompanion.insert(key: key, value: Value(value)),
          );

  Future<Profile?> profile() =>
      (db.select(db.profiles)..where((t) => t.id.equals(1))).getSingleOrNull();

  Future<void> saveProfile({String? name, String? avatarPath}) =>
      db.into(db.profiles).insertOnConflictUpdate(
            ProfilesCompanion.insert(
              id: 1,
              name: Value(name),
              avatarPath: Value(avatarPath),
            ),
          );

  Future<List<Reminder>> reminders() => db.select(db.reminders).get();

  Future<void> upsertReminder(RemindersCompanion reminder) =>
      db.into(db.reminders).insertOnConflictUpdate(reminder);

  Future<void> clearProfileAndMeta() async {
    await db.delete(db.profiles).go();
    await db.delete(db.reminders).go();
    await db.delete(db.appMeta).go();
  }
}
