import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'crypto/identity_key_store.dart';
import 'crypto/lock_stego.dart';
import 'crypto/mock_session_cipher.dart';
import 'crypto/private_key_vault.dart';
import 'crypto/session_cipher.dart';
import 'data/app_database.dart';
import 'data/envelope_repository.dart';
import 'demo/demo_seeder.dart';
import 'directory/peers.dart';
import 'media/attachment_picker.dart';
import 'media/device_voice.dart';
import 'media/voice_recorder.dart';
import 'models/display_message.dart';
import 'models/envelope.dart';
import 'models/payload_markers.dart';
import 'models/server_models.dart';
import 'notifications/neutral_notifications.dart';
import 'session/local_media.dart';
import 'session/notices.dart';
import 'session/user_id.dart';
import 'transport/messenger_transport.dart';
import 'transport/mock_messenger_transport.dart';

enum PreviewMode { normal, empty, loading, error, threadError, notify }

class ChatSummary {
  const ChatSummary({
    required this.chatId,
    required this.title,
    required this.updatedAt,
    required this.preview,
  });

  final String chatId;
  final String title;
  final DateTime updatedAt;

  /// Neutral list preview. The decrypted body is not shown here.
  final String preview;
}

const neutralPreview = 'Сообщение';

final previewModeProvider = Provider<PreviewMode>((ref) {
  final raw = Uri.base.queryParameters['preview'];
  return switch (raw) {
    'empty' => PreviewMode.empty,
    'loading' => PreviewMode.loading,
    'error' => PreviewMode.error,
    'thread-error' => PreviewMode.threadError,
    'notify' => PreviewMode.notify,
    _ => PreviewMode.normal,
  };
});

final seedDemoProvider = Provider<bool>((ref) => true);

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase.defaults();
  ref.onDispose(database.close);
  return database;
});

final envelopeRepositoryProvider = Provider<EnvelopeRepository>((ref) {
  return EnvelopeRepository(ref.watch(databaseProvider));
});

final sessionCipherProvider = Provider<SessionCipher>((ref) {
  return const MockSessionCipher();
});

final transportProvider = Provider<MessengerTransport>((ref) {
  return MockMessengerTransport(cipher: ref.watch(sessionCipherProvider));
});

final privateKeyVaultProvider = Provider<PrivateKeyVault>((ref) {
  return FlutterSecurePrivateKeyVault(const FlutterSecureStorage());
});

final identityProvider = FutureProvider<IdentityLoad>((ref) async {
  final store = IdentityKeyStore(vault: ref.watch(privateKeyVaultProvider));
  try {
    return await store.loadOrCreate();
  } catch (error) {
    debugPrint('Identity key is unavailable (${error.runtimeType}).');
    rethrow;
  }
});

final userIdStoreProvider = Provider<UserIdStore>((ref) {
  return FlutterSecureUserIdStore(const FlutterSecureStorage());
});

final sessionProvider = FutureProvider<RegistrationResult>((ref) async {
  final identity = await ref.watch(identityProvider.future);
  final transport = ref.watch(transportProvider);
  final store = ref.watch(userIdStoreProvider);
  final stored = await store.read();
  if (transport is MockMessengerTransport &&
      stored != null &&
      userIdPattern.hasMatch(stored)) {
    transport.holdUserId(stored);
  }
  final result = await transport.registerDevice(
    _stubRegistration(identity.info),
  );
  if (!userIdPattern.hasMatch(result.userId)) {
    throw StateError('userId is not canonical');
  }
  if (stored != result.userId) {
    await store.write(result.userId);
  }
  return result;
});

String readLocalUserId(Ref ref) {
  return ref.read(sessionProvider).requireValue.userId;
}

class IntroVisible extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final identity = await ref.watch(identityProvider.future);
    return identity.freshlyCreated;
  }

  void dismiss() => state = const AsyncData(false);
}

final introVisibleProvider = AsyncNotifierProvider<IntroVisible, bool>(
  IntroVisible.new,
);

final attachmentPickerProvider = Provider<AttachmentPicker>((ref) {
  return DeviceAttachmentPicker();
});

final voiceRecorderProvider = Provider<VoiceRecorder>((ref) {
  final recorder = DeviceVoiceRecorder();
  ref.onDispose(recorder.dispose);
  return recorder;
});

final voicePlayerProvider = Provider<VoicePlayer>((ref) {
  final player = DeviceVoicePlayer();
  ref.onDispose(player.dispose);
  return player;
});

final neutralNotificationsProvider = Provider<NeutralNotifications>((ref) {
  return createNeutralNotifications();
});

final demoSeederProvider = Provider<DemoSeeder>((ref) {
  return DemoSeeder(
    repository: ref.watch(envelopeRepositoryProvider),
    cipher: ref.watch(sessionCipherProvider),
  );
});

class SelectedChat extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String chatId) => state = chatId;

  void clear() => state = null;
}

class DisplayNames extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  void rename(String chatId, String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    state = {...state, chatId: trimmed};
  }
}

final displayNamesProvider =
    NotifierProvider<DisplayNames, Map<String, String>>(DisplayNames.new);

/// Local per-chat flag. It does not change the mock envelope or the cipher.
class ExtraEncryption extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  bool enabled(String chatId) => state.contains(chatId);

  void toggle(String chatId) {
    final next = {...state};
    if (!next.add(chatId)) next.remove(chatId);
    state = next;
  }
}

final extraEncryptionProvider = NotifierProvider<ExtraEncryption, Set<String>>(
  ExtraEncryption.new,
);

String displayTitle(String chatId, Map<String, String> names) {
  final override = names[chatId];
  if (override != null && override.isNotEmpty) return override;
  return peerByChatIdOrNull(chatId)?.name ?? 'Собеседник';
}

final selectedChatProvider = NotifierProvider<SelectedChat, String?>(
  SelectedChat.new,
);

class ChatListNotifier extends AsyncNotifier<List<ChatSummary>> {
  @override
  Future<List<ChatSummary>> build() async {
    final preview = ref.watch(previewModeProvider);
    final names = ref.watch(displayNamesProvider);
    if (preview == PreviewMode.loading) {
      await Completer<void>().future;
    }
    if (preview == PreviewMode.error) {
      throw StateError('chat list failed');
    }
    if (preview == PreviewMode.empty) {
      return const [];
    }

    final repository = ref.watch(envelopeRepositoryProvider);
    if (ref.watch(seedDemoProvider)) {
      final userId = (await ref.watch(sessionProvider.future)).userId;
      await ref.read(demoSeederProvider).seedIfEmpty(userId);
    }
    return summarize(await repository.listAll(), names);
  }

  Future<void> deleteChat(String chatId) async {
    await ref.read(envelopeRepositoryProvider).deleteChat(chatId);
    if (ref.read(selectedChatProvider) == chatId) {
      ref.read(selectedChatProvider.notifier).clear();
    }
    ref.read(openThreadProvider.notifier).clearIf(chatId);
    ref.invalidateSelf();
  }
}

final chatListProvider =
    AsyncNotifierProvider<ChatListNotifier, List<ChatSummary>>(
      ChatListNotifier.new,
    );

List<ChatSummary> summarize(
  List<Envelope> envelopes,
  Map<String, String> names,
) {
  final latest = <String, Envelope>{};
  for (final envelope in envelopes) {
    final current = latest[envelope.chatId];
    if (current == null || envelope.createdAt.isAfter(current.createdAt)) {
      latest[envelope.chatId] = envelope;
    }
  }
  final summaries = <ChatSummary>[];
  for (final envelope in latest.values) {
    summaries.add(
      ChatSummary(
        chatId: envelope.chatId,
        title: displayTitle(envelope.chatId, names),
        updatedAt: envelope.createdAt,
        preview: neutralPreview,
      ),
    );
  }
  summaries.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return summaries;
}

class ThreadNotifier extends AsyncNotifier<List<DisplayMessage>> {
  ThreadNotifier(this.chatId);

  final String chatId;

  @override
  Future<List<DisplayMessage>> build() async {
    if (ref.watch(previewModeProvider) == PreviewMode.threadError) {
      throw StateError('thread failed');
    }
    final repository = ref.watch(envelopeRepositoryProvider);
    final cipher = ref.watch(sessionCipherProvider);
    return _decode(await repository.listAll(), cipher);
  }

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    await _sendPayload(trimmed);
  }

  Future<void> sendWallSmiley() => _sendPayload(wallSmileyPayload);

  Future<void> sendFile(PickedLocalFile file) {
    return _sendPayload(
      filePayload,
      attachment: LocalAttachment(
        kind: MockKind.file,
        name: file.name,
        bytes: file.bytes,
      ),
    );
  }

  Future<void> sendVoice(VoiceClip clip) {
    return _sendPayload(
      voicePayload,
      attachment: LocalAttachment(
        kind: MockKind.voice,
        bytes: clip.bytes,
        duration: clip.duration,
        mimeType: clip.mimeType,
      ),
    );
  }

  Future<void> _sendPayload(
    String payload, {
    LocalAttachment? attachment,
  }) async {
    final repository = ref.read(envelopeRepositoryProvider);
    final cipher = ref.read(sessionCipherProvider);
    final transport = ref.read(transportProvider);
    final sealed = await sealMessage(
      cipher,
      payload,
      extra: ref.read(extraEncryptionProvider).contains(chatId),
    );
    final outbound = Envelope(
      id: _newId(),
      chatId: chatId,
      sender: readLocalUserId(ref),
      createdAt: DateTime.now().toUtc(),
      ciphertext: base64Encode(sealed),
      status: EnvelopeStatus.pending,
    );
    if (attachment != null) {
      ref.read(localMediaProvider.notifier).put(outbound.id, attachment);
    }
    await repository.insert(outbound);
    final reply = await transport.send(outbound);
    await repository.updateStatus(outbound.id, EnvelopeStatus.sent);
    if (reply != null) {
      await ref
          .read(inboundHubProvider.notifier)
          .acceptInbound(reply, refreshOpenThread: false);
    }
    state = AsyncData(await _decode(await repository.listAll(), cipher));
    ref.invalidate(chatListProvider);
  }

  Future<void> editMessage(String id, String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    final repository = ref.read(envelopeRepositoryProvider);
    final cipher = ref.read(sessionCipherProvider);
    final sealed = await sealMessage(
      cipher,
      trimmed,
      extra: ref.read(extraEncryptionProvider).contains(chatId),
    );
    await repository.updateCiphertext(id, base64Encode(sealed));
    ref.read(localMediaProvider.notifier).remove(id);
    state = AsyncData(await _decode(await repository.listAll(), cipher));
  }

  Future<void> deleteMessage(String id) async {
    final repository = ref.read(envelopeRepositoryProvider);
    final cipher = ref.read(sessionCipherProvider);
    await repository.deleteById(id);
    ref.read(localMediaProvider.notifier).remove(id);
    state = AsyncData(await _decode(await repository.listAll(), cipher));
    ref.invalidate(chatListProvider);
  }

  Future<void> forwardTo(DisplayMessage message, String targetChatId) async {
    if (targetChatId == chatId) return;
    final repository = ref.read(envelopeRepositoryProvider);
    final cipher = ref.read(sessionCipherProvider);
    final sealed = await sealMessage(
      cipher,
      _payloadOf(message),
      extra: ref.read(extraEncryptionProvider).contains(targetChatId),
    );
    final copy = Envelope(
      id: _newId(),
      chatId: targetChatId,
      sender: readLocalUserId(ref),
      createdAt: DateTime.now().toUtc(),
      ciphertext: base64Encode(sealed),
      status: EnvelopeStatus.sent,
    );
    final media = ref.read(localMediaProvider)[message.envelope.id];
    if (media != null) {
      ref.read(localMediaProvider.notifier).put(copy.id, media);
    }
    await repository.insert(copy);
    ref.invalidate(chatListProvider);
    ref.invalidate(threadProvider(targetChatId));
  }

  Future<List<DisplayMessage>> _decode(
    List<Envelope> rows,
    SessionCipher cipher,
  ) async {
    final catalog = ref.read(localMediaProvider);
    final mine = rows.where((row) => row.chatId == chatId);
    final messages = <DisplayMessage>[];
    for (final envelope in mine) {
      final opened = await _openEnvelope(cipher, envelope);
      messages.add(
        _toDisplay(
          envelope,
          opened.text,
          catalog,
          extraLayer: opened.extraLayer,
        ),
      );
    }
    return messages;
  }
}

DisplayMessage _toDisplay(
  Envelope envelope,
  String plain,
  Map<String, LocalAttachment> catalog, {
  bool extraLayer = false,
}) {
  final media = catalog[envelope.id];
  if (plain == wallSmileyPayload) {
    return DisplayMessage(
      envelope: envelope,
      mockDisplayText: '',
      kind: MockKind.wallSmiley,
      extraLayer: extraLayer,
    );
  }
  if (plain == filePayload) {
    return DisplayMessage(
      envelope: envelope,
      mockDisplayText: '',
      kind: MockKind.file,
      mockFileName: media?.name ?? 'Файл',
      mockSizeBytes: media?.bytes?.length ?? 0,
      mockBytes: media?.bytes,
      extraLayer: extraLayer,
    );
  }
  if (plain == voicePayload) {
    return DisplayMessage(
      envelope: envelope,
      mockDisplayText: '',
      kind: MockKind.voice,
      mockDuration: media?.duration ?? Duration.zero,
      mockBytes: media?.bytes,
      mockMimeType: media?.mimeType,
      extraLayer: extraLayer,
    );
  }
  return DisplayMessage(
    envelope: envelope,
    mockDisplayText: plain,
    extraLayer: extraLayer,
  );
}

String _payloadOf(DisplayMessage message) {
  return switch (message.kind) {
    MockKind.wallSmiley => wallSmileyPayload,
    MockKind.file => filePayload,
    MockKind.voice => voicePayload,
    MockKind.text => message.mockDisplayText,
  };
}

class InboundHub extends Notifier<int> {
  @override
  int build() => 0;

  var _previewSent = false;

  Future<void> maybeAnnouncePreview() async {
    if (_previewSent || ref.read(previewModeProvider) != PreviewMode.notify) {
      return;
    }
    _previewSent = true;
    await announceFromPeer('chat-marina');
  }

  Future<void> announceFromPeer(String chatId) async {
    final cipher = ref.read(sessionCipherProvider);
    final encrypted = await cipher.encrypt(utf8.encode('Принято.'));
    final peer = peerByChatId(chatId);
    await acceptInbound(
      Envelope(
        id: _newId(),
        chatId: chatId,
        sender: peer.userId,
        createdAt: DateTime.now().toUtc(),
        ciphertext: base64Encode(encrypted),
        status: EnvelopeStatus.received,
      ),
    );
  }

  Future<void> acceptInbound(
    Envelope envelope, {
    bool refreshOpenThread = true,
  }) async {
    await ref.read(envelopeRepositoryProvider).insert(envelope);
    _consider(envelope);
    ref.invalidate(chatListProvider);
    if (refreshOpenThread && envelope.chatId == ref.read(openThreadProvider)) {
      ref.invalidate(threadProvider(envelope.chatId));
    }
    state++;
  }

  void _consider(Envelope envelope) {
    if (envelope.sender == readLocalUserId(ref)) return;
    if (envelope.chatId == ref.read(openThreadProvider)) return;
    final name = displayTitle(envelope.chatId, ref.read(displayNamesProvider));
    ref
        .read(noticeProvider.notifier)
        .show(InboundNotice(chatId: envelope.chatId, senderName: name));
    unawaited(ref.read(neutralNotificationsProvider).showNewMessage(name));
  }
}

final inboundHubProvider = NotifierProvider<InboundHub, int>(InboundHub.new);

final threadProvider =
    AsyncNotifierProvider.family<ThreadNotifier, List<DisplayMessage>, String>(
      ThreadNotifier.new,
    );

Future<OpenedMessage> _openEnvelope(
  SessionCipher cipher,
  Envelope envelope,
) async {
  try {
    return await openMessage(cipher, envelope.ciphertext);
  } on Object {
    return const OpenedMessage(text: neutralPreview, extraLayer: false);
  }
}

String _newId() {
  final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
  final salt = Random.secure().nextInt(1 << 30).toRadixString(16);
  return 'env_${now}_$salt';
}

DeviceRegistrationRequest _stubRegistration(IdentityPublicInfo identity) {
  // Placeholder prekeys only. These are not X3DH keys and not signatures.
  // libsignal must replace this builder before a real session starts.
  final random = Random.secure();
  String opaque(int length) =>
      base64Encode(List<int>.generate(length, (_) => random.nextInt(256)));
  return DeviceRegistrationRequest(
    registrationId: 1000 + random.nextInt(15000),
    identityPublicKey: identity.publicKeyBase64,
    signedPreKey: SignedPreKey(
      keyId: 1,
      publicKey: opaque(32),
      signature: opaque(64),
    ),
    oneTimePreKeys: [
      for (var id = 1; id <= 8; id++)
        OneTimePreKey(keyId: id, publicKey: opaque(32)),
    ],
  );
}
