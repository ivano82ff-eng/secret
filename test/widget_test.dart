import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:secret/app.dart';
import 'package:secret/crypto/mock_session_cipher.dart';
import 'package:secret/crypto/private_key_vault.dart';
import 'package:secret/data/app_database.dart';
import 'package:secret/providers.dart';
import 'package:secret/transport/mock_messenger_transport.dart';

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
}

Future<void> _pumpApp(WidgetTester tester) async {
  final database = AppDatabase(NativeDatabase.memory());
  addTearDown(database.close);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(database),
        seedDemoProvider.overrideWithValue(false),
        previewModeProvider.overrideWithValue(PreviewMode.normal),
        privateKeyVaultProvider.overrideWithValue(_MemoryVault()),
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
}

Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
}

Future<void> _flush(WidgetTester tester) async {
  for (var i = 0; i < 12; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
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
