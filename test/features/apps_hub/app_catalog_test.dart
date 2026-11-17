import 'package:ecosystemku/features/apps_hub/domain/app_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalog has seven unique modules', () {
    expect(appCatalog, hasLength(7));
    expect(appCatalog.map((app) => app.id).toSet(), hasLength(7));
  });

  test('hesych is the only external app', () {
    final external = appCatalog
        .where((app) => app.target.kind == AppTargetKind.external)
        .toList();

    expect(external, hasLength(1));
    expect(external.single.id, 'hesych');
    expect(external.single.target.location, hesychUrl);
  });

  test('assistant points at the shell tab', () {
    final assistant =
        appCatalog.firstWhere((app) => app.id == 'assistant');

    expect(assistant.target.kind, AppTargetKind.tab);
    expect(assistant.target.location, '/assistant');
  });
}
