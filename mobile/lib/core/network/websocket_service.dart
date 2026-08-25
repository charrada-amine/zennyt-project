import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../config/app_config.dart';
import '../storage/token_storage.dart';

class WebSocketService with WidgetsBindingObserver {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;

  WebSocketService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  StompClient? _client;
  Timer? _timer;
  String? _userId;
  int _attempt = 0;
  bool _manualClose = false;

  final Map<String, Function(Map<String, dynamic>)> _handlers = {};
  final Map<String, StompUnsubscribe> _subs = {};

  String _buildUrl() {
    final base = AppConfig.baseUrl;
    if (base.isNotEmpty) {
      try {
        if (base.startsWith('/')) {
          if (kIsWeb) {
            final o = Uri.parse(Uri.base.origin);
            final scheme = o.scheme == 'https' ? 'wss' : 'ws';
            final port = o.hasPort ? ':${o.port}' : '';
            return '$scheme://${o.host}$port/ws-engagement';
          }
        } else {
          final u = Uri.parse(base);
          if (u.hasAuthority) {
            final scheme = u.scheme == 'https' ? 'wss' : 'ws';
            final port = u.hasPort ? ':${u.port}' : '';
            return '$scheme://${u.host}$port/ws-engagement';
          }
        }
      } catch (_) {}
    }
    if (kIsWeb) return 'ws://localhost:8080/ws-engagement';
    final env = dotenv.env['WS_BASE_URL'];
    if (env != null && env.isNotEmpty) {
      if (env.startsWith('http://')) return env.replaceFirst('http://', 'ws://');
      if (env.startsWith('https://')) return env.replaceFirst('https://', 'wss://');
      return env;
    }
    return 'ws://192.168.100.4:8080/ws-engagement';
  }

  bool _isExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final payload = jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1])))) as Map<String, dynamic>;
      final exp = payload['exp'];
      if (exp is int) {
        final dt = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        return DateTime.now().isAfter(dt.subtract(const Duration(seconds: 60)));
      }
    } catch (_) {}
    return false;
  }

  Future<String?> _validToken(String? supplied) async {
    String? token = supplied ?? await defaultTokenStorage.readAccessToken();
    if (token == null || token.isEmpty) return null;
    if (_isExpired(token)) {
      final ok = await _refresh();
      if (ok) token = await defaultTokenStorage.readAccessToken();
    }
    return token;
  }

  Future<bool> _refresh() async {
    try {
      final refresh = await defaultTokenStorage.readRefreshToken();
      if (refresh == null || refresh.isEmpty) return false;
      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));
      final res = await dio.post('/auth/refresh', data: {'refreshToken': refresh});
      if (res.statusCode == 200 && res.data is Map) {
        final m = res.data as Map;
        final a = m['accessToken'] as String?;
        final r = m['refreshToken'] as String?;
        if (a != null && r != null) {
          await defaultTokenStorage.saveTokens(accessToken: a, refreshToken: r);
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<void> connect({
    required String userId,
    String? authToken,
    Function? onConnect,
    Function? onDisconnect,
    Function? onError,
  }) async {
    _manualClose = false;
    _userId = userId.trim().toLowerCase();
    _attempt = 0;
    _timer?.cancel();
    await _doConnect(
      userId: _userId!,
      suppliedToken: authToken,
      onConnect: onConnect,
      onDisconnect: onDisconnect,
      onError: onError,
    );
  }

  Future<void> _doConnect({
    required String userId,
    String? suppliedToken,
    Function? onConnect,
    Function? onDisconnect,
    Function? onError,
  }) async {
    try {
      _client?.deactivate();
    } catch (_) {}
    _client = null;

    final token = await _validToken(suppliedToken);
    if (token == null || token.isEmpty) {
      _schedule(userId);
      return;
    }

    final url = _buildUrl();
    _client = StompClient(
      config: StompConfig(
        url: url,
        stompConnectHeaders: {'userId': userId},
        webSocketConnectHeaders: {
          'userId': userId,
          'Authorization': 'Bearer $token',
        },
        onConnect: (f) {
          _attempt = 0;
          onConnect?.call();
          _subscribe(userId);
        },
        onDisconnect: (f) {
          onDisconnect?.call();
          if (!_manualClose) _schedule(userId);
        },
        onWebSocketError: (e) async {
          onError?.call(e);
          final s = e.toString().toLowerCase();
          if (s.contains('401') || s.contains('unauthorized')) {
            if (await _refresh()) {
              await _doConnect(userId: userId);
              return;
            }
          }
          if (!_manualClose) _schedule(userId);
        },
        onWebSocketDone: () {
          if (!_manualClose) _schedule(userId);
        },
        reconnectDelay: Duration.zero,
      ),
    );
    _client!.activate();
  }

  void _schedule(String userId) {
    if (_manualClose) return;
    _timer?.cancel();
    _attempt++;
    final sec = (2 << _attempt.clamp(0, 4)).clamp(2, 30);
    _timer = Timer(Duration(seconds: sec), () {
      if (_manualClose) return;
      _doConnect(userId: userId);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _userId != null && !_manualClose) {
      _doConnect(userId: _userId!);
    }
  }

  void _subscribe(String userId) {
    _register('messages', '/user/queue/messages');
    _register('conversations', '/user/queue/conversations');
    _register('call/offer', '/user/queue/call/offer');
    _register('call/answer', '/user/queue/call/answer');
    _register('call/ice-candidate', '/user/queue/call/ice-candidate');
    _register('call/effect', '/user/queue/call/effect');
    _register('call/end', '/user/queue/call/end');
    _register('call/invite', '/user/queue/call/invite');
    _register('call/accept', '/user/queue/call/accept');
    _register('call/reject', '/user/queue/call/reject');
  }

  void _register(String key, String dest) {
    final u = _client?.subscribe(
      destination: dest,
      callback: (f) {
        if (f.body == null) return;
        try {
          final p = jsonDecode(f.body!) as Map<String, dynamic>;
          _handlers[key]?.call(p);
        } catch (_) {}
      },
    );
    if (u != null) _subs[key] = u;
  }

  void subscribe(String key, Function(Map<String, dynamic>) cb) => _handlers[key] = cb;
  Function(Map<String, dynamic>)? getSubscription(String key) => _handlers[key];

  void unsubscribe(String key) {
    _handlers.remove(key);
    _subs[key]?.call();
    _subs.remove(key);
  }

  void unsubscribeCallback(String key) => _handlers.remove(key);

  void send(String dest, Map<String, dynamic> body) {
    if (_client == null || !(_client!.connected)) return;
    _client!.send(destination: dest, body: jsonEncode(body));
  }

  bool get isConnected => _client?.connected ?? false;

  void disconnect() {
    _manualClose = true;
    _timer?.cancel();
    _subs.clear();
    _handlers.clear();
    try {
      _client?.deactivate();
    } catch (_) {}
    _client = null;
    _attempt = 0;
  }

  void reconnect() {
    if (_manualClose || _userId == null) return;
    _doConnect(userId: _userId!);
  }
}
