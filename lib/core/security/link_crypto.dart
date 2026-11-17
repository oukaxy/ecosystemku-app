import 'dart:convert';

import 'package:crypto/crypto.dart' show sha256;
import 'package:cryptography/cryptography.dart';

class LinkCryptoException implements Exception {
  LinkCryptoException(this.message);

  final String message;

  @override
  String toString() => message;
}

class LinkCrypto {
  static const salt = 'linkku-salt-v1';
  static const iterations = 100000;

  Future<String> hashPin(String pin) async =>
      sha256.convert(utf8.encode(pin)).toString();

  Future<String> encryptPrivate(String pin, Map<String, dynamic> payload) async {
    final key = await _deriveKey(pin);
    final algorithm = AesGcm.with256bits();
    final nonce = algorithm.newNonce();
    final box = await algorithm.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: key,
      nonce: nonce,
    );
    return base64Encode(box.concatenation());
  }

  Future<Map<String, dynamic>> decryptPrivate(String pin, String ep) async {
    final key = await _deriveKey(pin);
    final algorithm = AesGcm.with256bits();
    try {
      final combined = base64Decode(ep);
      final box = SecretBox.fromConcatenation(
        combined,
        nonceLength: 12,
        macLength: 16,
      );
      final clear = await algorithm.decrypt(box, secretKey: key);
      final decoded = jsonDecode(utf8.decode(clear));
      if (decoded is! Map<String, dynamic>) {
        throw LinkCryptoException('Isi link privat tidak valid.');
      }
      return decoded;
    } on SecretBoxAuthenticationError {
      throw LinkCryptoException('PIN salah.');
    } on FormatException {
      throw LinkCryptoException('Data link privat rusak.');
    }
  }

  Future<SecretKey> _deriveKey(String pin) async {
    final pinHash = await hashPin(pin);
    final algorithm = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(pinHash)),
      nonce: utf8.encode(salt),
    );
  }
}
