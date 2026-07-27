import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/network/websocket_service.dart';
import 'package:intl/intl.dart';

class MessagingTestPage extends ConsumerStatefulWidget {
  const MessagingTestPage({super.key});

  @override
  ConsumerState<MessagingTestPage> createState() => _MessagingTestPageState();
}

class _MessagingTestPageState extends ConsumerState<MessagingTestPage> {
  final TextEditingController _myIdController = TextEditingController(text: '11111111-1111-1111-1111-111111111111');
  final TextEditingController _targetIdController = TextEditingController(text: '22222222-2222-2222-2222-222222222222');
  final TextEditingController _conversationIdController =
      TextEditingController(text: 'conv-test-001');
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _logScrollController = ScrollController();
  WebSocketService? _webSocketService;

  bool _isConnected = false;
  bool _incomingCall = false;
  String _incomingCallType = '';
  String _incomingCallConversationId = '';
  String _incomingCallSenderId = '';
  Map<String, dynamic>? _lastOffer;
  final List<_LogEntry> _logs = [];
  String _currentUserId = '';
  String _targetUserId = '';

  static final _uuidRegex = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  @override
  void initState() {
    super.initState();
    debugPrint('🧪 [MessagingTestPage] initState');
    _addLog('Page de test initialisée. Saisissez les UUIDs pour commencer.',
        _LogType.info);
  }

  @override
  void dispose() {
    debugPrint('🧪 [MessagingTestPage] dispose');
    _disconnectCurrentService();
    _myIdController.dispose();
    _targetIdController.dispose();
    _conversationIdController.dispose();
    _messageController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  // ------------------ Helpers ------------------

  void _addLog(String log, _LogType type) {
    if (!mounted) return;
    setState(() {
      final time = DateFormat('HH:mm:ss').format(DateTime.now());
      _logs.insert(0, _LogEntry(time: time, message: log, type: type));
      if (_logs.length > 200) _logs.removeLast();
    });
  }

  bool _validateInputs() {
    final myId = _myIdController.text.trim();
    final targetId = _targetIdController.text.trim();
    final conversationId = _conversationIdController.text.trim();

    if (myId.isEmpty || targetId.isEmpty || conversationId.isEmpty) {
      _showSnack('Veuillez remplir tous les champs');
      return false;
    }
    if (!_uuidRegex.hasMatch(myId)) {
      _showSnack('Mon ID doit être un UUID valide');
      return false;
    }
    if (!_uuidRegex.hasMatch(targetId)) {
      _showSnack('L\'ID destinataire doit être un UUID valide');
      return false;
    }
    if (myId == targetId) {
      _showSnack('Mon ID et l\'ID destinataire ne peuvent pas être identiques');
      return false;
    }
    return true;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[700]),
    );
  }

  void _disconnectCurrentService() {
    _webSocketService?.disconnect();
    _webSocketService = null;
  }

  // ------------------ Connexion / Déconnexion ------------------

  void _connect() {
    if (!_validateInputs()) return;

    // Ferme toute connexion précédente pour éviter les doublons
    _disconnectCurrentService();

    _currentUserId = _myIdController.text.trim();
    _targetUserId = _targetIdController.text.trim();
    final convId = _conversationIdController.text.trim();
    debugPrint(
        '🔌 [WS] Tentative de connexion: myId=$_currentUserId targetId=$_targetUserId convId=$convId');
    _addLog(
        'Connexion WebSocket en tant que $_currentUserId...', _LogType.info);

    _webSocketService = WebSocketService();

    _webSocketService!.connect(
      userId: _currentUserId,
      onConnect: () {
        debugPrint(
            '✅ [WS] onConnect déclenché pour $_currentUserId — abonnements en cours...');
        if (!mounted) return;
        setState(() => _isConnected = true);
        _addLog('✅ WebSocket connecté avec succès', _LogType.success);

        // 🔥 Abonnements TOUS placés ICI, après la connexion STOMP effective
        _setupSubscriptions();
      },
      onDisconnect: () {
        debugPrint('🔌 [WS] onDisconnect déclenché pour $_currentUserId');
        if (!mounted) return;
        setState(() {
          _isConnected = false;
          _incomingCall = false;
        });
        _addLog('🔌 WebSocket déconnecté', _LogType.warning);
      },
      onError: (err) {
        debugPrint('❌ [WS] onError: $err');
        if (!mounted) return;
        _addLog('❌ Erreur WebSocket: $err', _LogType.error);
      },
    );
  }

  void _setupSubscriptions() {
    final service = _webSocketService;
    if (service == null) return;

    // Écouteur global de TOUS les messages bruts (débogage)
    service.subscribe('', (raw) {
      debugPrint('🌐 [WS RAW] Message reçu sur canal générique: $raw');
      _addLog('📨 RAW: $raw', _LogType.info);
    });

    debugPrint('🔧 [WS] Abonnement au topic "messages"');
    service.subscribe('messages', (message) {
      debugPrint('📩 [WS] Event "messages" reçu: $message');
      final content = message['content'] ?? message.toString();
      _addLog('📩 Message reçu: $content', _LogType.incoming);
    });

    debugPrint('🔧 [WS] Abonnement au topic "call/offer"');
    service.subscribe('call/offer', (offer) {
      debugPrint('========================================');
      debugPrint('🔔 [WS] call/offer event reçu');
      debugPrint('🔔 [WS] Payload brut: $offer');
      debugPrint('🔔 [WS] senderId: ${offer['senderId']}');
      debugPrint('🔔 [WS] callType: ${offer['callType']}');
      debugPrint('🔔 [WS] conversationId: ${offer['conversationId']}');
      debugPrint('🔔 [WS] mounted: $mounted');
      debugPrint('========================================');

      _addLog('📞 Appel entrant! De: ${offer['senderId']}', _LogType.incoming);
      _lastOffer = offer;
      if (!mounted) return;
      setState(() {
        _incomingCall = true;
        // ✅ le backend doit renvoyer 'callType': 'audio' | 'video' dans le
        // payload d'offer (voir CallSignalingRepositoryImpl.sendOffer).
        // Sans ce champ correctement propagé, l'appel est toujours affiché
        // comme "vidéo" ici (valeur par défaut).
        _incomingCallType = offer['callType'] ?? 'video';
        _incomingCallConversationId =
            offer['conversationId'] ?? _conversationIdController.text.trim();
        _incomingCallSenderId = offer['senderId'] ?? _targetUserId;
      });
      debugPrint(
          '✅ [WS] _incomingCall=true (type=$_incomingCallType, from=$_incomingCallSenderId), bannière devrait s\'afficher');
    });

    debugPrint('🔧 [WS] Abonnement au topic "call/answer"');
    service.subscribe('call/answer', (answer) {
      debugPrint('✅ [WS] Event "call/answer" reçu: $answer');
      _addLog('✅ Appel accepté par le destinataire', _LogType.success);
    });

    debugPrint('🔧 [WS] Abonnement au topic "call/ice-candidate"');
    service.subscribe('call/ice-candidate', (candidate) {
      debugPrint('🔗 [WS] Event "call/ice-candidate" reçu: $candidate');
      _addLog('🔗 ICE candidate reçu', _LogType.info);
    });

    debugPrint('🔧 [WS] Abonnement au topic "call/end"');
    service.subscribe('call/end', (end) {
      debugPrint('📴 [WS] Event "call/end" reçu: $end');
      _addLog('📴 Appel terminé', _LogType.warning);
      if (!mounted) return;
      setState(() => _incomingCall = false);
    });
  }

  void _disconnect() {
    debugPrint('🔌 [WS] Déconnexion manuelle demandée');
    _disconnectCurrentService();
    if (mounted) {
      setState(() {
        _isConnected = false;
        _incomingCall = false;
      });
    }
    _addLog('Déconnexion manuelle effectuée', _LogType.info);
  }

  // ------------------ Messagerie ------------------

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty || !_isConnected) return;

    final conversationId = _conversationIdController.text.trim();
    debugPrint(
        '📤 [WS] Envoi message -> to=$_targetUserId conv=$conversationId text="$text"');
    _addLog('📤 Envoi du message à $_targetUserId: "$text"', _LogType.outgoing);

    _webSocketService?.send('/app/chat.sendMessage', {
      'content': text,
      'senderId': _currentUserId,
      'recipientId': _targetUserId,
      'conversationId': conversationId,
    });
    _messageController.clear();
  }

  // ------------------ Appels sortants ------------------

  void _startAudioCall() {
    if (!_isConnected) return;
    final conversationId = _conversationIdController.text.trim();
    debugPrint(
        '📞 [CALL] Démarrage appel audio -> target=$_targetUserId conv=$conversationId');
    _addLog(
      '📞 Appel audio vers $_targetUserId (conv: $conversationId)',
      _LogType.outgoing,
    );
    // ✅ isVideoCall: false -> CallPage/CallPageController ne demanderont
    // jamais la caméra ni ne négocieront de track vidéo.
    context.push('/call', extra: {
      'contactName': 'Test User $_targetUserId',
      'conversationId': conversationId,
      'counterpartId': _targetUserId,
      'myUserId': _currentUserId,
      'isVideoCall': false,
    });
  }

  void _startVideoCall() {
    if (!_isConnected) return;
    final conversationId = _conversationIdController.text.trim();
    debugPrint(
        '📹 [CALL] Démarrage appel vidéo -> target=$_targetUserId conv=$conversationId');
    _addLog(
      '📹 Appel vidéo vers $_targetUserId (conv: $conversationId)',
      _LogType.outgoing,
    );
    context.push('/video-call', extra: {
      'contactName': 'Test User $_targetUserId',
      'conversationId': conversationId,
      'counterpartId': _targetUserId,
      'myUserId': _currentUserId,
      'isVideoCall': true,
    });
  }

  // ------------------ Gestion des appels entrants ------------------

  void _acceptIncomingCall() {
    debugPrint(
        '✅ [CALL] Acceptation appel entrant de $_incomingCallSenderId (type=$_incomingCallType, conv=$_incomingCallConversationId)');
    _addLog('✅ Acceptation de l\'appel de $_incomingCallSenderId',
        _LogType.success);
    setState(() => _incomingCall = false);
    final bool isVideo = _incomingCallType != 'audio';
    final route = isVideo ? '/video-call' : '/call';
    context.push(route, extra: {
      'contactName': 'Test User $_incomingCallSenderId',
      'conversationId': _incomingCallConversationId,
      'counterpartId': _incomingCallSenderId,
      'myUserId': _currentUserId,
      'incomingOffer': _lastOffer,
      'isVideoCall': isVideo,
    });
  }

  void _rejectIncomingCall() {
    debugPrint('❌ [CALL] Rejet appel entrant de $_incomingCallSenderId');
    _addLog('❌ Appel rejeté', _LogType.warning);
    setState(() => _incomingCall = false);
    final conversationId = _conversationIdController.text.trim();
    _webSocketService?.send('/app/call/$conversationId/end', {
      'senderId': _currentUserId,
      'counterpartId': _incomingCallSenderId,
    });
  }

  void _clearLogs() {
    setState(() => _logs.clear());
  }

  // ------------------ UI ------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🧪 Test Messaging & Calls'),
        backgroundColor: Colors.red[900],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Vider les logs',
            onPressed: _clearLogs,
          ),
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildConfigSection(),
              const SizedBox(height: 8),
              _buildStatusIndicator(),
              if (_incomingCall) _buildIncomingCallBanner(),
              const Divider(height: 16),
              if (_isConnected) ...[
                _buildCallButtons(),
                const SizedBox(height: 8),
                _buildMessageInput(),
                const SizedBox(height: 8),
              ],
              _buildLogSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfigSection() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuration de test',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _myIdController,
              decoration: InputDecoration(
                labelText: 'Mon ID (UUID)',
                hintText: 'ex: 550e8400-e29b-41d4-a716-446655440000',
                border: const OutlineInputBorder(),
                suffixIcon: _myIdController.text.isNotEmpty
                    ? Icon(
                        _uuidRegex.hasMatch(_myIdController.text.trim())
                            ? Icons.check_circle
                            : Icons.error,
                        color: _uuidRegex.hasMatch(_myIdController.text.trim())
                            ? Colors.green
                            : Colors.red,
                      )
                    : null,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
              enabled: !_isConnected,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _targetIdController,
              decoration: InputDecoration(
                labelText: 'ID destinataire (UUID)',
                hintText: 'ex: 660e8400-e29b-41d4-a716-446655440001',
                border: const OutlineInputBorder(),
                suffixIcon: _targetIdController.text.isNotEmpty
                    ? Icon(
                        _uuidRegex.hasMatch(_targetIdController.text.trim())
                            ? Icons.check_circle
                            : Icons.error,
                        color:
                            _uuidRegex.hasMatch(_targetIdController.text.trim())
                                ? Colors.green
                                : Colors.red,
                      )
                    : null,
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
              enabled: !_isConnected,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _conversationIdController,
              decoration: const InputDecoration(
                labelText: 'ID de conversation',
                hintText: 'ex: conv-test-001',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
              enabled: !_isConnected,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isConnected ? _disconnect : _connect,
                icon: Icon(
                  _isConnected ? Icons.link_off : Icons.link,
                ),
                label: Text(
                  _isConnected ? 'Déconnecter' : 'Connecter',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isConnected ? Colors.red[700] : Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isConnected ? Colors.green : Colors.grey,
              boxShadow: _isConnected
                  ? [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.5),
                        blurRadius: 6,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _isConnected
                  ? 'Connecté → $_currentUserId ↔ $_targetUserId'
                  : 'Non connecté',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 11,
                color: _isConnected ? Colors.green[800] : Colors.grey,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingCallBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        children: [
          Text(
            '📞 Appel ${_incomingCallType == 'audio' ? 'audio' : 'vidéo'} entrant!',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            'De: $_incomingCallSenderId',
            style: const TextStyle(fontSize: 11),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // ✅ FIX crash "BoxConstraints forces an infinite width" :
              // un ElevatedButton.icon enfant direct d'un Row peut recevoir
              // des contraintes de largeur invalides selon le contexte
              // parent. Flexible garantit une largeur toujours bornée.
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: _acceptIncomingCall,
                  icon: const Icon(Icons.call),
                  label: const Text('Accepter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: ElevatedButton.icon(
                  onPressed: _rejectIncomingCall,
                  icon: const Icon(Icons.call_end),
                  label: const Text('Rejeter'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCallButtons() {
    return Row(
      children: [
        // ✅ FIX layout : Wrap donne une largeur non bornée (infinie) à
        // chacun de ses enfants sur son axe principal. Un ElevatedButton
        // placé directement dedans peut alors planter avec
        // "BoxConstraints forces an infinite width". On utilise un Row
        // avec Expanded à la place, ce qui borne toujours la largeur.
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _startAudioCall,
            icon: const Icon(Icons.call, size: 18),
            label: const Text('Appel Audio'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _startVideoCall,
            icon: const Icon(Icons.video_call, size: 18),
            label: const Text('Appel Vidéo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple[700],
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMessageInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _messageController,
            decoration: const InputDecoration(
              hintText: 'Taper un message...',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            onSubmitted: (_) => _sendMessage(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.send),
          color: Colors.blue,
          onPressed: _sendMessage,
        ),
      ],
    );
  }

  Widget _buildLogSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Logs en direct:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                controller: _logScrollController,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final entry = _logs[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 3.0),
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: '[${entry.time}] ',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                          TextSpan(
                            text: entry.message,
                            style: TextStyle(
                              color: entry.color,
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------ Modèles de logs ------------------

enum _LogType { info, success, error, warning, incoming, outgoing }

class _LogEntry {
  final String time;
  final String message;
  final _LogType type;

  const _LogEntry({
    required this.time,
    required this.message,
    required this.type,
  });

  Color get color {
    switch (type) {
      case _LogType.info:
        return Colors.white70;
      case _LogType.success:
        return Colors.greenAccent;
      case _LogType.error:
        return Colors.redAccent;
      case _LogType.warning:
        return Colors.orangeAccent;
      case _LogType.incoming:
        return Colors.cyanAccent;
      case _LogType.outgoing:
        return Colors.lightBlueAccent;
    }
  }
}
