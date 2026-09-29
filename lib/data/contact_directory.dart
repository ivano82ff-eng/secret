import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../transport/canonical_user_id.dart';

class StoredContact {
  const StoredContact({required this.userId, required this.displayName});

  /// Same as [chatId] in real-server mode.
  final String userId;
  final String displayName;
}

class ContactDirectory {
  ContactDirectory(this._prefs);

  final SharedPreferences _prefs;
  static const _key = 'messenger.contacts.v1';

  List<StoredContact> readAll() {
    final raw = _prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return [
        for (final item in list)
          if (item is Map<String, dynamic>)
            StoredContact(
              userId: item['userId'] as String,
              displayName: item['displayName'] as String? ?? item['userId'] as String,
            ),
      ];
    } on Object {
      return const [];
    }
  }

  Future<void> add({required String userId, String? displayName}) async {
    final canonical = canonicalizeUserId(userId);
    if (canonical == null) {
      throw ArgumentError('invalid userId');
    }
    final name = (displayName ?? canonical).trim();
    final all = readAll();
    if (all.any((c) => c.userId == canonical)) return;
    final next = [
      ...all,
      StoredContact(userId: canonical, displayName: name.isEmpty ? canonical : name),
    ];
    await _prefs.setString(
      _key,
      jsonEncode([
        for (final c in next) {'userId': c.userId, 'displayName': c.displayName},
      ]),
    );
  }
}
