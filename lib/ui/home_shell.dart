import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers.dart';
import '../session/notices.dart';
import '../theme.dart';
import 'chat_list_body.dart';
import 'conversation_body.dart';
import 'inbound_banner.dart';
import 'safety_number_screen.dart';
import 'settings_menu.dart';

const wideBreakpoint = 840.0;

class MessengerHome extends ConsumerWidget {
  const MessengerHome({super.key});

  void _open(
    BuildContext context,
    WidgetRef ref,
    String chatId, {
    required bool wide,
  }) {
    ref.read(selectedChatProvider.notifier).select(chatId);
    ref.read(openThreadProvider.notifier).set(chatId);
    if (wide) return;
    unawaited(
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (context) => ConversationScreen(chatId: chatId),
            ),
          )
          .then((_) {
            if (!context.mounted) return;
            ref.read(openThreadProvider.notifier).clearIf(chatId);
          }),
    );
  }

  void _openSafety(BuildContext context, WidgetRef ref, String chatId) {
    final name = displayTitle(chatId, ref.read(displayNamesProvider));
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => SafetyNumberScreen(peerName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedChatProvider);
    final notice = ref.watch(noticeProvider);
    return StartupTasks(
      child: SafeArea(
        child: Column(
          children: [
            if (notice != null)
              InboundBanner(
                notice: notice,
                onDismiss: () => ref.read(noticeProvider.notifier).dismiss(),
                onOpen: () {
                  final chatId = notice.chatId;
                  ref.read(noticeProvider.notifier).dismiss();
                  _open(
                    context,
                    ref,
                    chatId,
                    wide: MediaQuery.sizeOf(context).width >= wideBreakpoint,
                  );
                },
              ),
            Expanded(child: _scaffold(context, ref, selected)),
          ],
        ),
      ),
    );
  }

  Widget _scaffold(BuildContext context, WidgetRef ref, String? selected) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= wideBreakpoint;
        final listColor = SecretPalette.of(context).listSurface;
        final names = ref.watch(displayNamesProvider);
        if (!wide) {
          return Scaffold(
            backgroundColor: listColor,
            appBar: AppBar(
              backgroundColor: listColor,
              title: const Text('Чаты'),
              actions: const [_AddPersonButton(), SettingsMenu()],
            ),
            body: ChatListBody(
              onOpen: (chatId) => _open(context, ref, chatId, wide: wide),
            ),
          );
        }
        final title = selected == null
            ? null
            : displayTitle(selected, names);
        return Scaffold(
          body: SafeArea(
            child: Row(
              children: [
                Material(
                  color: listColor,
                  child: SizedBox(
                    width: 380,
                    child: Column(
                      children: [
                        const _PaneHeader(
                          title: 'Чаты',
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [_AddPersonButton(), SettingsMenu()],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: ChatListBody(
                            selectedChatId: selected,
                            onOpen: (chatId) =>
                              _open(context, ref, chatId, wide: wide),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(
                  child: selected == null
                      ? const StatusPlaceholder()
                      : Column(
                          children: [
                            _PaneHeader(
                              title: title!,
                              trailing: IconButton(
                                tooltip: 'Число безопасности',
                                onPressed: () =>
                                    _openSafety(context, ref, selected),
                                icon: const Icon(Icons.verified_user_outlined),
                              ),
                            ),
                            const Divider(height: 1),
                            Expanded(child: ConversationBody(chatId: selected)),
                          ],
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ConversationScreen extends ConsumerWidget {
  const ConversationScreen({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = displayTitle(chatId, ref.watch(displayNamesProvider));
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Число безопасности',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (context) => SafetyNumberScreen(peerName: title),
                ),
              );
            },
            icon: const Icon(Icons.verified_user_outlined),
          ),
        ],
      ),
      body: ConversationBody(chatId: chatId),
    );
  }
}

class StatusPlaceholder extends StatelessWidget {
  const StatusPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Выберите переписку',
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _PaneHeader extends StatelessWidget {
  const _PaneHeader({required this.title, required this.trailing});

  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).appBarTheme.titleTextStyle,
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

class StartupTasks extends ConsumerStatefulWidget {
  const StartupTasks({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<StartupTasks> createState() => _StartupTasksState();
}

class _StartupTasksState extends ConsumerState<StartupTasks> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(ref.read(neutralNotificationsProvider).requestPermission());
      unawaited(ref.read(inboundHubProvider.notifier).maybeAnnouncePreview());
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _AddPersonButton extends StatelessWidget {
  const _AddPersonButton();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: IconButton.filled(
        key: const Key('add-person'),
        tooltip: 'Добавить',
        onPressed: () {},
        style: IconButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(40, 40),
        ),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

