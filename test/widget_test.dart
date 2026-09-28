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
import 'package:secret/ui/chat_wallpaper.dart';
import 'package:secret/ui/wall_smiley.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

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
    expect(find.byKey(const Key('settings-gear')), findsOneWidget);
    expect(find.byKey(const Key('account-button')), findsNothing);

    await tester.tap(find.byKey(const Key('settings-gear')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('gear-user-id')), findsOneWidget);
    expect(find.text('user-local'), findsWidgets);
    await tester.tap(find.byKey(const Key('gear-copy')));
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

    expect(find.byKey(const Key('wall-smiley')), findsOneWidget);
    expect(find.text('😀'), findsWidgets);
    await tester.tap(find.text('😀').first);
    await tester.pump();

    final field = tester.widget<TextField>(find.byKey(const Key('composer')));
    expect(field.controller?.text, contains('😀'));
    await _unmount(tester);
  });

  testWidgets('sending an emoji closes the picker', (tester) async {
    await _pumpApp(tester);
    await _openAlexey(tester);
    await tester.tap(find.byKey(const Key('emoji-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('emoji-panel')), findsOneWidget);

    await tester.tap(find.text('😀').first);
    await tester.pump();
    await tester.tap(find.byKey(const Key('send')));
    await _flush(tester);

    expect(find.byKey(const Key('emoji-panel')), findsNothing);
    expect(find.textContaining('😀'), findsWidgets);
    final field = tester.widget<TextField>(find.byKey(const Key('composer')));
    expect(field.focusNode?.hasFocus, isTrue);
    await _unmount(tester);
  });

  testWidgets('wallpaper is not an ancestor that spans the list', (
    tester,
  ) async {
    await _pumpApp(tester, seedDemo: true, size: const Size(1100, 800));
    await tester.tap(find.byKey(const Key('chat-chat-marina')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final list = find.byKey(const Key('chat-chat-marina'));
    final wallpaper = find.byType(ChatWallpaper);
    expect(wallpaper, findsOneWidget);
    expect(find.descendant(of: wallpaper, matching: list), findsNothing);

    var spansList = false;
    tester.element(list).visitAncestorElements((ancestor) {
      if (ancestor.widget is ChatWallpaper) spansList = true;
      return true;
    });
    expect(spansList, isFalse);

    final wallpaperRect = tester.getRect(wallpaper);
    final listRect = tester.getRect(list);
    expect(wallpaperRect.overlaps(listRect), isFalse);
    expect(wallpaperRect.left, greaterThanOrEqualTo(listRect.right - 1));
    expect(
      find.ancestor(
        of: find.byKey(const Key('thread-wallpaper')),
        matching: find.byType(ClipRect),
      ),
      findsWidgets,
    );
    await _unmount(tester);
  });

  testWidgets('edit dialog shows a long message and dismisses outside', (
    tester,
  ) async {
    const line = 'Видно целиком в окне правки.';
    final long = List.filled(8, line).join('\n');
    await _pumpApp(tester);
    await _openAlexey(tester);
    await tester.enterText(find.byKey(const Key('composer')), long);
    await tester.tap(find.byKey(const Key('send')));
    await _flush(tester);

    await tester.tap(find.byTooltip('Действия с сообщением'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Изменить'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final field = tester.widget<TextField>(find.byKey(const Key('edit-field')));
    expect(field.maxLines, isNull);
    expect(field.controller?.text, long);
    expect(
      tester.getSize(find.byKey(const Key('edit-field'))).height,
      greaterThan(180),
    );

    await tester.tapAt(const Offset(8, 8));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('edit-field')), findsNothing);
    expect(find.textContaining(line), findsWidgets);
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

  testWidgets('add button stays on the list and both themes build', (
    tester,
  ) async {
    await _pumpApp(tester);
    expect(find.byKey(const Key('add-person')), findsOneWidget);
    expect(find.byKey(const Key('settings-gear')), findsOneWidget);
    expect(find.byKey(const Key('theme-switch')), findsNothing);
    expect(
      Theme.of(tester.element(find.text('Чаты'))).brightness,
      Brightness.light,
    );

    await tester.tap(find.byKey(const Key('add-person')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('empty-chats')), findsOneWidget);
    expect(find.text('Чаты'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byKey(const Key('settings-gear')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('theme-switch')), findsOneWidget);
    expect(find.byKey(const Key('gear-user-id')), findsOneWidget);
    expect(find.text('user-local'), findsWidgets);

    await tester.tap(find.byKey(const Key('theme-switch')));
    await _flush(tester);
    expect(
      Theme.of(tester.element(find.text('Чаты'))).brightness,
      Brightness.dark,
    );
    expect(find.byKey(const Key('empty-chats')), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);

    await tester.tap(find.byKey(const Key('settings-gear')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byKey(const Key('theme-switch')));
    await _flush(tester);
    expect(
      Theme.of(tester.element(find.text('Чаты'))).brightness,
      Brightness.light,
    );
    await _unmount(tester);
  });

  testWidgets('wall smiley hides when another emoji filter is active', (
    tester,
  ) async {
    await _pumpApp(tester);
    await _openAlexey(tester);
    await tester.tap(find.byKey(const Key('emoji-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('wall-smiley')), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pets));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('wall-smiley')), findsNothing);
    expect(find.byIcon(Icons.pets), findsOneWidget);
    await _unmount(tester);
  });

  testWidgets('switching chats closes the emoji picker', (tester) async {
    await _pumpApp(tester, seedDemo: true, size: const Size(1100, 800));
    await tester.tap(find.byKey(const Key('chat-chat-marina')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('emoji-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const Key('emoji-panel')), findsOneWidget);
    expect(find.byKey(const Key('wall-smiley')), findsOneWidget);

    await tester.tap(find.byKey(const Key('chat-chat-ilya')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byKey(const Key('emoji-panel')), findsNothing);
    expect(find.byKey(const Key('wall-smiley')), findsNothing);
    final field = tester.widget<TextField>(find.byKey(const Key('composer')));
    expect(field.focusNode?.hasFocus, isTrue);
    await _unmount(tester);
  });

  testWidgets('rename changes the chat list label', (tester) async {
    await _pumpApp(tester, seedDemo: true);
    expect(find.text('Марина Соколова'), findsOneWidget);
    await tester.tap(find.byKey(const Key('chat-menu-chat-marina')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Переименовать'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.enterText(find.byKey(const Key('rename-field')), 'Маша');
    await tester.tap(find.byKey(const Key('rename-save')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Маша'), findsOneWidget);
    expect(find.text('Марина Соколова'), findsNothing);
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
  bool seedDemo = false,
  Size size = const Size(390, 844),
  AttachmentPicker? picker,
  VoiceRecorder? recorder,
  _Harness? harness,
}) async {
  await tester.binding.setSurfaceSize(size);
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
        seedDemoProvider.overrideWithValue(seedDemo),
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
