import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

class SecurityService {
  static final _algorithm = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: 120000,
    bits: 256,
  );
  static Future<(String, String)> createPin(String pin) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw const FormatException('Use exactly six digits');
    }
    final random = Random.secure();
    final salt = List.generate(16, (_) => random.nextInt(256));
    final key = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(pin)),
      nonce: salt,
    );
    return (base64Encode(await key.extractBytes()), base64Encode(salt));
  }

  static Future<bool> verifyPin(
    String pin,
    String expected,
    String salt,
  ) async {
    if (expected.isEmpty || salt.isEmpty || !RegExp(r'^\d{6}$').hasMatch(pin)) {
      return false;
    }
    try {
      final key = await _algorithm.deriveKey(
        secretKey: SecretKey(utf8.encode(pin)),
        nonce: base64Decode(salt),
      );
      final actual = await key.extractBytes(), target = base64Decode(expected);
      var diff = actual.length ^ target.length;
      for (var i = 0; i < actual.length && i < target.length; i++) {
        diff |= actual[i] ^ target[i];
      }
      return diff == 0;
    } catch (_) {
      return false;
    }
  }
}
