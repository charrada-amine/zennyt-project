import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../domain/services/speech_segmenter.dart';

/// Envoie les phrases captées au module de détection de fraude.
///
/// **Le protocole est celui du navigateur, à l'identique** : une trame texte
/// `{"seq": n, "started_at": "…"}` annonce le segment, la trame binaire qui suit le porte.
/// Rien n'a été inventé ici — le module écoute déjà exactement cela sur
/// `/ws/audio/{session_id}?role=…`, et le serveur n'a donc pas à changer.
///
/// **La détection n'est jamais sur le chemin de l'appel.** Toute erreur est avalée après
/// journalisation : si le module est éteint, injoignable ou en panne, l'entretien continue
/// sans que les participants s'en aperçoivent. C'est une propriété à préserver — deux
/// personnes doivent pouvoir se parler même quand la surveillance tombe.
class FraudAudioDataSource {
  final String baseUrl;
  final String sessionId;
  final String role;

  /// Jeton délivré par le backend, lié à (appel, utilisateur, rôle).
  final String? token;

  FraudAudioDataSource({
    required this.baseUrl,
    required this.sessionId,
    required this.role,
    this.token,
  });

  WebSocketChannel? _canal;
  int _sequence = 0;
  bool _ferme = false;

  /// Identifiant que le module a attribué à la session — pas forcément celui qu'on a donné.
  String? _sessionModule;

  /// L'origine HTTP correspondant à l'URL WebSocket : `ws://` devient `http://`.
  String get _origineHttp =>
      baseUrl.replaceFirst(RegExp(r'^ws'), 'http');

  bool get estConnecte => _canal != null;

  /// Ouvre la session, enregistre le consentement, puis connecte la WebSocket.
  ///
  /// Les trois étapes sont celles du navigateur, dans le même ordre : le module refuse une
  /// WebSocket dont la session n'existe pas (code 4404), et refuse chaque segment tant que
  /// le consentement n'est pas enregistré. Sauter l'une des deux donnerait une connexion
  /// qui s'ouvre et ne transporte rien — un échec silencieux de plus.
  ///
  /// Ne lève jamais : un échec laisse simplement la détection inactive.
  Future<void> connecter() async {
    if (_canal != null || _ferme) return;
    try {
      final http = Dio(BaseOptions(
        baseUrl: _origineHttp,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      // 1. Ouvrir la salle. Le module renvoie l'identifiant de session qu'il connaît —
      //    ce n'est pas forcément celui qu'on lui a donné.
      final entree = await http.post<Map<String, dynamic>>('/api/join', data: {
        'room': sessionId.toLowerCase(),
        'role': role,
        'display_name': role,
      });
      final identifiant = entree.data?['session_id'] as String?;
      if (identifiant == null) {
        debugPrint("[Fraude] le module n'a pas rendu de session — détection inactive");
        return;
      }
      _sessionModule = identifiant;

      // 2. Enregistrer l'accord. La personne l'a déjà donné à l'écran de consentement ;
      //    on le transmet ici pour qu'il soit journalisé côté module, par rôle.
      await http.post('/api/consent', data: {
        'session_id': identifiant,
        'role': role,
        'decision': 'accepted',
        'form': 'full',
        'locale': 'fr',
      });

      // 3. Ouvrir le transport.
      final uri = Uri.parse('$baseUrl/ws/audio/$identifiant').replace(queryParameters: {
        'role': role,
        // Le lint suggere ici la syntaxe `?:` ; elle rend la ligne illisible pour un
        // gain nul. Le conseil n'est qu'informatif.
        // ignore: use_null_aware_elements
        if (token != null) 'token': token!,
      });
      final canal = WebSocketChannel.connect(uri);
      await canal.ready;
      _canal = canal;
      canal.stream.listen(
        _surMessage,
        onError: (Object erreur) {
          debugPrint('[Fraude] connexion perdue : $erreur');
          _canal = null;
        },
        onDone: () => _canal = null,
        cancelOnError: true,
      );
      debugPrint('[Fraude] connecté — session $_sessionModule, rôle $role');
    } catch (erreur) {
      debugPrint('[Fraude] connexion impossible : $erreur — la détection reste inactive');
      _canal = null;
    }
  }

  void _surMessage(dynamic message) {
    if (message is! String) return;
    try {
      final json = jsonDecode(message) as Map<String, dynamic>;
      // « rejected » signifie que le consentement a été retiré en cours d'entretien : le
      // module refuse le segment et c'est la bonne réponse, pas une erreur.
      if (json['type'] == 'rejected') {
        debugPrint('[Fraude] segment refusé : ${json['reason']}');
      }
    } catch (_) {
      // Le module peut envoyer d'autres événements ; les ignorer est sans conséquence.
    }
  }

  /// Envoie une phrase. Sans connexion, le segment est simplement abandonné.
  void envoyer(Uint8List pcm, SegmentInfo info) {
    final canal = _canal;
    if (canal == null) return;
    try {
      canal.sink.add(jsonEncode({
        'seq': _sequence,
        'started_at': info.startedAt.toIso8601String(),
        'speech_ms': info.speechMs,
        'duration_ms': info.durationMs,
      }));
      canal.sink.add(enveloppeWav(pcm));
      _sequence++;
    } catch (erreur) {
      debugPrint('[Fraude] envoi échoué : $erreur');
    }
  }

  Future<void> fermer() async {
    _ferme = true;
    final canal = _canal;
    _canal = null;
    try {
      await canal?.sink.close();
    } catch (_) {
      // Fermer une connexion déjà tombée n'est pas un problème.
    }
  }

  /// Emballe du PCM 16 bits mono dans un conteneur WAV.
  ///
  /// Le navigateur envoie du `.webm/opus` parce que c'est ce que produit son enregistreur.
  /// Le téléphone livre du PCM brut ; quarante-quatre octets d'en-tête suffisent à en faire
  /// un fichier que le serveur décode déjà — il passe par PyAV, qui lit tout ce que ffmpeg
  /// lit. C'est ce qui évite d'avoir à embarquer un encodeur sur le téléphone.
  @visibleForTesting
  static Uint8List enveloppeWav(Uint8List pcm, {int sampleRate = 16000, int canaux = 1}) {
    const bitsParEchantillon = 16;
    final octetsParSeconde = sampleRate * canaux * bitsParEchantillon ~/ 8;
    final alignementBloc = canaux * bitsParEchantillon ~/ 8;

    final entete = ByteData(44);
    void ascii(int offset, String valeur) {
      for (var i = 0; i < valeur.length; i++) {
        entete.setUint8(offset + i, valeur.codeUnitAt(i));
      }
    }

    ascii(0, 'RIFF');
    entete.setUint32(4, 36 + pcm.length, Endian.little); // taille du fichier - 8
    ascii(8, 'WAVE');
    ascii(12, 'fmt ');
    entete.setUint32(16, 16, Endian.little); // taille du bloc fmt
    entete.setUint16(20, 1, Endian.little); // 1 = PCM non compressé
    entete.setUint16(22, canaux, Endian.little);
    entete.setUint32(24, sampleRate, Endian.little);
    entete.setUint32(28, octetsParSeconde, Endian.little);
    entete.setUint16(32, alignementBloc, Endian.little);
    entete.setUint16(34, bitsParEchantillon, Endian.little);
    ascii(36, 'data');
    entete.setUint32(40, pcm.length, Endian.little);

    final fichier = Uint8List(44 + pcm.length);
    fichier.setRange(0, 44, entete.buffer.asUint8List());
    fichier.setRange(44, fichier.length, pcm);
    return fichier;
  }
}
