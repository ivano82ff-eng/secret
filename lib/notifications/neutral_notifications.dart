import 'neutral_notifications_stub.dart'
    if (dart.library.html) 'neutral_notifications_web.dart';

/// Local notification with a sender name and the neutral text
/// «Новое сообщение». No message body, no push token.
abstract interface class NeutralNotifications {
  Future<void> requestPermission();

  Future<void> showNewMessage(String senderName);
}

NeutralNotifications createNeutralNotifications() =>
    createPlatformNotifications();
