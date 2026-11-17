import '../database.dart';

class LinkkuDao {
  LinkkuDao(this.db);

  final AppDatabase db;

  Future<List<SavedLink>> links() => db.select(db.savedLinks).get();

  Future<List<LinkCategory>> categories() => db.select(db.linkCategories).get();

  Future<List<LinkTag>> tags() => db.select(db.linkTags).get();

  Future<LinkSecurityData?> security() =>
      (db.select(db.linkSecurity)..where((t) => t.id.equals(1)))
          .getSingleOrNull();

  Future<void> deleteLink(String id) =>
      (db.delete(db.savedLinks)..where((t) => t.id.equals(id))).go();

  Future<void> clearAll() async {
    await db.delete(db.savedLinks).go();
    await db.delete(db.linkCategories).go();
    await db.delete(db.linkTags).go();
    await db.delete(db.linkSecurity).go();
  }
}
