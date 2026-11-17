import 'package:drift/native.dart';
import 'package:ecosystemku/app.dart';
import 'package:ecosystemku/core/db/clock.dart';
import 'package:ecosystemku/core/db/database.dart';
import 'package:ecosystemku/core/providers.dart';
import 'package:ecosystemku/core/widgets/app_tile.dart';
import 'package:ecosystemku/features/assistant/application/assistant_engine.dart';
import 'package:ecosystemku/features/assistant/application/assistant_providers.dart';

import 'package:ecosystemku/features/apps_hub/domain/app_catalog.dart' show appCatalog;
import 'package:ecosystemku/features/cucimoney/data/finance_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FixedClock implements Clock {
  _FixedClock(this.value);

  final DateTime value;

  @override
  DateTime now() => value;
}

class _FakeEngine implements AssistantEngine {
  @override
  Future<void> attach() async {}

  @override
  Future<void> setVisible(bool visible) async {}
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  List<Override> overrides({List<Override> extra = const []}) => [
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 11, 17, 20))),
        assistantEngineProvider.overrideWithValue(_FakeEngine()),
        live2dStageBuilderProvider.overrideWithValue(
            (context) => const SizedBox.shrink(),
          ),
        ...extra,
      ];

  testWidgets('hub shows greeting, snapshots, and seven apps', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: overrides(), child: const EcosystemApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selasa, 17 Nov 2026'), findsOneWidget);
    expect(find.text('Selamat Malam, Pengguna'), findsOneWidget);
    expect(find.text('Snapshot Hari Ini'.toUpperCase()), findsOneWidget);
    expect(find.text('0/0 Habit Selesai'), findsOneWidget);
    expect(find.text('Rp 0'), findsOneWidget);
    await tester.dragUntilVisible(
      find.text('Hesych'),
      find.byType(ListView),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppTile), findsNWidgets(appCatalog.length));
  });

  testWidgets('finance card error does not break other cards', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(
          extra: [
            financeSummaryProvider.overrideWith(
              (ref) async => throw StateError('boom'),
            ),
          ],
        ),
        child: const EcosystemApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Gagal memuat'), findsOneWidget);
    expect(find.text('0/0 Habit Selesai'), findsOneWidget);
  });

  testWidgets('app tile opens sub-app and hides bottom navigation',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: overrides(), child: const EcosystemApp()),
    );
    await tester.pumpAndSettle();

    await tester.dragUntilVisible(
      find.widgetWithText(AppTile, 'Daily OS'),
      find.byType(ListView),
      const Offset(0, -250),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(AppTile, 'Daily OS'));
    await tester.pumpAndSettle();

    expect(find.text('Hampir siap'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.tap(find.text('Kembali ke Apps'));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
  });

  testWidgets('pull to refresh re-reads snapshots', (tester) async {
    var calls = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides(
          extra: [
            financeSummaryProvider.overrideWith((ref) {
              ref.watch(refreshTickProvider);
              calls++;
              return const FinanceSummary.empty();
            }),
          ],
        ),
        child: const EcosystemApp(),
      ),
    );
    await tester.pumpAndSettle();
    final before = calls;

    await tester.drag(find.byType(ListView), const Offset(0, 320));
    await tester.pumpAndSettle();

    expect(calls, greaterThan(before));
  });

  testWidgets('hub survives text scale 1.3', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(overrides: overrides(), child: const EcosystemApp()),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
