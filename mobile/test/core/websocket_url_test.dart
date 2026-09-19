import 'package:flutter_test/flutter_test.dart';
import 'package:zennyt/core/network/websocket_service.dart';

void main() {
  test('the realtime endpoint follows the configured API host', () {
    expect(WebSocketService.websocketUrlFor('http://localhost:8080/api/v1'),
        'ws://localhost:8080/ws-engagement');
    expect(WebSocketService.websocketUrlFor('http://10.0.2.2:8080/api/v1/'),
        'ws://10.0.2.2:8080/ws-engagement');
    expect(WebSocketService.websocketUrlFor('https://api.zennyt.com/api/v1'),
        'wss://api.zennyt.com/ws-engagement');
  });
}
