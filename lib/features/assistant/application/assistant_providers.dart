import 'dart:convert';

import 'package:flutter/widgets.dart' show WidgetBuilder;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_client.dart';
import '../presentation/live2d_stage.dart';
import 'assistant_controller.dart';
import 'live2d_bridge.dart';

/// Loads Rem's persona from the synced Live2D character manifest.
Future<Map<String, dynamic>> loadCharacterConfig() async {
  final raw = await rootBundle.loadString('assets/live2d/rem/character.json');
  final decoded = jsonDecode(raw);
  return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
}

/// Character manifest loaded once at startup (see main.dart).
final characterConfigProvider =
    Provider<Map<String, dynamic>>((ref) => const {});

final aiClientProvider = Provider<AiClient>((ref) {
  final client = ServerAiClient();
  ref.onDispose(client.close);
  return client;
});

final assistantControllerProvider = StateNotifierProvider.autoDispose<
    AssistantController, AssistantState>((ref) {
  final prompt = ref.watch(characterConfigProvider)['systemPrompt'];
  return AssistantController(
    ref.watch(aiClientProvider),
    () => ref.read(live2dBridgeProvider),
    systemPrompt: prompt is String && prompt.trim().isNotEmpty ? prompt : null,
  );
});

/// Injectable stage builder so tests can swap the WebView stage out.
final live2dStageBuilderProvider = Provider<WidgetBuilder>(
  (ref) => (context) => const Live2DStage(),
);
