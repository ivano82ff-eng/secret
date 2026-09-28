import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme.dart';

class ThemeToggle extends ConsumerWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final night = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      key: const Key('theme-switch'),
      tooltip: night ? 'Дневная тема' : 'Ночная тема',
      onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
      icon: Icon(night ? Icons.light_mode_outlined : Icons.dark_mode_outlined),
    );
  }
}
