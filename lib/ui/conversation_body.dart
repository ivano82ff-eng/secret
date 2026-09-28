import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media/voice_recorder.dart';
import '../providers.dart';
import 'message_bubble.dart';
import 'status_panel.dart';
import 'wall_smiley.dart';

class ConversationBody extends ConsumerStatefulWidget {
  const ConversationBody({super.key, required this.chatId});

  final String chatId;

  @override
  ConsumerState<ConversationBody> createState() => _ConversationBodyState();
}

class _ConversationBodyState extends ConsumerState<ConversationBody> {
  final _controller = TextEditingController();
  var _sending = false;
  var _pickerOpen = false;
  var _recording = false;
  String? _micError;

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
    } catch (error) {
      debugPrint('send failed (${error.runtimeType})');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось отправить сообщение.')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendSmiley() async {
    setState(() => _pickerOpen = false);
    try {
      await ref.read(threadProvider(widget.chatId).notifier).sendWallSmiley();
    } catch (error) {
      debugPrint('smiley failed (${error.runtimeType})');
    }
  }

  Future<void> _attach() async {
    final picked = await ref.read(attachmentPickerProvider).pick();
    if (picked == null || !mounted) return;
    try {
      await ref.read(threadProvider(widget.chatId).notifier).sendFile(picked);
    } catch (error) {
      debugPrint('file failed (${error.runtimeType})');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Не удалось прикрепить файл.')),
        );
      }
    }
  }

  Future<void> _mic() async {
    final recorder = ref.read(voiceRecorderProvider);
    if (_recording) {
      setState(() => _recording = false);
      try {
        final clip = await recorder.stop();
        if (!mounted) return;
        if (clip == null || clip.duration < const Duration(milliseconds: 400)) {
          setState(() => _micError = 'Слишком короткая запись.');
          return;
        }
        setState(() => _micError = null);
        await ref.read(threadProvider(widget.chatId).notifier).sendVoice(clip);
      } on MicrophoneDenied {
        if (mounted) {
          setState(
            () => _micError =
                'Нет доступа к микрофону. Остальная переписка работает.',
          );
        }
      } catch (error) {
        debugPrint('voice failed (${error.runtimeType})');
        if (mounted) {
          setState(
            () => _micError =
                'Не удалось записать голос. Остальная переписка работает.',
          );
        }
      }
      return;
    }

    try {
      await recorder.start();
      if (mounted) {
        setState(() {
          _recording = true;
          _micError = null;
        });
      }
    } on MicrophoneDenied {
      if (mounted) {
        setState(
          () => _micError =
              'Нет доступа к микрофону. Остальная переписка работает.',
        );
      }
    } catch (error) {
      debugPrint('mic failed (${error.runtimeType})');
      if (mounted) {
        setState(
          () => _micError =
              'Нет доступа к микрофону. Остальная переписка работает.',
        );
      }
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
                  return MessageBubble(message: message);
                },
              );
            },
          ),
        ),
        if (_pickerOpen) const Divider(height: 1),
        if (_pickerOpen)
          _EmojiPanel(controller: _controller, onSmiley: _sendSmiley),
        const Divider(height: 1),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
            child: Column(
              children: [
                if (_micError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                    child: Text(
                      _micError!,
                      key: const Key('mic-error'),
                      style: const TextStyle(color: Color(0xFF8C3A32)),
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      key: const Key('emoji-button'),
                      tooltip: 'Смайлики',
                      visualDensity: VisualDensity.compact,
                      onPressed: () =>
                          setState(() => _pickerOpen = !_pickerOpen),
                      icon: Icon(
                        _pickerOpen ? Icons.keyboard_alt_outlined : Icons.mood,
                      ),
                    ),
                    IconButton(
                      key: const Key('attach-file'),
                      tooltip: 'Прикрепить файл',
                      visualDensity: VisualDensity.compact,
                      onPressed: _attach,
                      icon: const Icon(Icons.attach_file),
                    ),
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
                    IconButton(
                      key: const Key('mic'),
                      tooltip: _recording ? 'Остановить запись' : 'Голосовое',
                      visualDensity: VisualDensity.compact,
                      color: _recording ? const Color(0xFF8C3A32) : null,
                      onPressed: _mic,
                      icon: Icon(
                        _recording ? Icons.stop_circle : Icons.mic_none,
                      ),
                    ),
                    IconButton.filled(
                      key: const Key('send'),
                      tooltip: 'Отправить',
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmojiPanel extends StatelessWidget {
  const _EmojiPanel({required this.controller, required this.onSmiley});

  final TextEditingController controller;
  final VoidCallback onSmiley;

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    final pickerHeight = height < 700 ? 180.0 : 230.0;
    return Material(
      color: const Color(0xFFFFFCF7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 84,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              children: [_WallSmileyButton(onPressed: onSmiley)],
            ),
          ),
          SizedBox(
            height: pickerHeight,
            child: EmojiPicker(
              textEditingController: controller,
              config: Config(
                height: pickerHeight,
                checkPlatformCompatibility: false,
                emojiViewConfig: const EmojiViewConfig(
                  backgroundColor: Color(0xFFFFFCF7),
                  columns: 8,
                ),
                categoryViewConfig: const CategoryViewConfig(
                  initCategory: Category.SMILEYS,
                  recentTabBehavior: RecentTabBehavior.NONE,
                  backgroundColor: Color(0xFFF6F3EC),
                  indicatorColor: Color(0xFF1B3A31),
                  iconColor: Color(0xFF6E6A62),
                  iconColorSelected: Color(0xFF1B3A31),
                  backspaceColor: Color(0xFF1B3A31),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WallSmileyButton extends StatelessWidget {
  const _WallSmileyButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        key: const Key('wall-smiley'),
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          width: 92,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF1B3A31)),
            color: const Color(0xFFFFF6D8),
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(child: WallSmiley(size: 46)),
              Text(
                'О стену',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
