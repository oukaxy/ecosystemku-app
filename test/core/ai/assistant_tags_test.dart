import 'package:ecosystemku/core/ai/assistant_tags.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('extracts the last expression tag and strips all tags', () {
    final result = AssistantTags.parse('Halo Tuan [EXPR:happy] [EXPR:smile]');
    expect(result.text, 'Halo Tuan');
    expect(result.expression, 'smile');
  });

  test('unknown expression falls back to none', () {
    final result = AssistantTags.parse('Halo [EXPR:keren]');
    expect(result.expression, 'none');
  });

  test('legacy aliases map to none', () {
    for (final alias in ['navi', 'wait', 'bound']) {
      final result = AssistantTags.parse('Hai [EXPR:$alias]');
      expect(result.expression, 'none');
    }
  });

  test('dangling partial tag is stripped from streaming text', () {
    final result = AssistantTags.parse('Halo Tuan, selamat datang [EXP');
    expect(result.text, 'Halo Tuan, selamat datang');
    expect(result.expression, 'none');
  });

  test('dangling EXPR with name is stripped', () {
    final result = AssistantTags.parse('Siap [EXPR:hap');
    expect(result.text, 'Siap');
  });

  test('open app tag is captured', () {
    final result = AssistantTags.parse('Membuka CuciMoney [OPEN:cucimoney] [EXPR:proud]');
    expect(result.openApp, 'cucimoney');
    expect(result.expression, 'proud');
    expect(result.text, 'Membuka CuciMoney');
  });

  test('plain text is untouched', () {
    final result = AssistantTags.parse('Tidak ada tag di sini.');
    expect(result.text, 'Tidak ada tag di sini.');
    expect(result.expression, 'none');
    expect(result.openApp, isNull);
  });
}
