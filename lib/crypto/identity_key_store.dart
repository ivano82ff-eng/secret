import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'private_key_vault.dart';

/// Public half of the device identity. This is what would be registered
/// with the server. The private key never leaves [PrivateKeyVault].
class IdentityPublicInfo {
  const IdentityPublicInfo({required this.publicKeyBase64});

  final String publicKeyBase64;
}

class IdentityKeyStore {
  IdentityKeyStore({required this.vault, X25519? keyExchange})
    : algorithm = keyExchange ?? X25519();

  final PrivateKeyVault vault;
  final X25519 algorithm;

  Future<IdentityPublicInfo> loadOrCreate() async {
    final existing = await vault.readPrivateKey();
    if (existing != null && existing.isNotEmpty) {
      final pair = await algorithm.newKeyPairFromSeed(base64Decode(existing));
      return _publicInfo(pair);
    }

    final created = await algorithm.newKeyPair();
    final privateBytes = await created.extractPrivateKeyBytes();
    await vault.writePrivateKey(base64Encode(privateBytes));
    return _publicInfo(created);
  }

  Future<IdentityPublicInfo> _publicInfo(KeyPair pair) async {
    final publicKey = await pair.extractPublicKey();
    if (publicKey is! SimplePublicKey) {
      throw StateError('X25519 identity key is missing a public key');
    }
    return IdentityPublicInfo(publicKeyBase64: base64Encode(publicKey.bytes));
  }
}
