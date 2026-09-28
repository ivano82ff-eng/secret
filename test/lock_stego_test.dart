import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret/crypto/lock_stego.dart';
import 'package:secret/crypto/mock_session_cipher.dart';
import 'package:secret/models/server_models.dart';

void main() {
  const text = 'STEGO-PLAINTEXT-MARKER-9f3a';

  test('lock png roundtrip hides plaintext and decrypts to the text', () async {
    const cipher = MockSessionCipher();
    final sessionBytes = await cipher.encrypt(utf8.encode(text));
    final png = LockStego.embed(sessionBytes);

    expect(LockStego.looksLikePng(png), isTrue);
    expect(_containsAscii(png, text), isFalse);
    expect(_containsAscii(png, 'tEXt'), isFalse);

    final hidden = LockStego.extract(png);
    expect(hidden, sessionBytes);

    final sealed = await sealMessage(cipher, text, extra: true);
    expect(_containsAscii(sealed, text), isFalse);
    final opened = await openMessage(cipher, base64Encode(sealed));
    expect(opened.text, text);
    expect(opened.extraLayer, isTrue);

    final wire = WireEnvelope(
      id: 'env_test',
      recipientUserId: 'user-peer',
      ciphertext: base64Encode(sealed),
      sentAt: DateTime.utc(2026, 9, 28),
    );
    expect(wire.toJson().keys, {
      'type',
      'id',
      'recipientUserId',
      'ciphertext',
      'sentAt',
    });
    final carried = base64Decode(wire.ciphertext);
    expect(LockStego.looksLikePng(carried), isTrue);
    expect(_containsAscii(carried, text), isFalse);
  });

  test('toggle off keeps the normal ciphertext path', () async {
    const cipher = MockSessionCipher();
    final sealed = await sealMessage(cipher, text, extra: false);
    expect(LockStego.looksLikePng(sealed), isFalse);
    expect(LockStego.extract(sealed), isNull);
    final opened = await openMessage(cipher, base64Encode(sealed));
    expect(opened.text, text);
    expect(opened.extraLayer, isFalse);
  });
}

bool _containsAscii(Uint8List bytes, String needle) {
  final pattern = utf8.encode(needle);
  if (pattern.isEmpty || bytes.length < pattern.length) return false;
  for (var i = 0; i <= bytes.length - pattern.length; i++) {
    var match = true;
    for (var j = 0; j < pattern.length; j++) {
      if (bytes[i + j] != pattern[j]) {
        match = false;
        break;
      }
    }
    if (match) return true;
  }
  return false;
}
