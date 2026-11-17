import '../../../core/db/daos/ideku_dao.dart';
import 'ideku_summary.dart';

class IdekuRepository {
  IdekuRepository(this.dao);

  final IdekuDao dao;

  Future<IdekuSummary> summary() async {
    final ideas = await dao.ideas();
    if (ideas.isEmpty) return const IdekuSummary.empty();

    final open = ideas
        .where((idea) => idea.status != 'Selesai' && idea.status != 'Arsip')
        .length;
    final latest = ideas.reduce(
      (a, b) => a.updatedAt >= b.updatedAt ? a : b,
    );

    return IdekuSummary(
      total: ideas.length,
      open: open,
      latestTitle: latest.title,
    );
  }
}
