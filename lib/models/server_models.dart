/// DTOs for `docs/server-contract.md`.
///
/// Signed and one-time prekeys are opaque blobs. This client does not build
/// X3DH material; libsignal must fill these fields later.
class SignedPreKey {
  const SignedPreKey({
    required this.keyId,
    required this.publicKey,
    required this.signature,
  });

  final int keyId;
  final String publicKey;
  final String signature;

  Map<String, Object?> toJson() => {
    'keyId': keyId,
    'publicKey': publicKey,
    'signature': signature,
  };
}

class OneTimePreKey {
  const OneTimePreKey({required this.keyId, required this.publicKey});

  final int keyId;
  final String publicKey;

  Map<String, Object?> toJson() => {'keyId': keyId, 'publicKey': publicKey};
}

class DeviceRegistrationRequest {
  const DeviceRegistrationRequest({
    required this.registrationId,
    required this.identityPublicKey,
    required this.signedPreKey,
    required this.oneTimePreKeys,
  });

  final int registrationId;
  final String identityPublicKey;
  final SignedPreKey signedPreKey;
  final List<OneTimePreKey> oneTimePreKeys;

  Map<String, Object?> toJson() => {
    'registrationId': registrationId,
    'identityPublicKey': identityPublicKey,
    'signedPreKey': signedPreKey.toJson(),
    'oneTimePreKeys': oneTimePreKeys.map((key) => key.toJson()).toList(),
  };
}

class RegistrationResult {
  const RegistrationResult({
    required this.userId,
    required this.deviceId,
    required this.accessToken,
    required this.refreshToken,
  });

  final String userId;
  final String deviceId;
  final String accessToken;
  final String refreshToken;
}

class TokenPair {
  const TokenPair({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;
}

class PreKeyBundle {
  const PreKeyBundle({
    required this.userId,
    required this.deviceId,
    required this.registrationId,
    required this.identityPublicKey,
    required this.signedPreKey,
    this.oneTimePreKey,
  });

  final String userId;
  final String deviceId;
  final int registrationId;
  final String identityPublicKey;
  final SignedPreKey signedPreKey;
  final OneTimePreKey? oneTimePreKey;
}

/// Client → server websocket payload. Ciphertext only.
class WireEnvelope {
  const WireEnvelope({
    required this.id,
    required this.recipientUserId,
    required this.ciphertext,
    required this.sentAt,
  });

  final String id;
  final String recipientUserId;
  final String ciphertext;
  final DateTime sentAt;

  static const fields = <String>{
    'type',
    'id',
    'recipientUserId',
    'ciphertext',
    'sentAt',
  };

  Map<String, Object?> toJson() => {
    'type': 'envelope',
    'id': id,
    'recipientUserId': recipientUserId,
    'ciphertext': ciphertext,
    'sentAt': sentAt.toUtc().toIso8601String(),
  };
}

class TransportException implements Exception {
  const TransportException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => message;
}
