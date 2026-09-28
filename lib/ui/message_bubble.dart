import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../directory/peers.dart';
import '../models/display_message.dart';
import '../models/envelope.dart';
import '../providers.dart';
import 'time_format.dart';
import 'theme_colors.dart';
import 'wall_smiley.dart';

class MessageBubble extends ConsumerWidget {
  const MessageBubble({super.key, required this.message});

  final DisplayMessage message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outgoing = message.envelope.sender == localUserId;
    final status = switch (message.envelope.status) {
      EnvelopeStatus.pending => 'отправка',
      EnvelopeStatus.sent => 'отправлено',
      EnvelopeStatus.received => '',
    };
    final ink = outgoing ? Colors.white : const Color(0xFF1C1B19);
    final meta = outgoing ? const Color(0xFFD5E3DC) : const Color(0xFF6E6A62);
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
                child: _body(context, ref, ink),
              ),
              const SizedBox(height: 4),
              Text(
                [
                  formatChatTime(message.envelope.createdAt),
                  if (outgoing && status.isNotEmpty) status,
                ].join(' · '),
                style: TextStyle(color: meta, fontSize: 11),
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
        style: TextStyle(color: ink, height: 1.35, fontSize: 16),
      ),
    };
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
                style: TextStyle(color: ink, fontWeight: FontWeight.w600),
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
                style: TextStyle(color: ink, fontWeight: FontWeight.w600),
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
