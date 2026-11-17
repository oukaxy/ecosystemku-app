import 'package:ecosystemku/core/security/secure_keys.dart';
import 'package:ecosystemku/core/security/secure_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('masked key shows only last four characters', () async {
    final store = InMemorySecureStore();
    final keys = SecureKeys(store);
    await keys.save(AiProvider.groq, 'gsk_super_secret_9876');

    expect(await keys.masked(AiProvider.groq), '••••9876');
    expect(await keys.has(AiProvider.groq), isTrue);
  });

  test('absent key is null and has is false', () async {
    final keys = SecureKeys(InMemorySecureStore());

    expect(await keys.read(AiProvider.fish), isNull);
    expect(await keys.masked(AiProvider.fish), isNull);
    expect(await keys.has(AiProvider.fish), isFalse);
  });

  test('deleteAll removes every provider key', () async {
    final keys = SecureKeys(InMemorySecureStore());
    await keys.save(AiProvider.sumopod, 'a');
    await keys.save(AiProvider.groq, 'b');

    await keys.deleteAll();

    expect(await keys.read(AiProvider.sumopod), isNull);
    expect(await keys.read(AiProvider.groq), isNull);
  });
}
