import 'dart:convert';

class SseEvent {
  const SseEvent({required this.name, required this.data});

  final String name;
  final Map<String, dynamic> data;
}

/// Incremental parser for `text/event-stream` payloads.
///
/// `add` may be called with partial lines; the parser keeps the dangling
/// fragment until a complete line arrives. An empty line dispatches the
/// buffered event.
class SseParser {
  final StringBuffer _buffer = StringBuffer();
  String _eventName = '';
  final List<String> _dataLines = <String>[];

  List<SseEvent> add(String chunk) {
    _buffer.write(chunk);
    final events = <SseEvent>[];
    var text = _buffer.toString();

    while (true) {
      final lineEnd = text.indexOf('\n');
      if (lineEnd < 0) break;
      final line = _normalize(text.substring(0, lineEnd));
      text = text.substring(lineEnd + 1);
      final event = _consumeLine(line);
      if (event != null) events.add(event);
    }

    _buffer
      ..clear()
      ..write(text);
    return events;
  }

  /// Flushes any fully-terminated event still pending in the buffer
  /// (some servers never send a trailing blank line).
  List<SseEvent> flush() {
    final event = _consumeLine(_normalize(_buffer.toString()));
    _buffer.clear();
    return event == null ? const [] : [event];
  }

  String _normalize(String line) =>
      line.endsWith('\r') ? line.substring(0, line.length - 1) : line;

  SseEvent? _consumeLine(String line) {
    if (line.isEmpty) {
      if (_dataLines.isEmpty) {
        _eventName = '';
        return null;
      }
      final data = _decodeData(_dataLines.join('\n'));
      final name = _eventName;
      _eventName = '';
      _dataLines.clear();
      return SseEvent(name: name, data: data);
    }
    if (line.startsWith(':')) return null;

    if (line.startsWith('data:')) {
      _dataLines.add(line.substring(5).trim());
    } else if (line.startsWith('event:')) {
      _eventName = line.substring(6).trim();
    }
    return null;
  }

  Map<String, dynamic> _decodeData(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
    } on FormatException {
      // Non-JSON payload is returned as a plain data map.
    }
    return {'text': raw};
  }
}
