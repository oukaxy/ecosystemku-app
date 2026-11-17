/// Splits text into TTS chunks: sentence-based, each chunk at most
/// [maxChars] characters, at most [maxChunks] chunks played in sequence.
List<String> chunkForTts(
  String text, {
  int maxChars = 500,
  int maxChunks = 4,
}) {
  final clean = text.trim();
  if (clean.isEmpty) return const [];

  final sentences = clean
      .split(RegExp(r'(?<=[.!?…])\s+'))
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  final chunks = <String>[];
  final buffer = StringBuffer();
  for (final sentence in sentences) {
    final pieces = _splitHard(sentence, maxChars);
    for (final piece in pieces) {
      if (buffer.isEmpty) {
        buffer.write(piece);
      } else if (buffer.length + 1 + piece.length <= maxChars) {
        buffer
          ..write(' ')
          ..write(piece);
      } else {
        chunks.add(buffer.toString());
        buffer
          ..clear()
          ..write(piece);
      }
    }
  }
  if (buffer.isNotEmpty) chunks.add(buffer.toString());

  if (chunks.length <= maxChunks) return chunks;
  return chunks.sublist(0, maxChunks);
}

List<String> _splitHard(String sentence, int maxChars) {
  if (sentence.length <= maxChars) return [sentence];
  final pieces = <String>[];
  var start = 0;
  while (start < sentence.length) {
    final end = (start + maxChars).clamp(0, sentence.length);
    pieces.add(sentence.substring(start, end));
    start = end;
  }
  return pieces;
}
