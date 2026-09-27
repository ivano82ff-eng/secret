import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import '../crypto/session_cipher.dart';
import '../directory/peers.dart';
import '../models/envelope.dart';
import '../models/server_models.dart';
import 'messenger_transport.dart';

/// In-process stand-in for the contract in `docs/server-contract.md`.
///
/// Reply text exists only long enough to be wrapped by [SessionCipher].
/// The returned [Envelope] has ciphertext and no plaintext field.
class MockMessengerTransport implements MessengerTransport {
  MockMessengerTransport({
    required this.cipher,
    this.replyDelay = const Duration(milliseconds: 280),
    this.remoteOneTimePreKeys = 5,
  });

  final SessionCipher cipher;
  final Duration replyDelay;
  int remoteOneTimePreKeys;

  final _events = StreamController<ServerEvent>.broadcast();
  final _random = Random.secure();

  String? _accessToken;
  String? _refreshToken;
  int _tokenGeneration = 0;
  int _replyIndex = 0;

  static const replyTexts = <String>[
    'Принято.',
    'Увидел.',
    'Напишу, как будет ясно.',
  ];

  @override
  Stream<ServerEvent> get events => _events.stream;

  @override
  Future<RegistrationResult> registerDevice(
    DeviceRegistrationRequest request,
  ) async {
    _tokenGeneration += 1;
    _accessToken = 'mock-access-$_tokenGeneration';
    _refreshToken = 'mock-refresh-$_tokenGeneration';
    remoteOneTimePreKeys += request.oneTimePreKeys.length;
    return RegistrationResult(
      userId: localUserId,
      deviceId: 'device-local',
      accessToken: _accessToken!,
      refreshToken: _refreshToken!,
    );
  }

  @override
  Future<TokenPair> refreshSession({required String refreshToken}) async {
    if (refreshToken.isEmpty || refreshToken != _refreshToken) {
      throw const TransportException(401, 'invalid refresh token');
    }
    _tokenGeneration += 1;
    _accessToken = 'mock-access-$_tokenGeneration';
    _refreshToken = 'mock-refresh-$_tokenGeneration';
    return TokenPair(accessToken: _accessToken!, refreshToken: _refreshToken!);
  }

  @override
  Future<void> replenishOneTimePreKeys(List<OneTimePreKey> keys) async {
    remoteOneTimePreKeys += keys.length;
  }

  @override
  Future<PreKeyBundle> fetchPreKeyBundle(String userId) async {
    if (remoteOneTimePreKeys <= 0) {
      throw const TransportException(409, 'one-time prekeys exhausted');
    }
    remoteOneTimePreKeys -= 1;
    Peer? peer;
    for (final item in peers) {
      if (item.userId == userId) peer = item;
    }
    return PreKeyBundle(
      userId: userId,
      deviceId: 'device-${peer?.userId ?? userId}',
      registrationId: 2000 + _random.nextInt(1000),
      identityPublicKey: _opaque(32),
      signedPreKey: SignedPreKey(
        keyId: 1,
        publicKey: _opaque(32),
        signature: _opaque(64),
      ),
      oneTimePreKey: OneTimePreKey(
        keyId: _random.nextInt(1 << 16),
        publicKey: _opaque(32),
      ),
    );
  }

  @override
  Future<void> connect({required String accessToken}) async {
    if (accessToken.isEmpty || accessToken != _accessToken) {
      throw const TransportException(401, 'invalid access token');
    }
  }

  @override
  Future<Envelope?> send(Envelope outbound) async {
    final peer = peerByChatId(outbound.chatId);
    final wire = WireEnvelope(
      id: outbound.id,
      recipientUserId: peer.userId,
      ciphertext: outbound.ciphertext,
      sentAt: outbound.createdAt,
    );
    _rejectPlaintextFields(wire.toJson());
    _events.add(EnvelopeAcknowledged(outbound.id));

    if (replyDelay > Duration.zero) {
      await Future<void>.delayed(replyDelay);
    }

    final replyText = replyTexts[_replyIndex % replyTexts.length];
    _replyIndex += 1;
    final ciphertext = await cipher.encrypt(
      Uint8List.fromList(utf8.encode(replyText)),
    );
    final inbound = Envelope(
      id: _newId(),
      chatId: outbound.chatId,
      sender: peer.userId,
      createdAt: DateTime.now().toUtc(),
      ciphertext: base64Encode(ciphertext),
      status: EnvelopeStatus.received,
    );
    _rejectPlaintextFields({
      'type': 'envelope',
      'id': inbound.id,
      'recipientUserId': localUserId,
      'ciphertext': inbound.ciphertext,
      'sentAt': inbound.createdAt.toIso8601String(),
    });
    _events.add(EnvelopeDelivered(inbound));
    return inbound;
  }

  @override
  Future<void> close() async {}

  String _opaque(int length) {
    return base64Encode(
      List<int>.generate(length, (_) => _random.nextInt(256)),
    );
  }

  String _newId() {
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final salt = _random.nextInt(1 << 30).toRadixString(16);
    return 'env_${now}_$salt';
  }

  void _rejectPlaintextFields(Map<String, Object?> wire) {
    const banned = {'body', 'text', 'plaintext', 'filename', 'content'};
    for (final key in wire.keys) {
      if (banned.contains(key)) {
        throw StateError('Wire payload must not carry $key');
      }
    }
  }
}
