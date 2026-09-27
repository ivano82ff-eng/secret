import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../directory/peers.dart';
import '../models/display_message.dart';
import '../models/envelope.dart';
import '../providers.dart';
import 'status_panel.dart';
import 'time_format.dart';
import 'theme_colors.dart';

class ConversationBody extends ConsumerStatefulWidget {
  const ConversationBody({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ConversationBody> createState() => _ConversationBodyState();
}

class _ConversationBodyState extends ConsumerState<ConversationBody> {
  final _controller = TextEditingController();
  var _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await ref.read(threadProvider(widget.chatId).notifier).send(text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось отправить сообщение.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final thread = ref.watch(threadProvider(widget.chatId));
    return Column(
      children: [
        Expanded(
          child: thread.when(
            skipLoadingOnReload: true,
            loading: () => const StatusPanel(
              icon: Icons.hourglass_top,
              title: 'Открываем диалог',
              body: 'Достаём конверты из локального кэша.',
            ),
            error: (error, stackTrace) => StatusPanel(
              icon: Icons.error_outline,
              title: 'Не удалось открыть диалог',
              body: 'История не прочиталась. Повторите попытку.',
              actionLabel: 'Повторить',
              onAction: () => ref.invalidate(threadProvider(widget.chatId)),
            ),
            data: (messages) {
              if (messages.isEmpty) {
                return const StatusPanel(
                  icon: Icons.chat_bubble_outline,
                  title: 'Напишите первое сообщение',
                  body: 'Оно сохранится как зашифрованный конверт. Ответ придёт локально, без сервера.',
                );
              }
              return ListView.builder(
                reverse: true,
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[messages.length - 1 - index];
                  return _Bubble(message: message);
                },
              );
            },
          ),
        ),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('composer'),
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _send(),
                    decoration: const InputDecoration(
                      hintText: 'Написать сообщение',
                      filled: true,
                      fillColor: Colors.white,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(24)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton.filled(
                  key: const Key('send'),
                  tooltip: 'Отправить',
                  onPressed: _sending ? null : _send,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final DisplayMessage message;

  @override
  Widget build(BuildContext context) {
    final outgoing = message.envelope.sender == localUserId;
    final status = switch (message.envelope.status) {
      EnvelopeStatus.pending => 'отправка',
      EnvelopeStatus.sent => 'отправлено',
      EnvelopeStatus.received => '',
    };
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          decoration: BoxDecoration(
            color: outgoing ? outgoingBubble : incomingBubble,
            borderRadius: BorderRadius.circular(18),
            border: outgoing
                ? null
                : Border.all(color: const Color(0xFFE4DDD2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message.mockDisplayText,
                  style: TextStyle(
                    color: outgoing ? Colors.white : const Color(0xFF1C1B19),
                    height: 1.35,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  formatChatTime(message.envelope.createdAt),
                  if (outgoing && status.isNotEmpty) status,
                ].join(' · '),
                style: TextStyle(
                  color: outgoing
                      ? const Color(0xFFD5E3DC)
                      : const Color(0xFF6E6A62),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
