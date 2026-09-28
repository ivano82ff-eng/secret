import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../theme.dart';
import 'auth_screen.dart';

enum _GearAction { theme, wallpaper, copy }

class SettingsMenu extends ConsumerWidget {
  const SettingsMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider);
    final userId = session.asData?.value.userId;
    final night = Theme.of(context).brightness == Brightness.dark;
    return PopupMenuButton<_GearAction>(
      key: const Key('settings-gear'),
      tooltip: 'Настройки',
      icon: const Icon(Icons.settings_outlined),
      onSelected: (action) {
        switch (action) {
          case _GearAction.theme:
            ref.read(themeModeProvider.notifier).toggle();
          case _GearAction.wallpaper:
            _pickWallpaper(context, ref);
          case _GearAction.copy:
            if (userId != null) copyUserId(context, userId);
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          key: const Key('theme-switch'),
          value: _GearAction.theme,
          child: Row(
            children: [
              Icon(
                night ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              ),
              const SizedBox(width: 12),
              Text(night ? 'Дневная тема' : 'Ночная тема'),
            ],
          ),
        ),
        const PopupMenuItem(
          key: Key('wallpaper-switch'),
          value: _GearAction.wallpaper,
          child: Row(
            children: [
              Icon(Icons.wallpaper_outlined),
              SizedBox(width: 12),
              Text('Смена фона'),
            ],
          ),
        ),
        if (userId != null)
          PopupMenuItem(
            enabled: false,
            child: Text(userId, key: const Key('gear-user-id')),
          ),
        if (userId != null)
          PopupMenuItem(
            key: const Key('gear-copy'),
            value: _GearAction.copy,
            child: const Text('Скопировать идентификатор'),
          ),
      ],
    );
  }
}

Future<void> _pickWallpaper(BuildContext context, WidgetRef ref) {
  final current = ref.read(wallpaperProvider);
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      key: const Key('wallpaper-dialog'),
      title: const Text('Смена фона'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final choice in ThreadWallpaper.values)
            ListTile(
              key: Key('wallpaper-choice-${choice.name}'),
              leading: Icon(
                choice == current
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(choice.label),
              onTap: () {
                ref.read(wallpaperProvider.notifier).select(choice);
                Navigator.of(context).pop();
              },
            ),
        ],
      ),
    ),
  );
}
