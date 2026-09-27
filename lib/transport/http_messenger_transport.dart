import '../models/envelope.dart';
import '../models/server_models.dart';
import 'messenger_transport.dart';

/// Sketch of the real client. Fill the method bodies against
/// `docs/server-contract.md`. Do not change the interface.
///
/// Auth on `/v1/ws` is `Authorization: Bearer` or a first
/// `{type: auth, accessToken}` frame. Never put the token in the query string.
class HttpMessengerTransport implements MessengerTransport {
  HttpMessengerTransport({required this.baseUrl, this.accessToken});

  final String baseUrl;
  String? accessToken;

  @override
  Future<RegistrationResult> registerDevice(DeviceRegistrationRequest request) {
    // TODO(server): POST $baseUrl/v1/devices with request.toJson().
    // Store userId, deviceId, accessToken, refreshToken from the response.
    throw UnimplementedError('POST /v1/devices ($baseUrl)');
  }

  @override
  Future<TokenPair> refreshSession({required String refreshToken}) {
    // TODO(server): POST $baseUrl/v1/sessions/refresh
    // Body: {"refreshToken": refreshToken}. Rotate both tokens.
    // 401 when the refresh token is missing or already used.
    throw UnimplementedError('POST /v1/sessions/refresh ($baseUrl)');
  }

  @override
  Future<void> replenishOneTimePreKeys(List<OneTimePreKey> keys) {
    // TODO(server): PUT $baseUrl/v1/keys/one-time
    // Body: {"oneTimePreKeys": keys.map((key) => key.toJson()).toList()}.
    throw UnimplementedError('PUT /v1/keys/one-time ($baseUrl)');
  }

  @override
  Future<PreKeyBundle> fetchPreKeyBundle(String userId) {
    // TODO(server): GET $baseUrl/v1/keys/bundle/$userId
    // 409 when that user has no one-time prekeys left.
    // Until safety numbers exist, the server can substitute this bundle.
    throw UnimplementedError('GET /v1/keys/bundle/$userId ($baseUrl)');
  }

  @override
  Future<void> connect({required String accessToken}) {
    // TODO(server): WebSocket $baseUrl/v1/ws
    // Header: Authorization: Bearer $accessToken
    // or first frame {"type":"auth","accessToken": accessToken}.
    this.accessToken = accessToken;
    throw UnimplementedError('WebSocket /v1/ws ($baseUrl)');
  }

  @override
  Future<Envelope?> send(Envelope outbound) {
    // TODO(server): send {"type":"envelope", id, recipientUserId, ciphertext, sentAt}
    // Wait for {"type":"ack", id}. Return null; inbound envelopes arrive on [events].
    throw UnimplementedError('ws envelope ${outbound.id} ($baseUrl)');
  }

  @override
  Stream<ServerEvent> get events {
    // TODO(server): decode envelope and ack frames. No plaintext, no keys.
    throw UnimplementedError('ws events ($baseUrl)');
  }

  @override
  Future<void> close() async {
    // TODO(server): close the websocket when the HTTP client is wired up.
  }
}
