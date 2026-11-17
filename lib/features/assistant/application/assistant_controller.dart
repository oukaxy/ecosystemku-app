import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/ai/ai_client.dart';
import '../../../core/ai/assistant_tags.dart';
import '../../../core/ai/tts_chunker.dart';
import 'live2d_bridge.dart';

class ChatEntry {
  const ChatEntry({
    required this.role,
    required this.text,
    this.expression = 'none',
  });

  final String role;
  final String text;
  final String expression;

  bool get isUser => role == 'user';

  ChatEntry copyWith({String? text, String? expression}) => ChatEntry(
        role: role,
        text: text ?? this.text,
        expression: expression ?? this.expression,
      );
}

class AssistantState {
  const AssistantState({
    required this.messages,
    required this.isStreaming,
    this.error,
  });

  const AssistantState.initial()
      : messages = const [],
        isStreaming = false,
        error = null;

  final List<ChatEntry> messages;
  final bool isStreaming;
  final String? error;

  AssistantState copyWith({
    List<ChatEntry>? messages,
    bool? isStreaming,
    String? error,
  }) =>
      AssistantState(
        messages: messages ?? this.messages,
        isStreaming: isStreaming ?? this.isStreaming,
        error: error,
      );
}

class AssistantController extends StateNotifier<AssistantState> {
  AssistantController(
    this._ai,
    this._readBridge, {
    this.systemPrompt,
    this.systemPromptLoader,
  }) : super(const AssistantState.initial());

  static const maxHistory = 10;
  static const maxMessageChars = 4000;

  final AiClient _ai;
  final Live2DBridge? Function() _readBridge;
  final String? systemPrompt;
  final Future<String?> Function()? systemPromptLoader;
  StreamSubscription<String>? _subscription;
  String _currentExpression = 'none';
  String? _loadedPrompt;
  bool _promptLoaded = false;

  Future<String?> _resolveSystemPrompt() async {
    if (systemPrompt != null) return systemPrompt;
    final loader = systemPromptLoader;
    if (loader == null) return null;
    if (!_promptLoaded) {
      try {
        _loadedPrompt = await loader();
      } catch (_) {
        _loadedPrompt = null;
      }
      _promptLoaded = true;
    }
    return _loadedPrompt;
  }

  Future<void> send(String raw) async {
    final content = raw.trim();
    if (content.isEmpty || state.isStreaming) return;

    final clipped = content.length > maxMessageChars
        ? content.substring(0, maxMessageChars)
        : content;
    final entry = ChatEntry(role: 'user', text: clipped);
    const streaming = ChatEntry(role: 'assistant', text: '');
    state = state.copyWith(
      messages: [...state.messages, entry, streaming],
      isStreaming: true,
    );

    final history = [
      for (final message
          in state.messages.where((m) => m.text.isNotEmpty).take(maxHistory))
        ChatTurn(role: message.role, content: message.text),
    ];

    final buffer = StringBuffer();
    final bridgeAtStart = _readBridge();
    final prompt = await _resolveSystemPrompt();
    final subscription = _ai
        .chatStream(
          messages: history,
          context: {
            if (prompt != null) 'systemPrompt': prompt,
            'expression': _currentExpression,
          },
        )
        .listen(
          (delta) {
            buffer.write(delta);
            final parsed = AssistantTags.parse(buffer.toString());
            _updateStreaming(parsed.text, parsed.expression);
            if (parsed.expression != 'none') {
              _currentExpression = parsed.expression;
              bridgeAtStart?.setExpression(parsed.expression);
            }
          },
          onError: (Object error) {
            _finish(error: _friendly(error));
          },
          onDone: () {
            _finish();
            _speak(buffer.toString(), bridgeAtStart);
          },
        );
    _subscription = subscription;
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
    _readBridge()?.setSpeaking(false);
    if (state.isStreaming) {
      state = state.copyWith(isStreaming: false);
    }
  }

  void _finish({String? error}) {
    final settledError = error ?? state.error;
    final messages = [...state.messages];
    for (var i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      if (!message.isUser && message.text.isEmpty) {
        messages[i] = message.copyWith(
          text: error ?? '…',
          expression: 'none',
        );
        break;
      }
    }
    _subscription = null;
    state = AssistantState(
      messages: messages,
      isStreaming: false,
      error: settledError,
    );
  }

  void _updateStreaming(String text, String expression) {
    final messages = [...state.messages];
    for (var i = messages.length - 1; i >= 0; i--) {
      final message = messages[i];
      if (!message.isUser) {
        messages[i] = message.copyWith(text: text, expression: expression);
        break;
      }
    }
    state = state.copyWith(messages: messages);
  }

  Future<void> _speak(String raw, Live2DBridge? bridge) async {
    if (bridge == null) return;
    final parsed = AssistantTags.parse(raw);
    if (parsed.text.isEmpty) return;
    try {
      final chunks = chunkForTts(parsed.text);
      for (final chunk in chunks) {
        final audio = await _ai.tts(chunk);
        if (audio.isEmpty) continue;
        bridge.setSpeaking(true);
        await bridge.playAudio(base64Encode(audio), 'audio/mpeg');
      }
      if (chunks.isNotEmpty) bridge.setSpeaking(false);
    } on AiException {
      // Chat text already rendered; TTS is best-effort.
    }
  }

  String _friendly(Object error) {
    if (error is AiException) return error.message;
    return 'Rem tidak bisa menjawab sekarang. Coba lagi.';
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
