import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Canonical `userId` from `docs/server-contract.md`.
///
/// Three digits, a space, one uppercase Latin letter, a space, three digits.
final userIdPattern = RegExp(r'^[0-9]{3} [A-Z] [0-9]{3}$');

/// Install-scoped address. The private key stays in its own vault.
abstract interface class UserIdStore {
  Future<String?> read();

  Future<void> write(String userId);
}

class FlutterSecureUserIdStore implements UserIdStore {
  FlutterSecureUserIdStore(this._storage);

  final FlutterSecureStorage _storage;

  static const storageKey = 'local_user_id';

  @override
  Future<String?> read() => _storage.read(key: storageKey);

  @override
  Future<void> write(String userId) {
    if (!userIdPattern.hasMatch(userId)) {
      throw ArgumentError.value(userId, 'userId', 'userId is not canonical');
    }
    return _storage.write(key: storageKey, value: userId);
  }
}

/// Six digits and one letter, as in `456 N 634`.
String mintUserId(Random random) {
  final digits = List.generate(
    6,
    (_) => random.nextInt(10).toString(),
  ).join();
  final letter = String.fromCharCode(65 + random.nextInt(26));
  return '${digits.substring(0, 3)} $letter ${digits.substring(3)}';
}
