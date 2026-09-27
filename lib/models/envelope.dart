/// Persisted and API-facing message. Ciphertext only — no plaintext body.
enum EnvelopeStatus { pending, sent, received }

class Envelope {
  const Envelope({
    required this.id,
    required this.chatId,
    required this.sender,
    required this.createdAt,
    required this.ciphertext,
    required this.status,
  });

  final String id;
  final String chatId;
  final String sender;
  final DateTime createdAt;

  /// Base64 of opaque ciphertext bytes. Not a message body.
  final String ciphertext;
  final EnvelopeStatus status;

  static const jsonFields = <String>{
    'id',
    'chatId',
    'sender',
    'createdAt',
    'ciphertext',
    'status',
  };

  Envelope copyWith({EnvelopeStatus? status}) {
    return Envelope(
      id: id,
      chatId: chatId,
      sender: sender,
      createdAt: createdAt,
      ciphertext: ciphertext,
      status: status ?? this.status,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'chatId': chatId,
    'sender': sender,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'ciphertext': ciphertext,
    'status': status.name,
  };

  factory Envelope.fromJson(Map<String, Object?> json) {
    return Envelope(
      id: json['id']! as String,
      chatId: json['chatId']! as String,
      sender: json['sender']! as String,
      createdAt: DateTime.parse(json['createdAt']! as String).toUtc(),
      ciphertext: json['ciphertext']! as String,
      status: EnvelopeStatus.values.byName(json['status']! as String),
    );
  }
}
