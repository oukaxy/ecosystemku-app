import 'package:ecosystemku/core/ai/sse_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses complete delta events', () {
    final parser = SseParser();
    final events = parser.add(
      'data: {"type":"delta","delta":"Halo"}\n\n'
      'data: {"type":"delta","delta":" Tuan"}\n\n',
    );

    expect(events, hasLength(2));
    expect(events[0].data['delta'], 'Halo');
    expect(events[1].data['delta'], ' Tuan');
  });

  test('keeps dangling partial lines across chunks', () {
    final parser = SseParser();
    expect(parser.add('data: {"type":"del'), isEmpty);
    final events = parser.add('ta","delta":"a"}\n\n');
    expect(events, hasLength(1));
    expect(events.single.data['delta'], 'a');
  });

  test('named event lines set the event name', () {
    final parser = SseParser();
    final events = parser.add(
      'event: delta\ndata: {"delta":"x"}\n\n',
    );
    expect(events.single.name, 'delta');
    expect(events.single.data['delta'], 'x');
  });

  test('error event carries the message', () {
    final parser = SseParser();
    final events = parser.add('data: {"type":"error","error":"quota"}\n\n');
    expect(events.single.data['error'], 'quota');
  });

  test('flush dispatches a terminated event without trailing blank line',
      () {
    final parser = SseParser();
    expect(parser.add('data: {"type":"done","text":"selesai"}\n'), isEmpty);
    final events = parser.flush();
    expect(events.single.name, isEmpty);
    expect(events.single.data['text'], 'selesai');
  });

  test('non-json payload is passed through as text', () {
    final parser = SseParser();
    final events = parser.add('data: hello world\n\n');
    expect(events.single.data['text'], 'hello world');
  });

  test('comment lines are ignored', () {
    final parser = SseParser();
    final events = parser.add(': keep-alive\ndata: {"delta":"y"}\n\n');
    expect(events, hasLength(1));
  });
}
