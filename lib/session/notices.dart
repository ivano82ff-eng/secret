import 'package:flutter_riverpod/flutter_riverpod.dart';

class InboundNotice {
  const InboundNotice({required this.chatId, required this.senderName});

  final String chatId;
  final String senderName;
}

class NoticeController extends Notifier<InboundNotice?> {
  @override
  InboundNotice? build() => null;

  void show(InboundNotice notice) => state = notice;

  void dismiss() => state = null;
}

final noticeProvider = NotifierProvider<NoticeController, InboundNotice?>(
  NoticeController.new,
);

class OpenThread extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String chatId) => state = chatId;

  void clearIf(String chatId) {
    if (state == chatId) state = null;
  }
}

final openThreadProvider = NotifierProvider<OpenThread, String?>(
  OpenThread.new,
);
