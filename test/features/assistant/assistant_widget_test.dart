import 'dart:async';
import 'dart:typed_data';

import 'package:ecosystemku/core/ai/ai_client.dart';
import 'package:ecosystemku/features/assistant/application/assistant_providers.dart';
import 'package:ecosystemku/features/assistant/presentation/assistant_page.dart';
import 'package:ecosystemku/features/assistant/presentation/chat_panel.dart';
import 'package:ecosystemku/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAi implements AiClient {
  @override
  Stream<String> chatStream({
    required List<ChatTurn> messages,
    Map<String, dynamic>? context,
  }) async* {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    yield 'Halo Tuan, Rem siap membantu ';
    await Future<void>.delayed(const Duration(milliseconds: 5));
    yield '[EXPR:happy]';
  }

  @override
  Future<String> complete({
    required List<ChatTurn> messages,
    Map<String, dynamic>? context,
  }) async =>
      '';

  @override
  Future<Uint8List> tts(
    String text, {
    String? voiceId,
    bool translated = false,
  }) async =>
      Uint8List(0);

  @override
  void close() {}
}

void main() {
  Future<void> pumpPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiClientProvider.overrideWithValue(_FakeAi()),
          live2dStageBuilderProvider.overrideWithValue(
            (context) => const SizedBox.expand(),
          ),
        ],
        child: MaterialApp(
          theme: EcosystemTheme.dark(),
          home: const AssistantPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('sending a message streams the reply into the chat',
      (tester) async {
    await pumpPage(tester);

    expect(find.byType(ChatPanel), findsOneWidget);
    expect(find.text('Tanya apa saja — Rem siap membantu.'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hai Rem');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump();
    expect(find.text('Hai Rem'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Halo Tuan, Rem siap membantu'), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsNothing);
  });

  testWidgets('streaming shows typing dots and a stop button',
      (tester) async {
    await pumpPage(tester);

    await tester.enterText(find.byType(TextField), 'Hai');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pump(const Duration(milliseconds: 2));

    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.text('Halo Tuan, Rem siap membantu'), findsOneWidget);
  });

  testWidgets('chat survives text scale 1.3', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await pumpPage(tester);
    await tester.enterText(find.byType(TextField), 'Hai Rem');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
