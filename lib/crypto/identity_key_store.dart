import 'dart:convert';

import 'package:cryptography/cryptography.dart';

import 'private_key_vault.dart';

/// Public half of the device identity. This is what would be registered
/// with the server. The private key never leaves [PrivateKeyVault].
class IdentityPublicInfo {
  const IdentityPublicInfo({required this.publicKeyBase64});

  final String publicKeyBase64;
}

class IdentityLoad {
  const IdentityLoad({required this.info, required this.freshlyCreated});

  final IdentityPublicInfo info;

  /// True only when this call generated a new private key.
  final bool freshlyCreated;
}

class IdentityKeyStore {
  IdentityKeyStore({required this.vault, X25519? keyExchange})
    : algorithm = keyExchange ?? X25519();

  final PrivateKeyVault vault;
  final X25519 algorithm;

  Future<IdentityLoad> loadOrCreate() async {
    final existing = await vault.readPrivateKey();
    if (existing != null && existing.isNotEmpty) {
      final pair = await algorithm.newKeyPairFromSeed(base64Decode(existing));
      return IdentityLoad(info: await _publicInfo(pair), freshlyCreated: false);
    }

    final created = await algorithm.newKeyPair();
    final privateBytes = await created.extractPrivateKeyBytes();
    await vault.writePrivateKey(base64Encode(privateBytes));
    return IdentityLoad(info: await _publicInfo(created), freshlyCreated: true);
  }

  Future<IdentityPublicInfo> _publicInfo(KeyPair pair) async {
    final publicKey = await pair.extractPublicKey();
    if (publicKey is! SimplePublicKey) {
      throw StateError('X25519 identity key is missing a public key');
    }
    return IdentityPublicInfo(publicKeyBase64: base64Encode(publicKey.bytes));
  }
}
