import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import '../constants/app_constants.dart';
import '../storage/token_storage.dart';
import '../config/app_config.dart';

class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  factory WebSocketService() => _instance;
  WebSocketService._internal();

  /// L'adresse du temps reel, derivee de celle de l'API.
  ///
  /// Elle etait codee en dur sur `ws://192.168.100.4:8080` — l'adresse locale d'une
  /// machine de developpement. Sur toute autre machine, et en production, le temps reel
  /// tentait donc de joindre une adresse qui n'existe pas : messagerie, appels entrants
  /// et notifications tombaient ensemble, sans autre signe qu'un « Connection reset by
  /// peer » dans les journaux. La derivation correcte etait commentee juste au-dessus.
  ///
  /// `AppConfig.baseUrl` sait deja retomber sur 10.0.2.2 pour l'emulateur Android et sur
  /// localhost ailleurs ; il suffit d'en retirer le prefixe `/api/v1`, le point d'entree
  /// STOMP etant a la racine.
  static String get _websocketUrl {
    return AppConfig.baseUrl
        .replaceFirst(RegExp(r'^http'), 'ws')
        .replaceFirst(RegExp(r'/api/v1/?$'), '') +
        '/ws-engagement';
  }

  StompClient? _stompClient;

  final Map<String, Function(Map<String, dynamic>)> _subscriptions = {};
  final Map<String, StompUnsubscribe> _stompSubs = {};

  /// Ouvre la connexion STOMP. Si [authToken] est absent, le bearer token est
  /// relu depuis le stockage sécurisé ([defaultTokenStorage]) : le handshake
  /// WebSocket exige toujours `Authorization: Bearer <JWT>` côté serveur.
  Future<void> connect({
    required String userId,
    String? authToken,
    Function? onConnect,
    Function? onDisconnect,
    Function? onError,
  }) async {
    if (_stompClient != null && _stompClient!.connected) {
      onConnect?.call();
      return;
    }

    final effectiveToken = authToken ?? await defaultTokenStorage.readAccessToken();

    final normalisedUserId = userId.trim().toLowerCase();

    _stompClient = StompClient(
      config: StompConfig(
        url: _websocketUrl,
        stompConnectHeaders: {'userId': normalisedUserId},
        webSocketConnectHeaders: {
          'userId': normalisedUserId,
          if (effectiveToken != null) 'Authorization': 'Bearer $effectiveToken',
        },
        onConnect: (StompFrame frame) {
          print('✅ WebSocket connected! principal=$normalisedUserId');
          onConnect?.call();
          _subscribeToUserQueues(normalisedUserId);
        },
        onDisconnect: (StompFrame frame) {
          print('🔌 WebSocket disconnected');
          onDisconnect?.call();
        },
        onWebSocketError: (dynamic error) {
          print("wsUrl: ${_websocketUrl}");
          print('❌ WebSocket error: $error');
          onError?.call(error);
        },
        onWebSocketDone: () {
          print('WebSocket done');
        },
        reconnectDelay: const Duration(seconds: 5),
      ),
    );

    _stompClient?.activate();
  }

  void _subscribeToUserQueues(String userId) {
    _registerSub(
      key: 'messages',
      destination: '/user/queue/messages',
    );

    _registerSub(
      key: 'conversations',
      destination: '/user/queue/conversations',
    );

    _registerSub(
      key: 'call/offer',
      destination: '/user/queue/call/offer',
    );

    _registerSub(
      key: 'call/answer',
      destination: '/user/queue/call/answer',
    );

    _registerSub(
      key: 'call/ice-candidate',
      destination: '/user/queue/call/ice-candidate',
    );

    _registerSub(
      key: 'call/effect',
      destination: '/user/queue/call/effect',
    );

    _registerSub(
      key: 'call/end',
      destination: '/user/queue/call/end',
    );

    _registerSub(
      key: 'call/invite',
      destination: '/user/queue/call/invite',
    );

    _registerSub(
      key: 'call/accept',
      destination: '/user/queue/call/accept',
    );

    _registerSub(
      key: 'call/reject',
      destination: '/user/queue/call/reject',
    );

    // DEBUG: common alternative call destinations
    _registerSub(
      key: 'debug/call/invitation',
      destination: '/user/queue/call/invitation',
    );
    _registerSub(
      key: 'debug/call/invites',
      destination: '/user/queue/call/invites',
    );
    _registerSub(
      key: 'debug/calls/invite',
      destination: '/user/queue/calls/invite',
    );
    _registerSub(
      key: 'debug/topic/call/invite',
      destination: '/topic/call/invite',
    );
    _registerSub(
      key: 'debug/queue/call/invite',
      destination: '/queue/call/invite',
    );
  }

  void _registerSub({required String key, required String destination}) {
    final unsub = _stompClient?.subscribe(
      destination: destination,
      callback: (StompFrame frame) {
        print('📨 Received on $destination: ${frame.body}');
        if (frame.body != null) {
          try {
            final payload = jsonDecode(frame.body!) as Map<String, dynamic>;
            _subscriptions[key]?.call(payload);
          } catch (e) {
            print('⚠️  Failed to parse frame body on $destination: $e');
          }
        }
      },
    );

    if (unsub != null) {
      _stompSubs[key] = unsub;
    }
  }

  void subscribe(String key, Function(Map<String, dynamic>) callback) {
    _subscriptions[key] = callback;
  }

  Function(Map<String, dynamic>)? getSubscription(String key) {
    return _subscriptions[key];
  }

  void unsubscribe(String key) {
    _subscriptions.remove(key);
    _stompSubs[key]?.call();
    _stompSubs.remove(key);
  }

  void unsubscribeCallback(String key) {
    _subscriptions.remove(key);
  }

  void send(String destination, Map<String, dynamic> body) {
    if (_stompClient == null || !(_stompClient!.connected)) {
      print('⚠️  send() called but STOMP client is not connected yet.');
      return;
    }
    _stompClient?.send(
      destination: destination,
      body: jsonEncode(body),
    );
  }

  bool get isConnected => _stompClient?.connected ?? false;

  void disconnect() {
    _stompSubs.clear();
    _subscriptions.clear();
    _stompClient?.deactivate();
  }
}
