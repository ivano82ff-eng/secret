import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../crypto/session_cipher.dart';
import '../data/envelope_repository.dart';
import '../directory/peers.dart';
import '../models/envelope.dart';

class DemoSeeder {
  DemoSeeder({required this.repository, required this.cipher});

  final EnvelopeRepository repository;
  final SessionCipher cipher;
  bool _done = false;

  Future<void> seedIfEmpty() async {
    if (_done) return;
    if (await repository.count() > 0) {
      _done = true;
      return;
    }
    _done = true;
    final now = DateTime.now().toUtc();
    await _insert(
      chatId: 'chat-kira',
      sender: 'user-kira',
      text: 'Завтра в десять всё ещё удобно?',
      createdAt: now.subtract(const Duration(days: 4, hours: 2)),
      status: EnvelopeStatus.received,
    );
    await _insert(
      chatId: 'chat-kira',
      sender: localUserId,
      text: 'Да, подхожу к десяти.',
      createdAt: now.subtract(const Duration(days: 4, hours: 1, minutes: 50)),
      status: EnvelopeStatus.sent,
    );
    await _insert(
      chatId: 'chat-ilya',
      sender: 'user-ilya',
      text: 'Скинь номер договора, как будешь у компьютера.',
      createdAt: now.subtract(const Duration(days: 1, hours: 3)),
      status: EnvelopeStatus.received,
    );
    await _insert(
      chatId: 'chat-marina',
      sender: 'user-marina',
      text: 'Дойду до метро и напишу.',
      createdAt: now.subtract(const Duration(hours: 2)),
      status: EnvelopeStatus.received,
    );
    await _insert(
      chatId: 'chat-marina',
      sender: localUserId,
      text: 'Хорошо, жду у выхода.',
      createdAt: now.subtract(const Duration(hours: 1, minutes: 40)),
      status: EnvelopeStatus.sent,
    );
  }

  Future<void> _insert({
    required String chatId,
    required String sender,
    required String text,
    required DateTime createdAt,
    required EnvelopeStatus status,
  }) async {
    final ciphertext = await cipher.encrypt(
      Uint8List.fromList(utf8.encode(text)),
    );
    await repository.insert(
      Envelope(
        id: _id(chatId, createdAt),
        chatId: chatId,
        sender: sender,
        createdAt: createdAt,
        ciphertext: base64Encode(ciphertext),
        status: status,
      ),
    );
  }

  String _id(String chatId, DateTime createdAt) {
    final salt = Random(createdAt.microsecondsSinceEpoch).nextInt(1 << 20);
    return 'seed_${chatId}_${createdAt.microsecondsSinceEpoch}_$salt';
  }
}
