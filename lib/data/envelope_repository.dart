import 'package:drift/drift.dart';

import '../models/envelope.dart';
import 'app_database.dart';

class EnvelopeRepository {
  EnvelopeRepository(this._db);

  final AppDatabase _db;

  Future<int> count() async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS c FROM envelopes')
        .getSingle();
    return row.read<int>('c');
  }

  Future<void> insert(Envelope envelope) {
    return _db
        .into(_db.storedEnvelopes)
        .insert(
          StoredEnvelopesCompanion.insert(
            id: envelope.id,
            chatId: envelope.chatId,
            sender: envelope.sender,
            createdAt: envelope.createdAt,
            ciphertext: envelope.ciphertext,
            status: envelope.status.name,
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  Future<void> updateStatus(String id, EnvelopeStatus status) {
    return (_db.update(_db.storedEnvelopes)..where((row) => row.id.equals(id)))
        .write(StoredEnvelopesCompanion(status: Value(status.name)));
  }

  Future<void> updateCiphertext(String id, String ciphertext) {
    return (_db.update(_db.storedEnvelopes)..where((row) => row.id.equals(id)))
        .write(StoredEnvelopesCompanion(ciphertext: Value(ciphertext)));
  }

  Future<void> deleteById(String id) {
    return (_db.delete(_db.storedEnvelopes)..where((row) => row.id.equals(id)))
        .go();
  }

  Future<void> deleteChat(String chatId) {
    return (_db.delete(
      _db.storedEnvelopes,
    )..where((row) => row.chatId.equals(chatId))).go();
  }

  Future<List<Envelope>> listAll() async {
    final rows = await (_db.select(
      _db.storedEnvelopes,
    )..orderBy([(row) => OrderingTerm.asc(row.createdAt)])).get();
    return rows.map(_map).toList();
  }

  Envelope _map(StoredEnvelope row) {
    return Envelope(
      id: row.id,
      chatId: row.chatId,
      sender: row.sender,
      createdAt: row.createdAt.toUtc(),
      ciphertext: row.ciphertext,
      status: EnvelopeStatus.values.byName(row.status),
    );
  }
}
