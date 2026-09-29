/// Local address book. Names are not message plaintext and are not stored
/// in the envelope table.
class Peer {
  const Peer({required this.userId, required this.chatId, required this.name});

  final String userId;
  final String chatId;
  final String name;

  String get initial => name.isEmpty ? '?' : name[0];
}

const peers = <Peer>[
  Peer(userId: 'user-marina', chatId: 'chat-marina', name: 'Марина Соколова'),
  Peer(userId: 'user-ilya', chatId: 'chat-ilya', name: 'Илья Петров'),
  Peer(userId: 'user-kira', chatId: 'chat-kira', name: 'Кира Лебедева'),
  Peer(userId: 'user-alexey', chatId: 'chat-alexey', name: 'Алексей Воронов'),
];

const alexeyChatId = 'chat-alexey';

Peer peerByChatId(String chatId) {
  return peers.firstWhere((peer) => peer.chatId == chatId);
}

Peer? peerByChatIdOrNull(String chatId) {
  for (final peer in peers) {
    if (peer.chatId == chatId) return peer;
  }
  return null;
}
