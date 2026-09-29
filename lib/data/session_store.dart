import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/server_models.dart';

const _sessionKey = 'messenger.session.v1';

class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<RegistrationResult?> read() async {
    final raw = await _storage.read(key: _sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      return RegistrationResult(
        userId: json['userId'] as String,
        deviceId: json['deviceId'] as String,
        accessToken: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
      );
    } on Object {
      return null;
    }
  }

  Future<void> write(RegistrationResult session) async {
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode({
        'userId': session.userId,
        'deviceId': session.deviceId,
        'accessToken': session.accessToken,
        'refreshToken': session.refreshToken,
      }),
    );
  }

  Future<void> clear() => _storage.delete(key: _sessionKey);
}
