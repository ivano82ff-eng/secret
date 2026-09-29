import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

Future<WebSocketChannel> openAuthenticatedWebSocket(
  Uri uri,
  String accessToken,
) async {
  return IOWebSocketChannel.connect(
    uri,
    headers: {'Authorization': 'Bearer $accessToken'},
  );
}
