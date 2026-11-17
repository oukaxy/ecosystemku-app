import 'package:ecosystemku/app.dart';
import 'package:ecosystemku/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:ecosystemku/features/assistant/application/assistant_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EcosystemApp renders without exceptions', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          live2dStageBuilderProvider.overrideWithValue(
            (context) => const SizedBox.shrink(),
          ),
        ],
        child: const EcosystemApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Selamat'), findsOneWidget);
    expect(find.text('Snapshot Hari Ini'.toUpperCase()), findsOneWidget);
  });

  testWidgets('bootstrap layout survives text scale 1.3', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          theme: EcosystemTheme.dark(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Text('EcosystemKu', style: Theme.of(context).textTheme.displayLarge),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
