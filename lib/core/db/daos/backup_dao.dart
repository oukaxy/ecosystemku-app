import '../database.dart';

class BackupDao {
  BackupDao(this.db);

  final AppDatabase db;

  Future<Map<String, List<Map<String, Object?>>>> readAll(
    List<String> tables,
  ) async {
    final result = <String, List<Map<String, Object?>>>{};
    for (final table in tables) {
      final rows = await db.customSelect('SELECT * FROM "$table"').get();
      result[table] = rows
          .map((row) => Map<String, Object?>.from(row.data))
          .toList(growable: false);
    }
    return result;
  }

  Future<void> replaceAll(
    Map<String, List<Map<String, Object?>>> tables,
  ) async {
    await db.transaction(() async {
      for (final table in tables.keys.toList().reversed) {
        await db.customStatement('DELETE FROM "$table"');
      }
      for (final entry in tables.entries) {
        for (final row in entry.value) {
          final columns = row.keys.toList(growable: false);
          if (columns.isEmpty) continue;
          final columnList = columns.map((c) => '"$c"').join(', ');
          final placeholders = List.filled(columns.length, '?').join(', ');
          await db.customStatement(
            'INSERT OR REPLACE INTO "${entry.key}" ($columnList) '
            'VALUES ($placeholders)',
            columns.map((c) => row[c]).toList(growable: false),
          );
        }
      }
    });
  }
}
