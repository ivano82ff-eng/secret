import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Storage for the X25519 identity private key.
///
/// The only production implementation is [FlutterSecurePrivateKeyVault].
/// Never write this key to Drift, Hive, or shared_preferences, and never log it.
abstract interface class PrivateKeyVault {
  Future<String?> readPrivateKey();

  Future<void> writePrivateKey(String stored);
}

class FlutterSecurePrivateKeyVault implements PrivateKeyVault {
  FlutterSecurePrivateKeyVault(this._storage);

  final FlutterSecureStorage _storage;

  static const storageKey = 'identity_x25519_private';

  @override
  Future<String?> readPrivateKey() => _storage.read(key: storageKey);

  @override
  Future<void> writePrivateKey(String stored) {
    return _storage.write(key: storageKey, value: stored);
  }
}
