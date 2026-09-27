import 'dart:typed_data';

/// Opaque session encryption for one conversation.
///
/// [encrypt] and [decrypt] take opaque bytes so the rest of the app never
/// depends on a concrete cipher. Production must replace [MockSessionCipher]
/// with official libsignal (Double Ratchet) via FFI (`flutter_rust_bridge`)
/// or a reviewed Dart port. Do not implement a ratchet from scratch here.
abstract interface class SessionCipher {
  Future<Uint8List> encrypt(Uint8List plaintext);

  Future<Uint8List> decrypt(Uint8List ciphertext);
}
