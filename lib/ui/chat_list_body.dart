import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../directory/peers.dart';
import '../providers.dart';
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
            return ListTile(
              key: Key('chat-${chat.chatId}'),
              selected: selected,
              selectedTileColor: const Color(0xFFE7EFEA),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 6,
              ),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFF1B3A31),
                foregroundColor: Colors.white,
                child: Text(peerByChatIdOrNull(chat.chatId)?.initial ?? '?'),
              ),
              title: Text(
                chat.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                chat.preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              trailing: Text(
                formatChatTime(chat.updatedAt),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              onTap: () => onOpen(chat.chatId),
            );
          },
        );
      },
    );
  }
}
