import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/envelope.dart';
import '../models/server_models.dart';
import 'canonical_user_id.dart';
import 'messenger_transport.dart';
import 'ws_channel_factory.dart';

/// Live client for `docs/server-contract.md`.
///
/// Auth on `/v1/ws` is `Authorization: Bearer` or a first
/// `{type: auth, accessToken}` frame. Never put the token in the query string.
class HttpMessengerTransport implements MessengerTransport {
  HttpMessengerTransport({
    required this.baseUrl,
    this.accessToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  final String baseUrl;
  String? accessToken;
  final http.Client _client;

  WebSocketChannel? _channel;
  StreamSubscription<Object?>? _wsSub;
  StreamController<ServerEvent>? _events;
  final Map<String, Completer<void>> _ackWaiters = {};

  static const _timeout = Duration(seconds: 12);

  Uri get _origin => Uri.parse(baseUrl);

  Uri _uri(String path) => _origin.replace(path: path);

  Future<http.Response> _send(Future<http.Response> future) async {
    try {
      return await future.timeout(_timeout);
    } on TimeoutException {
      throw TransportException(
        0,
        'Сервер не отвечает: $baseUrl (таймаут ${_timeout.inSeconds} с)',
      );
    } on http.ClientException catch (e) {
      throw TransportException(0, 'Нет связи с сервером: ${e.message}');
    }
  }

  @override
  Future<RegistrationResult> registerDevice(
    DeviceRegistrationRequest request,
  ) async {
    final response = await _send(
      _client.post(
        _uri('/v1/devices'),
        headers: _jsonHeaders(),
        body: jsonEncode(request.toJson()),
      ),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 201) {
      throw TransportException(response.statusCode, _errorMessage(body));
    }
    accessToken = body['accessToken'] as String?;
    return RegistrationResult(
      userId: body['userId'] as String,
      deviceId: body['deviceId'] as String,
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
    );
  }

  @override
  Future<TokenPair> refreshSession({required String refreshToken}) async {
    final response = await _send(
      _client.post(
        _uri('/v1/sessions/refresh'),
        headers: _jsonHeaders(),
        body: jsonEncode({'refreshToken': refreshToken}),
      ),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 200) {
      throw TransportException(response.statusCode, _errorMessage(body));
    }
    accessToken = body['accessToken'] as String?;
    return TokenPair(
      accessToken: body['accessToken'] as String,
      refreshToken: body['refreshToken'] as String,
    );
  }

  @override
  Future<void> replenishOneTimePreKeys(List<OneTimePreKey> keys) async {
    final response = await _send(
      _client.put(
        _uri('/v1/keys/one-time'),
        headers: _jsonHeaders(bearer: accessToken),
        body: jsonEncode({
          'oneTimePreKeys': keys.map((key) => key.toJson()).toList(),
        }),
      ),
    );
    if (response.statusCode != 200) {
      final body = _decodeBody(response);
      throw TransportException(response.statusCode, _errorMessage(body));
    }
  }

  @override
  Future<PreKeyBundle> fetchPreKeyBundle(String userId) async {
    final canonical = canonicalizeUserId(userId);
    if (canonical == null) {
      throw const TransportException(400, 'invalid userId');
    }
    final response = await _send(
      _client.get(
        _uri('/v1/keys/bundle/${encodeUserIdPathSegment(canonical)}'),
        headers: _jsonHeaders(bearer: accessToken),
      ),
    );
    final body = _decodeBody(response);
    if (response.statusCode != 200) {
      throw TransportException(response.statusCode, _errorMessage(body));
    }
    final otp = body['oneTimePreKey'] as Map<String, dynamic>?;
    return PreKeyBundle(
      userId: body['userId'] as String,
      deviceId: body['deviceId'] as String,
      registrationId: body['registrationId'] as int,
      identityPublicKey: body['identityPublicKey'] as String,
      signedPreKey: SignedPreKey(
        keyId: (body['signedPreKey'] as Map<String, dynamic>)['keyId'] as int,
        publicKey:
            (body['signedPreKey'] as Map<String, dynamic>)['publicKey'] as String,
        signature:
            (body['signedPreKey'] as Map<String, dynamic>)['signature'] as String,
      ),
      oneTimePreKey: otp == null
          ? null
          : OneTimePreKey(
              keyId: otp['keyId'] as int,
              publicKey: otp['publicKey'] as String,
            ),
    );
  }

  @override
  Future<void> connect({required String accessToken}) async {
    await close();
    this.accessToken = accessToken;
    _events = StreamController<ServerEvent>.broadcast();

    final wsScheme = _origin.scheme == 'https' ? 'wss' : 'ws';
    final wsUri = _origin.replace(scheme: wsScheme, path: '/v1/ws', query: '');

    _channel = await openAuthenticatedWebSocket(wsUri, accessToken);
    _wsSub = _channel!.stream.listen(
      _onWsData,
      onError: (_) => _events?.addError(StateError('websocket error')),
      onDone: () {},
    );
  }

  void _onWsData(Object? data) {
    Map<String, dynamic> msg;
    try {
      msg = jsonDecode(data as String) as Map<String, dynamic>;
    } on Object {
      return;
    }
    switch (msg['type']) {
      case 'envelope':
        final sender = msg['senderUserId'] as String? ?? '';
        final id = msg['id'] as String? ?? '';
        final ciphertext = msg['ciphertext'] as String? ?? '';
        final sentAtRaw = msg['sentAt'] as String?;
        if (id.isEmpty || ciphertext.isEmpty || sentAtRaw == null) return;
        final sentAt = DateTime.parse(sentAtRaw).toUtc();
        _events?.add(
          EnvelopeDelivered(
            Envelope(
              id: id,
              chatId: sender,
              sender: sender,
              createdAt: sentAt,
              ciphertext: ciphertext,
              status: EnvelopeStatus.received,
            ),
          ),
        );
      case 'ack':
        final id = msg['id'] as String?;
        if (id != null) _ackWaiters.remove(id)?.complete();
      case 'error':
        break;
      default:
        break;
    }
  }

  @override
  Future<Envelope?> send(Envelope outbound) async {
    final channel = _channel;
    if (channel == null) {
      throw StateError('WebSocket is not connected');
    }
    final recipient = canonicalizeUserId(outbound.chatId);
    if (recipient == null) {
      throw const TransportException(400, 'invalid recipientUserId');
    }

    final wire = WireEnvelope(
      id: outbound.id,
      recipientUserId: recipient,
      ciphertext: outbound.ciphertext,
      sentAt: outbound.createdAt,
    );

    final ack = Completer<void>();
    _ackWaiters[outbound.id] = ack;
    channel.sink.add(jsonEncode(wire.toJson()));

    try {
      await ack.future.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      _ackWaiters.remove(outbound.id);
      throw StateError('ack timeout for ${outbound.id}');
    }
    return null;
  }

  @override
  Stream<ServerEvent> get events {
    final stream = _events?.stream;
    if (stream == null) {
      throw StateError('WebSocket is not connected');
    }
    return stream;
  }

  @override
  Future<void> close() async {
    await _wsSub?.cancel();
    _wsSub = null;
    await _channel?.sink.close();
    _channel = null;
    await _events?.close();
    _events = null;
    for (final waiter in _ackWaiters.values) {
      if (!waiter.isCompleted) waiter.completeError(StateError('closed'));
    }
    _ackWaiters.clear();
  }

  Map<String, String> _jsonHeaders({String? bearer}) {
    final headers = {'Content-Type': 'application/json'};
    final token = bearer ?? accessToken;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Map<String, dynamic> _decodeBody(http.Response response) {
    if (response.body.isEmpty) return {};
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  String _errorMessage(Map<String, dynamic> body) {
    final err = body['error'];
    if (err is String && err.isNotEmpty) return err;
    return 'request failed';
  }
}
