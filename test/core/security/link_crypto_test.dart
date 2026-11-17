import 'dart:convert';
import 'dart:io';

import 'package:ecosystemku/core/security/link_crypto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> fixture;
  final crypto = LinkCrypto();

  setUpAll(() {
    fixture = jsonDecode(
      File('test/fixtures/crypto/linkku_v1.json').readAsStringSync(),
    ) as Map<String, dynamic>;
  });

  test('PIN hash matches WebCrypto fixture', () async {
    expect(await crypto.hashPin(fixture['pin'] as String), fixture['pinHash']);
  });

  test('decrypts WebCrypto AES-GCM payload', () async {
    final data = await crypto.decryptPrivate(
      fixture['pin'] as String,
      fixture['ep'] as String,
    );

    expect(jsonEncode(data), jsonEncode(fixture['expected']));
  });

  test('wrong PIN rejects payload', () async {
    expect(
      () => crypto.decryptPrivate('0000', fixture['ep'] as String),
      throwsA(isA<LinkCryptoException>()),
    );
  });
}
