import '../../../core/db/daos/linkku_dao.dart';
import 'linkku_summary.dart';

class LinkkuRepository {
  LinkkuRepository(this.dao);

  final LinkkuDao dao;

  Future<LinkkuSummary> summary() async {
    final links = await dao.links();
    return LinkkuSummary(
      total: links.length,
      privateCount: links.where((link) => link.isPrivate).length,
    );
  }
}
