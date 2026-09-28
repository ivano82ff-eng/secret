import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:emoji_picker_flutter/locales/default_emoji_set_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media/voice_recorder.dart';
import '../providers.dart';
import '../theme.dart';
import 'chat_wallpaper.dart';
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
  final _focus = FocusNode();
  var _sending = false;
  var _pickerOpen = false;
  var _recording = false;
  String? _micError;

  @override
  void didUpdateWidget(ConversationBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.chatId == widget.chatId) return;
    _pickerOpen = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _showTextComposer() {
    _pickerOpen = false;
    _recording = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focus.requestFocus();
    });
  }

  void _quote(String snippet) {
    _controller.value = TextEditingValue(
      text: snippet,
      selection: TextSelection.collapsed(offset: snippet.length),
    );
    _focus.requestFocus();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _pickerOpen = false;
    });
    _controller.clear();
    try {
      await ref.read(threadProvider(widget.chatId).notifier).send(text);
      if (mounted) setState(_showTextComposer);
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
      if (mounted) setState(_showTextComposer);
    } catch (error) {
      debugPrint('smiley failed (${error.runtimeType})');
    }
  }

  Future<void> _attach() async {
    final picked = await ref.read(attachmentPickerProvider).pick();
    if (picked == null || !mounted) return;
    try {
      await ref.read(threadProvider(widget.chatId).notifier).sendFile(picked);
      if (mounted) setState(_showTextComposer);
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
        if (mounted) setState(_showTextComposer);
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
    final palette = SecretPalette.of(context);
    final locked = ref.watch(extraEncryptionProvider).contains(widget.chatId);
    return Column(
      children: [
        Expanded(
          child: ClipRect(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                ChatWallpaper(locked: locked),
                thread.when(
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
                    onAction: () =>
                        ref.invalidate(threadProvider(widget.chatId)),
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
                        return MessageBubble(message: message, onQuote: _quote);
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (_pickerOpen)
          Divider(height: 1, color: palette.quiet.withValues(alpha: 0.2)),
        if (_pickerOpen)
          _EmojiPanel(
            key: const Key('emoji-panel'),
            controller: _controller,
            onSmiley: _sendSmiley,
          ),
        Divider(height: 1, color: palette.quiet.withValues(alpha: 0.2)),
        Material(
          color: palette.composer,
          child: SafeArea(
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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
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
                          _pickerOpen
                              ? Icons.keyboard_alt_outlined
                              : Icons.mood,
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
                          focusNode: _focus,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _send(),
                          style: TextStyle(
                            fontSize: 17,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Написать сообщение',
                            filled: true,
                            fillColor: palette.field,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: const OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(24),
                              ),
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
        ),
      ],
    );
  }
}

List<CategoryEmoji> _compactEmojiSet(Locale locale) {
  final source = getDefaultEmojiLocale(locale);
  return [
    for (final category in source)
      if (category.category == Category.SMILEYS)
        CategoryEmoji(category.category, [
          const Emoji('\u2060', 'wall'),
          ...category.emoji,
        ])
      else
        category,
  ];
}

class _EmojiPanel extends StatefulWidget {
  const _EmojiPanel({
    super.key,
    required this.controller,
    required this.onSmiley,
  });

  final TextEditingController controller;
  final VoidCallback onSmiley;

  @override
  State<_EmojiPanel> createState() => _EmojiPanelState();
}

class _EmojiPanelState extends State<_EmojiPanel> {
  static const _columns = 8;
  static const _tabHeight = 36.0;

  final _category = ValueNotifier<Category>(Category.SMILEYS);
  var _gridOffset = 0.0;

  @override
  void dispose() {
    _category.dispose();
    super.dispose();
  }

  bool _onGridScroll(ScrollNotification notification) {
    if (notification.metrics.axis != Axis.vertical) return false;
    final next = notification.metrics.pixels;
    if ((next - _gridOffset).abs() < 0.5) return false;
    setState(() => _gridOffset = next);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final palette = SecretPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final height = MediaQuery.sizeOf(context).height;
    final pickerHeight = height < 700 ? 220.0 : 248.0;
    return Material(
      color: palette.composer,
      child: Align(
        alignment: Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 392),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cell = constraints.maxWidth / _columns;
              return NotificationListener<ScrollNotification>(
                onNotification: _onGridScroll,
                child: SizedBox(
                  height: pickerHeight,
                  child: Stack(
                    clipBehavior: Clip.hardEdge,
                    children: [
                      EmojiPicker(
                        textEditingController: widget.controller,
                        onCategoryChanged: (category) {
                          if (!mounted || _category.value == category) return;
                          _category.value = category;
                        },
                        config: Config(
                          height: pickerHeight,
                          checkPlatformCompatibility: false,
                          emojiSet: _compactEmojiSet,
                          emojiViewConfig: EmojiViewConfig(
                            backgroundColor: palette.composer,
                            columns: _columns,
                            emojiSizeMax: 28,
                            verticalSpacing: 0,
                            horizontalSpacing: 0,
                            gridPadding: EdgeInsets.zero,
                            buttonMode: ButtonMode.NONE,
                          ),
                          categoryViewConfig: CategoryViewConfig(
                            tabBarHeight: _tabHeight,
                            initCategory: Category.SMILEYS,
                            recentTabBehavior: RecentTabBehavior.NONE,
                            backgroundColor: palette.composer,
                            indicatorColor: scheme.primary,
                            iconColor: palette.quiet,
                            iconColorSelected: scheme.primary,
                            backspaceColor: scheme.primary,
                            dividerColor: palette.quiet.withValues(alpha: 0.2),
                          ),
                          bottomActionBarConfig: const BottomActionBarConfig(
                            enabled: false,
                          ),
                        ),
                      ),
                      ValueListenableBuilder<Category>(
                        valueListenable: _category,
                        builder: (context, category, _) {
                          if (category != Category.SMILEYS) {
                            return const SizedBox.shrink();
                          }
                          return Positioned(
                            left: 0,
                            top: _tabHeight,
                            width: cell,
                            height: cell,
                            child: ClipRect(
                              child: Transform.translate(
                                offset: Offset(0, -_gridOffset),
                                child: _WallSmileyCell(
                                  extent: cell,
                                  color: palette.composer,
                                  onPressed: widget.onSmiley,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WallSmileyCell extends StatelessWidget {
  const _WallSmileyCell({
    required this.extent,
    required this.color,
    required this.onPressed,
  });

  final double extent;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'О стену',
      child: Material(
        color: color,
        child: InkWell(
          key: const Key('wall-smiley'),
          onTap: onPressed,
          child: Center(child: WallSmiley(size: extent * 0.78)),
        ),
      ),
    );
  }
}
