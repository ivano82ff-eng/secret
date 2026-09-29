import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret/crypto/mock_session_cipher.dart';
import 'package:secret/models/envelope.dart';

void main() {
  const cipher = MockSessionCipher();
  const marker = 'PLAINTEXT_MARKER_не_должно_попасть_в_json';

  test('roundtrips opaque bytes and prefixes a version byte', () async {
    final plain = utf8.encode(marker);
    final ciphertext = await cipher.encrypt(plain);

    expect(ciphertext.first, MockSessionCipher.versionByte);
    expect(utf8.decode(ciphertext.sublist(1)), base64Encode(plain));
    expect(await cipher.decrypt(ciphertext), plain);
  });

  test('envelope json has ciphertext and no plaintext field', () async {
    final ciphertext = await cipher.encrypt(utf8.encode(marker));
    final envelope = Envelope(
      id: 'env_1',
      chatId: 'chat-marina',
      sender: '456 N 634',
      createdAt: DateTime.utc(2026, 9, 27, 12),
      ciphertext: base64Encode(ciphertext),
      status: EnvelopeStatus.sent,
    );

    final json = envelope.toJson();
    expect(json.keys.toSet(), Envelope.jsonFields);
    final encoded = jsonEncode(json);
    expect(encoded.contains(marker), isFalse);
    expect(encoded.contains('"body"'), isFalse);
    expect(encoded.contains('"plaintext"'), isFalse);
    expect(encoded.contains('"text"'), isFalse);
    expect(encoded.contains('"filename"'), isFalse);
  });
}
