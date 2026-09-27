import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret/crypto/mock_session_cipher.dart';
import 'package:secret/data/app_database.dart';
import 'package:secret/data/envelope_repository.dart';
import 'package:secret/models/envelope.dart';

void main() {
  const marker = 'PLAINTEXT_MARKER_не_хранить_в_таблице';

  test('persists ciphertext only and reads the envelope back', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = EnvelopeRepository(database);
    final cipher = const MockSessionCipher();
    final ciphertext = await cipher.encrypt(utf8.encode(marker));
    final envelope = Envelope(
      id: 'env_db',
      chatId: 'chat-ilya',
      sender: 'user-local',
      createdAt: DateTime.utc(2026, 9, 27, 15, 30),
      ciphertext: base64Encode(ciphertext),
      status: EnvelopeStatus.pending,
    );

    await repository.insert(envelope);
    await repository.updateStatus(envelope.id, EnvelopeStatus.sent);
    final stored = await repository.listAll();

    expect(stored, hasLength(1));
    expect(stored.single.id, envelope.id);
    expect(stored.single.status, EnvelopeStatus.sent);
    expect(await cipher.decrypt(base64Decode(stored.single.ciphertext)), [
      ...utf8.encode(marker),
    ]);

    final encoded = jsonEncode(stored.single.toJson());
    expect(encoded.contains(marker), isFalse);
    expect(stored.single.toJson().keys.toSet(), Envelope.jsonFields);

    final columns = await database
        .customSelect('PRAGMA table_info(envelopes)')
        .get();
    final names = columns.map((row) => row.read<String>('name')).toSet();
    expect(names, {
      'id',
      'chat_id',
      'sender',
      'created_at',
      'ciphertext',
      'status',
    });
    expect(names.contains('plaintext'), isFalse);
    expect(names.contains('body'), isFalse);
    expect(names.contains('text'), isFalse);
  });
}
