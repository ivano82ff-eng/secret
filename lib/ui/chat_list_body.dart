import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../directory/peers.dart';
import '../providers.dart';
import '../theme.dart';
import 'status_panel.dart';
import 'time_format.dart';

class ChatListBody extends ConsumerWidget {
  const ChatListBody({super.key, required this.onOpen, this.selectedChatId});

  final void Function(String chatId) onOpen;
  final String? selectedChatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chats = ref.watch(chatListProvider);
    return chats.when(
      skipLoadingOnReload: true,
      loading: () => const StatusPanel(
        icon: Icons.hourglass_top,
        title: 'Загружаем переписки',
        body: 'Читаем локальный кэш конвертов.',
      ),
      error: (error, stackTrace) => StatusPanel(
        icon: Icons.cloud_off,
        title: 'Не удалось загрузить переписки',
        body: 'Список остался на этом устройстве. Повторите попытку.',
        actionLabel: 'Повторить',
        onAction: () => ref.invalidate(chatListProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return StatusPanel(
            key: const Key('empty-chats'),
            icon: Icons.lock_outline,
            title: 'Пока нет переписок',
            body: 'Когда появится диалог, здесь будут имя, время и пометка «Сообщение». Текст в списке не показывается.',
            actionLabel: 'Написать Алексею',
            onAction: () => onOpen(alexeyChatId),
          );
        }
        return ListView.separated(
          itemCount: items.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final chat = items[index];
            final selected = chat.chatId == selectedChatId;
            final palette = SecretPalette.of(context);
            final extra = ref
                .watch(extraEncryptionProvider)
                .contains(chat.chatId);
            return ListTile(
              key: Key('chat-${chat.chatId}'),
              selected: selected,
              tileColor: extra ? palette.extraRow(selected: false) : null,
              selectedTileColor: extra
                  ? palette.extraRow(selected: true)
                  : palette.outgoing.withValues(alpha: 0.55),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: Text(chat.title.isEmpty ? '?' : chat.title[0]),
              ),
              title: Row(
                children: [
                  if (extra) ...[
                    Icon(
                      Icons.lock,
                      key: Key('chat-lock-${chat.chatId}'),
                      size: 16,
                      color: palette.lockedInk,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      chat.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              subtitle: Text(
                chat.preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    formatChatTime(chat.updatedAt),
                    style: TextStyle(color: palette.quiet, fontSize: 12),
                  ),
                  PopupMenuButton<String>(
                    key: Key('chat-menu-${chat.chatId}'),
                    tooltip: 'Действия с чатом',
                    padding: EdgeInsets.zero,
                    iconSize: 20,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    onSelected: (action) {
                      if (action == 'rename') {
                        _renameChat(context, ref, chat.chatId, chat.title);
                      } else if (action == 'delete') {
                        ref
                            .read(chatListProvider.notifier)
                            .deleteChat(chat.chatId);
                      } else if (action == 'extra') {
                        ref
                            .read(extraEncryptionProvider.notifier)
                            .toggle(chat.chatId);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Переименовать'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Удалить'),
                      ),
                      CheckedPopupMenuItem(
                        key: Key('extra-encryption-${chat.chatId}'),
                        value: 'extra',
                        checked: extra,
                        child: const Text('Дополнительное шифрование'),
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () => onOpen(chat.chatId),
            );
          },
        );
      },
    );
  }
}

Future<void> _renameChat(
  BuildContext context,
  WidgetRef ref,
  String chatId,
  String current,
) async {
  final next = await showDialog<String>(
    context: context,
    builder: (context) => _RenameDialog(initial: current),
  );
  if (next == null) return;
  ref.read(displayNamesProvider.notifier).rename(chatId, next);
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.initial});

  final String initial;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Переименовать'),
      content: TextField(
        key: const Key('rename-field'),
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        TextButton(
          key: const Key('rename-save'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}
