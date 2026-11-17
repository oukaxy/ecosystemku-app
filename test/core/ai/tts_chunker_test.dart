import 'package:ecosystemku/core/ai/tts_chunker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('empty text has no chunks', () {
    expect(chunkForTts('   '), isEmpty);
  });

  test('short text becomes a single chunk', () {
    expect(chunkForTts('Halo Tuan.'), ['Halo Tuan.']);
  });

  test('splits per sentence', () {
    final chunks = chunkForTts('Kalimat pertama. Kalimat kedua! Kalimat ketiga?');
    expect(chunks, [
      'Kalimat pertama. Kalimat kedua! Kalimat ketiga?',
    ]);
  });

  test('never exceeds the character limit per chunk', () {
    final long = 'a' * 300;
    final text = '$long. ${'b' * 300}. ${'c' * 300}.';
    final chunks = chunkForTts(text, maxChars: 500);
    for (final chunk in chunks) {
      expect(chunk.length, lessThanOrEqualTo(500));
    }
    expect(chunks.length, 3);
  });

  test('hard-splits a single sentence longer than the limit', () {
    final chunks = chunkForTts('x' * 1200, maxChars: 500);
    expect(chunks.length, 3);
    expect(chunks.every((c) => c.length <= 500), isTrue);
  });

  test('returns at most four chunks', () {
    final text = List.generate(10, (i) => 'Kalimat nomor ${i + 1}.').join(' ');
    final chunks = chunkForTts(text);
    expect(chunks.length, 4);
  });
}
