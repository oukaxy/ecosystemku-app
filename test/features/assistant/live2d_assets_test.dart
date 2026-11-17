import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

const requiredFiles = [
  'assets/live2d/rem/Character.moc3',
  'assets/live2d/rem/Character.model3.json',
  'assets/live2d/rem/Character.physics3.json',
  'assets/live2d/rem/character.json',
  'assets/live2d/rem/textures/texture_00.png',
  'assets/live2d/index.html',
  'assets/live2d/adapter.js',
  'assets/live2d/vendor/live2dcubismcore.min.js',
  'assets/live2d/vendor/pixi.min.js',
  'assets/live2d/vendor/pixi-live2d-display.min.js',
];

String _sha256Hex(List<int> bytes) => sha256.convert(bytes).toString();

void main() {
  test('required Live2D assets exist', () {
    for (final path in requiredFiles) {
      expect(File(path).existsSync(), isTrue, reason: '$path missing');
    }
  });

  test('model textures and motions exist', () {
    final model = jsonDecode(
      File('assets/live2d/rem/Character.model3.json').readAsStringSync(),
    ) as Map<String, dynamic>;
    final refs = model['FileReferences'] as Map<String, dynamic>;
    for (final texture in refs['Textures'] as List) {
      expect(
        File('assets/live2d/rem/$texture').existsSync(),
        isTrue,
        reason: 'texture $texture missing',
      );
    }
    final motions = refs['Motions'] as Map<String, dynamic>;
    expect(motions.keys, contains('idle'));
    for (final group in motions.values) {
      for (final motion in (group as List)) {
        final file = (motion as Map<String, dynamic>)['File'] as String;
        expect(
          File('assets/live2d/rem/$file').existsSync(),
          isTrue,
          reason: 'motion $file missing',
        );
      }
    }
  });

  test('checksum manifest matches synced files', () {
    final lines = File('assets/live2d/rem/checksums.sha256')
        .readAsLinesSync()
        .where((line) => line.trim().isNotEmpty)
        .toList();
    expect(lines, isNotEmpty);

    for (final line in lines) {
      final parts = line.split(RegExp(r'\s+'));
      expect(parts, hasLength(2), reason: 'bad checksum line: $line');
      final expected = parts[0];
      final relative = parts[1].replaceFirst('./', '');
      final file = File('assets/live2d/rem/$relative');
      expect(file.existsSync(), isTrue, reason: '$relative missing');
      final actual = _sha256Hex(file.readAsBytesSync());
      expect(actual, expected, reason: '$relative checksum mismatch');
    }
  });
}
