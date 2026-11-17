import '../../../core/db/clock.dart';
import '../../../core/db/daos/kronik_dao.dart';
import 'kronik_summary.dart';

class KronikRepository {
  KronikRepository(this.dao);

  final KronikDao dao;

  Future<KronikSummary> summary(DateTime day) async {
    final entries = (await dao.entries())
        .where((entry) => !entry.isArchived)
        .toList();
    if (entries.isEmpty) return const KronikSummary.empty();

    final today = dateString(day);
    final todays = entries.where((entry) => entry.date == today).toList();
    final pool = todays.isNotEmpty ? todays : entries;
    final latest = pool.reduce(
      (a, b) => a.updatedAt >= b.updatedAt ? a : b,
    );

    return KronikSummary(date: latest.date, title: latest.title);
  }
}
