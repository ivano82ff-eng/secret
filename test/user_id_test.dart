import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:secret/crypto/mock_session_cipher.dart';
import 'package:secret/models/server_models.dart';
import 'package:secret/session/user_id.dart';
import 'package:secret/transport/mock_messenger_transport.dart';

void main() {
  test('mintUserId matches the canonical form', () {
    final random = Random(4);
    final ids = List.generate(48, (_) => mintUserId(random));
    expect(ids, everyElement(matches(userIdPattern)));
    expect(ids.toSet().length, greaterThan(1));
  });

  test('mock registration reuses a held user id', () async {
    final transport = MockMessengerTransport(
      cipher: const MockSessionCipher(),
      localUserId: '456 N 634',
    );
    final first = await transport.registerDevice(_request());
    final second = await transport.registerDevice(_request());
    expect(first.userId, '456 N 634');
    expect(second.userId, first.userId);
  });

  test('mock registration mints one id for the transport', () async {
    final transport = MockMessengerTransport(
      cipher: const MockSessionCipher(),
      random: Random(9),
    );
    final first = await transport.registerDevice(_request());
    final second = await transport.registerDevice(_request());
    expect(first.userId, matches(userIdPattern));
    expect(second.userId, first.userId);
  });
}

DeviceRegistrationRequest _request() {
  return const DeviceRegistrationRequest(
    registrationId: 4821,
    identityPublicKey: 'a2V5',
    signedPreKey: SignedPreKey(keyId: 1, publicKey: 'cHVi', signature: 'c2ln'),
    oneTimePreKeys: [OneTimePreKey(keyId: 1, publicKey: 'b25l')],
  );
}
