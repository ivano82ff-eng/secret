import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'neutral_notifications.dart';

NeutralNotifications createPlatformNotifications() => WebNeutralNotifications();

class WebNeutralNotifications implements NeutralNotifications {
  @override
  Future<void> requestPermission() async {
    try {
      if (web.Notification.permission == 'granted') return;
      await web.Notification.requestPermission().toDart.timeout(
        const Duration(seconds: 3),
      );
    } on Object {
      // The page still shows the in-app banner if the browser refuses.
    }
  }

  @override
  Future<void> showNewMessage(String senderName) async {
    try {
      if (web.Notification.permission != 'granted') return;
      web.Notification(
        senderName,
        web.NotificationOptions(body: 'Новое сообщение', lang: 'ru'),
      );
    } on Object {
      // Ignore. The in-app banner is the reliable surface.
    }
  }
}
