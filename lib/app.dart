import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'theme.dart';
import 'ui/home_shell.dart';

class SecretApp extends ConsumerWidget {
  const SecretApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(identityProvider);
    ref.watch(sessionProvider);
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
      home: const MessengerHome(),
    );
  }
}
