import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/display_message.dart';
import '../models/envelope.dart';
import '../providers.dart';
import '../theme.dart';
import 'time_format.dart';
import 'wall_smiley.dart';

class MessageBubble extends ConsumerWidget {
  const MessageBubble({super.key, required this.message, this.onQuote});

  final DisplayMessage message;
  final ValueChanged<String>? onQuote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outgoing = message.envelope.sender == ref.watch(activeUserIdProvider);
    final status = switch (message.envelope.status) {
      EnvelopeStatus.pending => 'отправка',
      EnvelopeStatus.sent => 'отправлено',
      EnvelopeStatus.received => '',
    };
    final palette = SecretPalette.of(context);
    final ink = outgoing ? palette.outgoingInk : palette.incomingInk;
    final meta = outgoing ? palette.outgoingMeta : palette.incomingMeta;
    return Align(
      alignment: outgoing ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: EdgeInsets.fromLTRB(14, 10, outgoing ? 4 : 14, 8),
          decoration: BoxDecoration(
            color: outgoing ? palette.outgoing : palette.incoming,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: palette.night ? 0.28 : 0.06,
                ),
                blurRadius: 10,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _body(context, ref, ink),
                    ),
                  ),
                  if (outgoing)
                    _MessageActions(message: message, onQuote: onQuote),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (message.extraLayer)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Icon(
                        Icons.lock,
                        key: Key('bubble-lock-${message.envelope.id}'),
                        size: 14,
                        color: meta,
                      ),
                    ),
                  Text(
                    [
                      formatChatTime(message.envelope.createdAt),
                      if (outgoing && status.isNotEmpty) status,
                    ].join(' · '),
                    style: TextStyle(color: meta, fontSize: 12, height: 1.2),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, WidgetRef ref, Color ink) {
    return switch (message.kind) {
      MockKind.wallSmiley => const WallSmiley(size: 120),
      MockKind.file => _FileBody(message: message, ink: ink),
      MockKind.voice => _VoiceBody(message: message, ink: ink),
      MockKind.text => Text(
        message.mockDisplayText,
        style: TextStyle(color: ink, height: 1.35, fontSize: 20),
      ),
    };
  }
}

class _MessageActions extends ConsumerWidget {
  const _MessageActions({required this.message, required this.onQuote});

  final DisplayMessage message;
  final ValueChanged<String>? onQuote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meta = SecretPalette.of(context).outgoingMeta;
    return PopupMenuButton<String>(
      key: Key('message-actions-${message.envelope.id}'),
      tooltip: 'Действия с сообщением',
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_horiz, color: meta, size: 18),
      iconSize: 18,
      style: IconButton.styleFrom(
        minimumSize: const Size(28, 28),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      ),
      onSelected: (action) => _run(context, ref, action),
      itemBuilder: (context) => const [
        PopupMenuItem(value: 'edit', child: Text('Изменить')),
        PopupMenuItem(value: 'delete', child: Text('Удалить')),
        PopupMenuItem(value: 'copy', child: Text('Копировать')),
        PopupMenuItem(value: 'forward', child: Text('Переслать')),
        PopupMenuItem(value: 'quote', child: Text('Цитировать')),
      ],
    );
  }

  Future<void> _run(BuildContext context, WidgetRef ref, String action) async {
    final thread = ref.read(threadProvider(message.envelope.chatId).notifier);
    switch (action) {
      case 'edit':
        final next = await showDialog<String>(
          context: context,
          barrierDismissible: true,
          builder: (context) => _EditDialog(initial: _snippet(message)),
        );
        if (next == null) return;
        await thread.editMessage(message.envelope.id, next);
      case 'delete':
        await thread.deleteMessage(message.envelope.id);
      case 'copy':
        await Clipboard.setData(ClipboardData(text: _snippet(message)));
      case 'forward':
        final target = await _pickChat(context, ref, message.envelope.chatId);
        if (target == null) return;
        await thread.forwardTo(message, target);
      case 'quote':
        onQuote?.call(_snippet(message));
    }
  }
}

String _snippet(DisplayMessage message) {
  return switch (message.kind) {
    MockKind.text => message.mockDisplayText,
    MockKind.file => message.mockFileName ?? 'Файл',
    MockKind.voice => 'Голосовое',
    MockKind.wallSmiley => '',
  };
}

Future<String?> _pickChat(
  BuildContext context,
  WidgetRef ref,
  String currentChatId,
) {
  final chats =
      ref.read(chatListProvider).asData?.value ?? const <ChatSummary>[];
  final others = chats.where((chat) => chat.chatId != currentChatId).toList();
  return showDialog<String>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Переслать'),
        content: others.isEmpty
            ? const Text('Нет других переписок')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final chat in others)
                    ListTile(
                      key: Key('forward-${chat.chatId}'),
                      title: Text(chat.title),
                      onTap: () => Navigator.of(context).pop(chat.chatId),
                    ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Отмена'),
          ),
        ],
      );
    },
  );
}

class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.initial});

  final String initial;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
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
    final width = MediaQuery.sizeOf(context).width;
    final minWidth = width < 448
        ? (width - 80).clamp(0, 420).toDouble()
        : 420.0;
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      constraints: BoxConstraints(minWidth: minWidth, maxWidth: 560),
      title: const Text('Изменить'),
      content: TextField(
        key: const Key('edit-field'),
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.multiline,
        minLines: 1,
        maxLines: null,
        style: const TextStyle(fontSize: 20, height: 1.35),
        decoration: const InputDecoration(
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.all(16),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
        FilledButton(
          key: const Key('edit-save'),
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('Сохранить'),
        ),
      ],
    );
  }
}

class _FileBody extends StatelessWidget {
  const _FileBody({required this.message, required this.ink});

  final DisplayMessage message;
  final Color ink;

  @override
  Widget build(BuildContext context) {
    final muted = ink.withValues(alpha: 0.75);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.insert_drive_file_outlined, color: ink),
        const SizedBox(width: 10),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.mockFileName ?? 'Файл',
                key: const Key('file-bubble'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              Text(
                formatByteSize(message.mockSizeBytes ?? 0),
                style: TextStyle(color: muted, fontSize: 12),
              ),
              Text(
                'Только на этом устройстве',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VoiceBody extends ConsumerWidget {
  const _VoiceBody({required this.message, required this.ink});

  final DisplayMessage message;
  final Color ink;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final muted = ink.withValues(alpha: 0.75);
    final bytes = message.mockBytes;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Слушать',
          onPressed: bytes == null
              ? null
              : () {
                  ref
                      .read(voicePlayerProvider)
                      .play(
                        bytes,
                        mimeType: message.mockMimeType ?? 'audio/wav',
                      );
                },
          icon: Icon(Icons.play_arrow, color: ink),
        ),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Голосовое',
                key: const Key('voice-bubble'),
                style: TextStyle(
                  color: ink,
                  fontWeight: FontWeight.w600,
                  fontSize: 17,
                ),
              ),
              Text(
                formatVoiceDuration(message.mockDuration ?? Duration.zero),
                style: TextStyle(color: muted, fontSize: 12),
              ),
              Text(
                'Только на этом устройстве',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String formatByteSize(int size) {
  if (size < 1024) return '$size Б';
  if (size < 1024 * 1024) {
    return '${(size / 1024).toStringAsFixed(1)} КБ';
  }
  return '${(size / (1024 * 1024)).toStringAsFixed(1)} МБ';
}

String formatVoiceDuration(Duration duration) {
  final minutes = duration.inMinutes;
  final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$minutes:$seconds';
}
