import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret/app.dart';
import 'package:secret/crypto/mock_session_cipher.dart';
import 'package:secret/crypto/private_key_vault.dart';
import 'package:secret/data/app_database.dart';
import 'package:secret/data/envelope_repository.dart';
import 'package:secret/media/attachment_picker.dart';
import 'package:secret/media/voice_recorder.dart';
import 'package:secret/models/payload_markers.dart';
import 'package:secret/providers.dart';
import 'package:secret/transport/mock_messenger_transport.dart';
import 'package:secret/ui/wall_smiley.dart';

void main() {
  testWidgets('chat list shows the empty state', (tester) async {
    await _pumpApp(tester);
    expect(find.byKey(const Key('empty-chats')), findsOneWidget);
    expect(find.text('Пока нет переписок'), findsOneWidget);
    expect(find.text('Написать Алексею'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('sending appends the outbound text and a mock reply', (
    tester,
  ) async {
    await _pumpApp(tester);
    await tester.tap(find.text('Написать Алексею'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Напишите первое сообщение'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('composer')), 'Проверка связи');
    await tester.tap(find.byKey(const Key('send')));
    await _flush(tester);

    expect(find.text('Проверка связи'), findsOneWidget);
    expect(find.text('Принято.'), findsOneWidget);
    expect(find.textContaining('отправлено'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('first launch shows a copyable user id', (tester) async {
    _mockClipboard(tester);
    await _pumpApp(tester, storedIdentity: false);
    expect(find.byKey(const Key('user-id-value')), findsOneWidget);
    expect(find.text('user-local'), findsOneWidget);
    expect(
      find.textContaining('Идентификатор устройства — не адрес'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('copy-user-id')));
    await tester.pump();
    expect(await _readClipboard(tester), 'user-local');

    await tester.tap(find.byKey(const Key('enter-chats')));
    await _flush(tester);
    expect(find.text('Чаты'), findsOneWidget);
    expect(find.byKey(const Key('account-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('account-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('account-user-id')), findsOneWidget);
    await tester.tap(find.byKey(const Key('account-copy')));
    await tester.pump();
    expect(await _readClipboard(tester), 'user-local');
    await _unmount(tester);
  });

  testWidgets('a stored identity opens the chat list', (tester) async {
    await _pumpApp(tester);
    expect(find.byKey(const Key('user-id-value')), findsNothing);
    expect(find.text('Чаты'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('emoji picker inserts into the draft', (tester) async {
    await _pumpApp(tester);
    await _openAlexey(tester);
    await tester.tap(find.byKey(const Key('emoji-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('О стену'), findsOneWidget);
    expect(find.text('😀'), findsWidgets);
    await tester.tap(find.text('😀').first);
    await tester.pump();

    final field = tester.widget<TextField>(find.byKey(const Key('composer')));
    expect(field.controller?.text, contains('😀'));
    await _unmount(tester);
  });

  testWidgets('wall smiley plays in the bubble after reopen', (tester) async {
    final harness = await _pumpApp(tester);
    await _openAlexey(tester);
    await tester.tap(find.byKey(const Key('emoji-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byKey(const Key('wall-smiley')));
    await _flush(tester);

    expect(find.byType(WallSmiley), findsOneWidget);
    expect(find.text('О стену'), findsNothing);

    await _unmount(tester);
    await _pumpApp(tester, harness: harness);
    await tester.tap(find.byKey(const Key('chat-chat-alexey')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(WallSmiley), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('a file stays in a local bubble and off the envelope', (
    tester,
  ) async {
    final harness = await _pumpApp(
      tester,
      picker: _ScriptedPicker(
        PickedLocalFile(
          name: 'заметка.txt',
          bytes: Uint8List.fromList(const [9, 8, 7, 6]),
        ),
      ),
    );
    await _openAlexey(tester);
    await tester.tap(find.byKey(const Key('attach-file')));
    await _flush(tester);

    expect(find.byKey(const Key('file-bubble')), findsOneWidget);
    expect(find.text('заметка.txt'), findsOneWidget);
    expect(find.text('4 Б'), findsOneWidget);
    expect(find.text('Только на этом устройстве'), findsWidgets);

    final rows = await EnvelopeRepository(harness.database).listAll();
    final cipher = const MockSessionCipher();
    final plains = <String>[];
    for (final row in rows) {
      expect(row.toJson().keys, isNot(contains('filename')));
      final plain = utf8.decode(
        await cipher.decrypt(base64Decode(row.ciphertext)),
      );
      plains.add(plain);
      expect(plain.contains('заметка'), isFalse);
    }
    expect(plains, contains(filePayload));
    await _unmount(tester);
  });

  testWidgets('a voice message shows a playable bubble', (tester) async {
    final harness = await _pumpApp(tester, recorder: _ScriptedRecorder());
    await _openAlexey(tester);
    await tester.tap(find.byKey(const Key('mic')));
    await tester.pump();
    await tester.pump();
    await tester.tap(find.byKey(const Key('mic')));
    await _flush(tester);

    expect(find.byKey(const Key('voice-bubble')), findsOneWidget);
    expect(find.text('Голосовое'), findsOneWidget);
    expect(find.text('0:02'), findsOneWidget);
    expect(find.text('Только на этом устройстве'), findsWidgets);

    final rows = await EnvelopeRepository(harness.database).listAll();
    final cipher = const MockSessionCipher();
    final plains = <String>[];
    for (final row in rows) {
      final plain = utf8.decode(
        await cipher.decrypt(base64Decode(row.ciphertext)),
      );
      plains.add(plain);
    }
    expect(plains, contains(voicePayload));
    expect(plains.any((plain) => plain.contains('audio')), isFalse);
    await _unmount(tester);
  });

  testWidgets('mic denial stays in the chat', (tester) async {
    await _pumpApp(tester, recorder: _DeniedRecorder());
    await _openAlexey(tester);
    await tester.tap(find.byKey(const Key('mic')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('mic-error')), findsOneWidget);
    expect(find.textContaining('Нет доступа к микрофону'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('composer')), 'Текст жив');
    await tester.tap(find.byKey(const Key('send')));
    await _flush(tester);
    expect(find.text('Текст жив'), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('inbound banner names the sender and opens the thread', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final vault = _MemoryVault();
    await vault.writePrivateKey(await _identitySeed());
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(database),
        seedDemoProvider.overrideWithValue(false),
        previewModeProvider.overrideWithValue(PreviewMode.normal),
        privateKeyVaultProvider.overrideWithValue(vault),
        transportProvider.overrideWithValue(
          MockMessengerTransport(
            cipher: const MockSessionCipher(),
            replyDelay: Duration.zero,
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SecretApp()),
    );
    await _flush(tester);

    await container
        .read(inboundHubProvider.notifier)
        .announceFromPeer('chat-marina');
    await _flush(tester);

    expect(find.byKey(const Key('inbound-banner')), findsOneWidget);
    expect(find.text('Марина Соколова'), findsWidgets);
    expect(find.text('Новое сообщение'), findsOneWidget);
    expect(find.text('Принято.'), findsNothing);

    await tester.tap(find.byKey(const Key('inbound-banner')));
    await _flush(tester);
    expect(find.text('Принято.'), findsOneWidget);
    expect(find.byKey(const Key('inbound-banner')), findsNothing);
    await _unmount(tester);
  });
}

class _Harness {
  _Harness(this.database, this.vault);

  final AppDatabase database;
  final _MemoryVault vault;
}

Future<_Harness> _pumpApp(
  WidgetTester tester, {
  bool storedIdentity = true,
  AttachmentPicker? picker,
  VoiceRecorder? recorder,
  _Harness? harness,
}) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  final next =
      harness ?? _Harness(AppDatabase(NativeDatabase.memory()), _MemoryVault());
  if (harness == null) {
    addTearDown(next.database.close);
    if (storedIdentity) {
      await next.vault.writePrivateKey(await _identitySeed());
    }
  }
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(next.database),
        seedDemoProvider.overrideWithValue(false),
        previewModeProvider.overrideWithValue(PreviewMode.normal),
        privateKeyVaultProvider.overrideWithValue(next.vault),
        if (picker != null) attachmentPickerProvider.overrideWithValue(picker),
        if (recorder != null) voiceRecorderProvider.overrideWithValue(recorder),
        transportProvider.overrideWithValue(
          MockMessengerTransport(
            cipher: const MockSessionCipher(),
            replyDelay: Duration.zero,
          ),
        ),
      ],
      child: const SecretApp(),
    ),
  );
  await _flush(tester);
  return next;
}

Future<void> _openAlexey(WidgetTester tester) async {
  await tester.tap(find.text('Написать Алексею'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.binding.setSurfaceSize(null);
}

void _mockClipboard(WidgetTester tester) {
  final store = <String, String>{};
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (call) {
      switch (call.method) {
        case 'Clipboard.setData':
          store['text'] = (call.arguments as Map)['text'] as String;
          return SynchronousFuture<Object?>(null);
        case 'Clipboard.getData':
          return SynchronousFuture<Object?>(<String, dynamic>{
            'text': store['text'],
          });
        case 'Clipboard.hasStrings':
          return SynchronousFuture<Object?>(<String, dynamic>{
            'value': store.containsKey('text'),
          });
        default:
          return null;
      }
    },
  );
  addTearDown(() {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });
}

Future<String?> _readClipboard(WidgetTester tester) async {
  final pending = Clipboard.getData(Clipboard.kTextPlain);
  await tester.pump();
  return (await pending)?.text;
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<String> _identitySeed() async {
  final pair = await X25519().newKeyPair();
  return base64Encode(await pair.extractPrivateKeyBytes());
}

class _MemoryVault implements PrivateKeyVault {
  String? _stored;

  @override
  Future<String?> readPrivateKey() async => _stored;

  @override
  Future<void> writePrivateKey(String stored) async {
    _stored = stored;
  }
}

class _ScriptedPicker implements AttachmentPicker {
  _ScriptedPicker(this.file);

  final PickedLocalFile file;

  @override
  Future<PickedLocalFile?> pick() async => file;
}

class _ScriptedRecorder implements VoiceRecorder {
  @override
  Future<void> start() async {}

  @override
  Future<VoiceClip?> stop() async {
    return VoiceClip(
      bytes: Uint8List.fromList(const [1, 2, 3, 4]),
      duration: const Duration(seconds: 2),
      mimeType: 'audio/wav',
    );
  }

  @override
  Future<void> dispose() async {}
}

class _DeniedRecorder implements VoiceRecorder {
  @override
  Future<void> start() async => throw const MicrophoneDenied();

  @override
  Future<VoiceClip?> stop() async => null;

  @override
  Future<void> dispose() async {}
}
