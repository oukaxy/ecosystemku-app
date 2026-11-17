import 'dart:async';
import 'dart:typed_data';

import 'package:ecosystemku/core/ai/ai_client.dart';
import 'package:ecosystemku/features/assistant/application/assistant_controller.dart';
import 'package:ecosystemku/features/assistant/application/live2d_bridge.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAi implements AiClient {
  _FakeAi(this.chunks);

  final List<String> chunks;
  int ttsCalls = 0;

  @override
  Stream<String> chatStream({
    required List<ChatTurn> messages,
    Map<String, dynamic>? context,
  }) async* {
    for (final chunk in chunks) {
      await Future<void>.delayed(const Duration(milliseconds: 1));
      yield chunk;
    }
  }

  @override
  Future<String> complete({
    required List<ChatTurn> messages,
    Map<String, dynamic>? context,
  }) async =>
      chunks.join();

  @override
  Future<Uint8List> tts(
    String text, {
    String? voiceId,
    bool translated = false,
  }) async {
    ttsCalls++;
    return Uint8List.fromList([1, 2, 3]);
  }

  @override
  void close() {}
}

class _FakeBridge implements Live2DBridge {
  final expressions = <String>[];
  bool? paused;
  bool speaking = false;
  final playedAudio = <String>[];

  @override
  Future<void> init({bool muted = false}) async {}

  @override
  Future<void> setExpression(String name) async {
    expressions.add(name);
  }

  @override
  Future<void> setSpeaking(bool value) async {
    speaking = value;
  }

  @override
  Future<void> playAudio(String base64, String mime) async {
    playedAudio.add(base64);
  }

  @override
  Future<void> stopAudio() async {}

  @override
  Future<void> setMuted(bool value) async {}

  @override
  Future<void> setPaused(bool value) async {
    paused = value;
  }

  @override
  Future<void> tapZone(String zone) async {}
}

AssistantController _controller(AiClient ai, _FakeBridge bridge) =>
    AssistantController(ai, () => bridge);

void main() {
  test('send streams text, strips tags, and drives expressions', () async {
    final ai = _FakeAi([
      'Halo Tuan! ',
      'Rem siap membantu [EXP',
      'R:happy]',
    ]);
    final bridge = _FakeBridge();
    final controller = _controller(ai, bridge);

    await controller.send('Hai');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final last = controller.state.messages.last;
    expect(last.isUser, isFalse);
    expect(last.text, 'Halo Tuan! Rem siap membantu');
    expect(controller.state.isStreaming, isFalse);
    expect(controller.state.error, isNull);
    expect(bridge.expressions, contains('happy'));
  });

  test('stop cancels streaming and keeps partial text', () async {
    final controller = StreamController<String>();
    final ai = _StreamingAi(controller.stream);
    final bridge = _FakeBridge();
    final assistant = _controller(ai, bridge);

    await assistant.send('Hai');
    controller.add('Sedang mengetik…');
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(assistant.state.isStreaming, isTrue);

    assistant.stop();
    await Future<void>.delayed(const Duration(milliseconds: 10));
    expect(assistant.state.isStreaming, isFalse);
    expect(
      assistant.state.messages.last.text,
      'Sedang mengetik…',
    );
    expect(bridge.speaking, isFalse);
    await controller.close();
  });

  test('error surfaces as friendly message', () async {
    final ai = _ErrorAi();
    final assistant = _controller(ai, _FakeBridge());

    await assistant.send('Hai');
    await Future<void>.delayed(const Duration(milliseconds: 10));

    expect(assistant.state.isStreaming, isFalse);
    expect(assistant.state.error, isNotNull);
    expect(assistant.state.messages.last.text, assistant.state.error);
  });

  test('empty input is ignored', () async {
    final ai = _FakeAi(['x']);
    final assistant = _controller(ai, _FakeBridge());
    await assistant.send('   ');
    expect(assistant.state.messages, isEmpty);
  });

  test('speak plays chunked tts audio through the bridge', () async {
    final ai = _FakeAi(['Kalimat satu. Kalimat dua.']);
    final bridge = _FakeBridge();
    final assistant = _controller(ai, bridge);

    await assistant.send('Hai');
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(ai.ttsCalls, greaterThanOrEqualTo(1));
    expect(bridge.playedAudio, isNotEmpty);
    expect(bridge.speaking, isFalse);
  });
}

class _StreamingAi implements AiClient {
  _StreamingAi(this.stream);

  final Stream<String> stream;

  @override
  Stream<String> chatStream({
    required List<ChatTurn> messages,
    Map<String, dynamic>? context,
  }) =>
      stream;

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

class _ErrorAi implements AiClient {
  @override
  Stream<String> chatStream({
    required List<ChatTurn> messages,
    Map<String, dynamic>? context,
  }) async* {
    throw AiException('Server bermasalah, coba lagi nanti.');
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
