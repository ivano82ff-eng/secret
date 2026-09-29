import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

Future<WebSocketChannel> openAuthenticatedWebSocket(
  Uri uri,
  String accessToken,
) async {
  final channel = WebSocketChannel.connect(uri);
  channel.sink.add(
    jsonEncode({'type': 'auth', 'accessToken': accessToken}),
  );
  return channel;
}
