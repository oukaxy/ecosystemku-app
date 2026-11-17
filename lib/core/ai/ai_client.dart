import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'sse_parser.dart';

class AiException implements Exception {
  AiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ChatTurn {
  const ChatTurn({required this.role, required this.content});

  final String role;
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

abstract interface class AiClient {
  Stream<String> chatStream({
    required List<ChatTurn> messages,
    Map<String, dynamic>? context,
  });

  Future<String> complete({
    required List<ChatTurn> messages,
    Map<String, dynamic>? context,
  });

  Future<Uint8List> tts(
    String text, {
    String? voiceId,
    bool translated = false,
  });

  void close();
}

class ServerAiClient implements AiClient {
  ServerAiClient({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        baseUrl = baseUrl ?? _defaultBaseUrl;

  static const _defaultBaseUrl = String.fromEnvironment(
    'ECOSYSTEMKU_API_BASE',
    defaultValue: 'https://ecosystemku.vercel.app',
  );

  final http.Client _client;
  final String baseUrl;

  @override
  Stream<String> chatStream({
    required List<ChatTurn> messages,
    Map<String, dynamic>? context,
  }) async* {
    final request = http.Request('POST', Uri.parse('$baseUrl/api/chat'))
      ..headers['Content-Type'] = 'application/json'
      ..body = jsonEncode({
        'messages': [for (final turn in messages) turn.toJson()],
        if (context != null) 'context': context,
      });

    final http.StreamedResponse response;
    try {
      response = await _client.send(request).timeout(
            const Duration(seconds: 60),
          );
    } on TimeoutException {
      throw AiException('Waktu tunggu habis. Coba lagi.');
    }

    if (response.statusCode != 200) {
      throw AiException(_friendlyStatus(response.statusCode));
    }

    final contentType = response.headers['content-type'] ?? '';
    if (!contentType.contains('text/event-stream')) {
      final body = await response.stream.bytesToString();
      final text = _plainText(body);
      if (text.isEmpty) throw AiException('Respons AI kosong.');
      yield text;
      return;
    }

    final parser = SseParser();
    var yieldedAny = false;
    var doneText = '';
    try {
      await for (final chunk
          in response.stream.transform(utf8.decoder)) {
        for (final event in parser.add(chunk)) {
          if (event.data.containsKey('error')) {
            throw AiException('${event.data['error'] ?? 'Terjadi kesalahan.'}');
          }
          final type = event.name.isNotEmpty
              ? event.name
              : '${event.data['type'] ?? ''}';
          if (type == 'done') {
            doneText = '${event.data['text'] ?? ''}';
            continue;
          }
          final delta = '${event.data['delta'] ?? ''}';
          if (delta.isNotEmpty) {
            yieldedAny = true;
            yield delta;
          }
        }
      }
      for (final event in parser.flush()) {
        if (event.data.containsKey('error')) {
          throw AiException('${event.data['error'] ?? 'Terjadi kesalahan.'}');
        }
        final type = event.name.isNotEmpty
            ? event.name
            : '${event.data['type'] ?? ''}';
        if (type == 'done') {
          doneText = '${event.data['text'] ?? ''}';
          continue;
        }
        final delta = '${event.data['delta'] ?? ''}';
        if (delta.isNotEmpty) {
          yieldedAny = true;
          yield delta;
        }
      }
      if (!yieldedAny && doneText.isNotEmpty) {
        yield doneText;
      }
    } on AiException {
      rethrow;
    } catch (_) {
      throw AiException('Koneksi ke asisten terputus.');
    }
  }

  @override
  Future<String> complete({
    required List<ChatTurn> messages,
    Map<String, dynamic>? context,
  }) async {
    final buffer = StringBuffer();
    await for (final delta in chatStream(messages: messages, context: context)) {
      buffer.write(delta);
    }
    return buffer.toString();
  }

  @override
  Future<Uint8List> tts(
    String text, {
    String? voiceId,
    bool translated = false,
  }) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$baseUrl/api/tts'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'text': text,
              'voiceId': voiceId ?? '',
              'translated': translated,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } on TimeoutException {
      throw AiException('TTS timeout. Chat tetap jalan.');
    }

    if (response.statusCode != 200) {
      throw AiException(_friendlyStatus(response.statusCode));
    }

    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('application/json')) {
      try {
        final json = jsonDecode(response.body);
        final base64Audio = json is Map
            ? (json['audio'] ?? json['data'] ?? json['base64'])
            : null;
        if (base64Audio is String && base64Audio.isNotEmpty) {
          return Uint8List.fromList(base64Decode(base64Audio));
        }
      } on FormatException {
        throw AiException('Format TTS tidak dikenal.');
      }
      throw AiException('Format TTS tidak dikenal.');
    }
    return Uint8List.fromList(response.bodyBytes);
  }

  @override
  void close() => _client.close();

  String _plainText(String body) {
    try {
      final json = jsonDecode(body);
      if (json is Map) {
        final value = json['text'] ?? json['message'] ?? json['content'];
        if (value is String) return value;
      }
    } on FormatException {
      return body.trim();
    }
    return '';
  }

  String _friendlyStatus(int statusCode) {
    if (statusCode == 429) return 'Server sedang sibuk, coba sebentar lagi.';
    if (statusCode >= 500) return 'Server bermasalah, coba lagi nanti.';
    return 'Gagal terhubung ke asisten.';
  }
}
