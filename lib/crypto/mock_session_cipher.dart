import 'dart:convert';
import 'dart:typed_data';

import 'session_cipher.dart';

/// Pipeline stand-in, not encryption.
///
/// Prefixes a version byte and base64-wraps the payload so send, store, and
/// display share one path. Anyone can reverse it. Production must replace
/// this class with official libsignal via FFI (`flutter_rust_bridge`) or a
/// reviewed Dart port — not a from-scratch Double Ratchet or X3DH.
class MockSessionCipher implements SessionCipher {
  const MockSessionCipher();

  static const int versionByte = 0x01;

  @override
  Future<Uint8List> encrypt(Uint8List plaintext) async {
    final wrapped = utf8.encode(base64Encode(plaintext));
    final out = Uint8List(1 + wrapped.length);
    out[0] = versionByte;
    out.setRange(1, out.length, wrapped);
    return out;
  }

  @override
  Future<Uint8List> decrypt(Uint8List ciphertext) async {
    if (ciphertext.isEmpty || ciphertext[0] != versionByte) {
      throw const FormatException('Unsupported mock ciphertext version');
    }
    final wrapped = utf8.decode(ciphertext.sublist(1));
    return Uint8List.fromList(base64Decode(wrapped));
  }
}
