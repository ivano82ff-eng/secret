import '../models/envelope.dart';
import '../models/server_models.dart';

/// Server boundary. The app runs on [MockMessengerTransport] today.
/// [HttpMessengerTransport] is the fill-in for the same methods.
abstract interface class MessengerTransport {
  Future<RegistrationResult> registerDevice(DeviceRegistrationRequest request);

  Future<TokenPair> refreshSession({required String refreshToken});

  Future<void> replenishOneTimePreKeys(List<OneTimePreKey> keys);

  Future<PreKeyBundle> fetchPreKeyBundle(String userId);

  /// Opens `/v1/ws`. Auth is the Authorization header or a first
  /// `{type: auth, accessToken}` frame, never a query string.
  Future<void> connect({required String accessToken});

  /// Sends an opaque envelope. The mock returns a ciphertext inbound reply.
  /// The HTTP implementation returns null and delivers traffic on [events].
  Future<Envelope?> send(Envelope outbound);

  Stream<ServerEvent> get events;

  Future<void> close();
}

sealed class ServerEvent {
  const ServerEvent();
}

class EnvelopeDelivered extends ServerEvent {
  const EnvelopeDelivered(this.envelope);

  final Envelope envelope;
}

class EnvelopeAcknowledged extends ServerEvent {
  const EnvelopeAcknowledged(this.id);

  final String id;
}
