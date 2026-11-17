import 'secure_store.dart';

enum AiProvider {
  sumopod,
  groq,
  fish;

  String get storageKey => switch (this) {
        AiProvider.sumopod => 'api.sumopod',
        AiProvider.groq => 'api.groq',
        AiProvider.fish => 'api.fish',
      };
}

class SecureKeys {
  SecureKeys(this.store);

  final SecureStore store;

  Future<void> save(AiProvider provider, String key) =>
      store.write(provider.storageKey, key.trim());

  Future<String?> read(AiProvider provider) async {
    final value = await store.read(provider.storageKey);
    return (value == null || value.trim().isEmpty) ? null : value.trim();
  }

  Future<bool> has(AiProvider provider) async => await read(provider) != null;

  Future<String?> masked(AiProvider provider) async {
    final key = await read(provider);
    if (key == null) return null;
    if (key.length <= 4) return '••••';
    return '••••${key.substring(key.length - 4)}';
  }

  Future<void> deleteAll() => store.deleteAll();
}
