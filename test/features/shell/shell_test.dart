import 'package:ecosystemku/app.dart';
import 'package:ecosystemku/core/router/app_router.dart';
import 'package:ecosystemku/features/assistant/application/assistant_engine.dart';
import 'package:ecosystemku/features/assistant/application/assistant_providers.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEngine implements AssistantEngine {
  int attachCount = 0;
  bool? visible;

  @override
  Future<void> attach() async {
    attachCount++;
  }

  @override
  Future<void> setVisible(bool visible) async {
    this.visible = visible;
  }
}

void main() {
  testWidgets('shell shows three tabs and pauses assistant when leaving',
      (tester) async {
    final engine = _FakeEngine();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantEngineProvider.overrideWithValue(engine),
          live2dStageBuilderProvider.overrideWithValue(
            (context) => const SizedBox.shrink(),
          ),
        ],
        child: const EcosystemApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Asisten'), findsOneWidget);
    expect(find.text('Apps'), findsOneWidget);
    expect(find.text('Setelan'), findsOneWidget);
    expect(engine.attachCount, 1);
    expect(engine.visible, isFalse);

    await tester.tap(find.text('Asisten'));
    await tester.pumpAndSettle();
    expect(engine.visible, isTrue);

    await tester.tap(find.text('Setelan'));
    await tester.pumpAndSettle();
    expect(engine.visible, isFalse);
    expect(find.text('PROFIL'), findsOneWidget);
  });

  testWidgets('sub-app route hides bottom navigation', (tester) async {
    final container = ProviderContainer(
      overrides: [
        assistantEngineProvider.overrideWithValue(_FakeEngine()),
        live2dStageBuilderProvider.overrideWithValue(
            (context) => const SizedBox.shrink(),
          ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const EcosystemApp(),
      ),
    );
    await tester.pumpAndSettle();

    container.read(routerProvider).go('/app/daily-os');
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Daily OS'), findsOneWidget);
  });

  testWidgets('back shows exit hint before leaving', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantEngineProvider.overrideWithValue(_FakeEngine()),
          live2dStageBuilderProvider.overrideWithValue(
            (context) => const SizedBox.shrink(),
          ),
        ],
        child: const EcosystemApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pump();

    expect(find.text('Tekan lagi untuk keluar'), findsOneWidget);
  });

  testWidgets('shell survives text scale 1.3', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          assistantEngineProvider.overrideWithValue(_FakeEngine()),
          live2dStageBuilderProvider.overrideWithValue(
            (context) => const SizedBox.shrink(),
          ),
        ],
        child: const EcosystemApp(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Setelan'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
