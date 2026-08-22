
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';

import '../../data/datasources/fraud_audio_datasource.dart';
import '../../domain/services/speech_segmenter.dart';

/// Dérive le micro local vers le module de détection de fraude, pendant l'appel.
///
/// Trois pièces, chacune ignorante des deux autres :
///
/// 1. Agora livre le PCM du micro local via `onRecordAudioFrame` — **avant mixage**, donc
///    la voix du participant et non celle d'en face. Chacun reste responsable de son propre
///    consentement, exactement comme dans la version navigateur où chaque onglet envoie son
///    propre micro sur sa propre connexion.
/// 2. [SpeechSegmenter] découpe ce flux en phrases, dans les silences.
/// 3. [FraudAudioDataSource] envoie chaque phrase au module.
///
/// **Rien de tout cela n'est sur le chemin de l'appel.** Si le module est éteint, si le
/// réseau tombe, si le découpage se trompe — l'appel continue. C'est une propriété à
/// défendre : la surveillance ne doit jamais empêcher deux personnes de se parler.
class FraudDetectionService {
  final RtcEngine engine;
  final FraudAudioDataSource _envoi;
  late final SpeechSegmenter _segmenteur;

  AudioFrameObserver? _observateur;
  bool _actif = false;
  int _segmentsEnvoyes = 0;

  FraudDetectionService({
    required this.engine,
    required String baseUrl,
    required String sessionId,
    required String role,
    String? token,
  }) : _envoi = FraudAudioDataSource(
          baseUrl: baseUrl,
          sessionId: sessionId,
          role: role,
          token: token,
        ) {
    _segmenteur = SpeechSegmenter(onSegment: _surSegment);
  }

  bool get estActif => _actif;
  int get segmentsEnvoyes => _segmentsEnvoyes;

  /// Démarre la dérivation. **À n'appeler qu'après le consentement des deux parties.**
  Future<void> demarrer() async {
    if (_actif) return;
    try {
      await _envoi.connecter();
      if (!_envoi.estConnecte) {
        debugPrint('[Fraude] module injoignable — l\'appel continue sans détection');
        return;
      }

      // 16 kHz mono : exactement ce que consomme le pipeline, donc aucun
      // rééchantillonnage ni sur le téléphone ni sur le serveur.
      await engine.setRecordingAudioFrameParameters(
        sampleRate: 16000,
        channel: 1,
        mode: RawAudioFrameOpModeType.rawAudioFrameOpModeReadOnly,
        samplesPerCall: 1024,
      );

      _observateur = AudioFrameObserver(
        onRecordAudioFrame: (String channelId, AudioFrame frame) {
          final octets = frame.buffer;
          if (octets != null && octets.isNotEmpty) {
            _segmenteur.push(octets);
          }
        },
      );
      engine.getMediaEngine().registerAudioFrameObserver(_observateur!);

      _actif = true;
      debugPrint('[Fraude] dérivation audio active');
    } catch (erreur) {
      // Un échec ici ne doit rien casser : on repart sans détection.
      debugPrint('[Fraude] démarrage impossible : $erreur');
      await arreter();
    }
  }

  void _surSegment(Uint8List pcm, SegmentInfo info) {
    _segmentsEnvoyes++;
    debugPrint('[Fraude] phrase ${info.speechMs} ms sur ${info.durationMs} ms '
        '— ${pcm.length ~/ 2} échantillons');
    _envoi.envoyer(pcm, info);
  }

  /// Arrête la dérivation et clôt la connexion. Sans effet si déjà arrêtée.
  Future<void> arreter() async {
    if (_observateur != null) {
      try {
        engine.getMediaEngine().unregisterAudioFrameObserver(_observateur!);
      } catch (_) {
        // Le moteur peut déjà être détruit quand l'appel se termine.
      }
      _observateur = null;
    }
    if (_actif) {
      // La dernière phrase mérite d'être envoyée : elle peut être celle qui compte.
      _segmenteur.flush();
    }
    _actif = false;
    await _envoi.fermer();
  }
}
