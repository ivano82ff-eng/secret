import 'neutral_notifications.dart';

NeutralNotifications createPlatformNotifications() =>
    const StubNeutralNotifications();

class StubNeutralNotifications implements NeutralNotifications {
  const StubNeutralNotifications();

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> showNewMessage(String senderName) async {}
}
