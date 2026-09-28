import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'theme.dart';
import 'ui/auth_screen.dart';
import 'ui/home_shell.dart';
import 'ui/status_panel.dart';

class SecretApp extends ConsumerWidget {
  const SecretApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Секрет',
      debugShowCheckedModeBanner: false,
      theme: secretTheme(),
      locale: const Locale('ru'),
      supportedLocales: const [Locale('ru')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intro = ref.watch(introVisibleProvider);
    final session = ref.watch(sessionProvider);
    if (intro.isLoading || session.isLoading) {
      return const Scaffold(
        body: StatusPanel(
          icon: Icons.lock_outline,
          title: 'Готовим идентификатор',
          body: 'Создаём ключ устройства и регистрируем его локально.',
        ),
      );
    }
    if (intro.hasError || session.hasError) {
      return Scaffold(
        body: StatusPanel(
          icon: Icons.error_outline,
          title: 'Не удалось получить идентификатор',
          body: 'Ключ не сохранился. Повторите попытку. Пароль не нужен.',
          actionLabel: 'Повторить',
          onAction: () {
            ref.invalidate(identityProvider);
            ref.invalidate(sessionProvider);
            ref.invalidate(introVisibleProvider);
          },
        ),
      );
    }
    if (intro.requireValue) {
      return AuthScreen(
        userId: session.requireValue.userId,
        onContinue: () => ref.read(introVisibleProvider.notifier).dismiss(),
      );
    }
    return const MessengerHome();
  }
}
