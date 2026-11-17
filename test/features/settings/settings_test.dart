import 'package:drift/native.dart';
import 'package:ecosystemku/app.dart';
import 'package:ecosystemku/core/db/clock.dart';
import 'package:ecosystemku/core/db/database.dart';
import 'package:ecosystemku/core/db/daos/meta_dao.dart';
import 'package:ecosystemku/core/providers.dart';
import 'package:ecosystemku/core/security/secure_store.dart';
import 'package:ecosystemku/features/assistant/application/assistant_engine.dart';
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
  late InMemorySecureStore secureStore;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    secureStore = InMemorySecureStore();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          secureStoreProvider.overrideWithValue(secureStore),
          clockProvider.overrideWithValue(_FixedClock(DateTime(2026, 11, 17, 20))),
          assistantEngineProvider.overrideWithValue(_FakeEngine()),
        ],
        child: const EcosystemApp(),
      ),
    );
    await tester.tap(find.text('Setelan'));
    await tester.pumpAndSettle();
  }

  testWidgets('renders every settings section', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Profil'), findsOneWidget);
    expect(find.text('Kunci AI'), findsOneWidget);
    expect(find.text('Backup'), findsOneWidget);
    expect(find.text('Tampilan'), findsOneWidget);
    expect(find.text('Notifikasi'), findsOneWidget);
    expect(find.text('Data'), findsOneWidget);
    expect(find.text('Tentang'), findsOneWidget);
  });

  testWidgets('shows masked keys from secure storage', (tester) async {
    await secureStore.write('api.groq', 'gsk_super_secret_9876');
    await pumpSettings(tester);

    expect(find.text('••••9876'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Text &&
            widget.data != null &&
            widget.data!.contains('gsk_super_secret'),
      ),
      findsNothing,
    );
  });

  testWidgets('saving profile name persists and refreshes greeting',
      (tester) async {
    await pumpSettings(tester);

    await tester.enterText(find.byType(TextField).first, 'Mahfud');
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    final profile = await MetaDao(db).profile();
    expect(profile?.name, 'Mahfud');
  });

  testWidgets('theme choice persists to app_meta', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Terang'));
    await tester.pumpAndSettle();

    final theme = await MetaDao(db).getString('settings.theme');
    expect(theme, 'light');
  });

  testWidgets('delete-all requires typing the profile name', (tester) async {
    await db.into(db.ideas).insert(
          IdeasCompanion.insert(
            id: 'i1',
            title: 'Sisa data',
            createdAt: 1,
            updatedAt: 1,
          ),
        );
    await pumpSettings(tester);

    await tester.scrollUntilVisible(
      find.text('Hapus semua'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Hapus semua'));
    await tester.pumpAndSettle();

    expect(find.text('Hapus semua data?'), findsOneWidget);

    await tester.enterText(find.byType(TextField).last, 'salah');
    await tester.pumpAndSettle();
    final deleteButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Hapus'),
    );
    expect(deleteButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).last, 'Pengguna');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Hapus'));
    await tester.pumpAndSettle();

    expect(await db.select(db.ideas).get(), isEmpty);
  });

  testWidgets('settings survives text scale 1.3', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpSettings(tester);
    await tester.drag(find.byType(ListView), const Offset(0, -800));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
