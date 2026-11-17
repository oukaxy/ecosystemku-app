import '../database.dart';

class IdekuDao {
  IdekuDao(this.db);

  final AppDatabase db;

  Future<List<Idea>> ideas() => db.select(db.ideas).get();

  Future<List<IdeaCategory>> categories() => db.select(db.ideaCategories).get();

  Future<void> deleteIdea(String id) =>
      (db.delete(db.ideas)..where((t) => t.id.equals(id))).go();

  Future<void> clearAll() async {
    await db.delete(db.ideaCategories).go();
    await db.delete(db.ideas).go();
  }
}
