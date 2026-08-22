import 'dart:math' as math;
import 'dart:typed_data';

/// Découpe un flux audio continu en phrases, en coupant dans les silences.
///
/// Porté depuis `vad.js` du module de détection de fraude, à l'identique : mêmes
/// constantes, même machine à états. Les valeurs y ont été réglées à l'usage, il ne
/// s'agit pas de les redécouvrir.
///
/// **Pourquoi ne pas découper à intervalle fixe**, ce qui tiendrait en cinq lignes : une
/// coupure au milieu d'une phrase oblige soit à recoller le texte après coup, soit — pire —
/// à demander aux participants de marquer des pauses artificielles. Un entretien doit se
/// parler normalement.
///
/// **Le principe** : on mesure l'énergie du signal en continu, on accumule les échantillons,
/// et on ne clôt un segment que pendant un silence, une fois qu'une phrase a été prononcée.
/// Aucune syllabe n'est perdue, aucune phrase n'est scindée.
///
/// Contrairement à la version navigateur, celle-ci reçoit du PCM brut : pas d'`AnalyserNode`,
/// une moyenne quadratique sur le tampon suffit. Elle ne connaît ni Agora ni le réseau — on
/// lui pousse des octets, elle rend des segments. C'est ce qui la rend testable sans micro.
class SpeechSegmenter {
  /// Période d'échantillonnage de l'énergie.
  static const int frameMs = 50;

  /// Durée de son continu avant de déclarer « ça parle ».
  static const int onsetMs = 120;

  /// Silence qui clôt une phrase — une pause naturelle de fin de phrase.
  static const int silenceMs = 700;

  /// En dessous : toux, clic, raclement de gorge. Rien n'est envoyé.
  static const int minSpeechMs = 400;

  /// Filet de sécurité pour un monologue continu.
  static const int maxSegmentMs = 25000;

  /// Silence prolongé : on repart à neuf sans rien envoyer.
  static const int idleResetMs = 15000;

  /// Vitesse d'adaptation du bruit de fond.
  static const double floorAlpha = 0.02;

  /// Combien de fois le bruit de fond vaut de la parole.
  static const double floorMargin = 2.8;

  /// Plancher, pour un micro très silencieux.
  static const double absoluteFloor = 0.008;

  final int sampleRate;

  /// Appelé à chaque phrase close : le PCM 16 bits de la phrase, et sa description.
  final void Function(Uint8List pcm, SegmentInfo info) onSegment;

  /// Retour visuel facultatif — niveau dans [0, 1] et « est-ce qu'on parle ».
  final void Function(double level, bool speaking)? onLevel;

  SpeechSegmenter({
    required this.onSegment,
    this.sampleRate = 16000,
    this.onLevel,
  });

  final BytesBuilder _segment = BytesBuilder(copy: false);
  final BytesBuilder _frame = BytesBuilder(copy: false);

  double _noiseFloor = 0.01;
  int _onsetAccumulatedMs = 0;
  int _speechMs = 0;
  int _segmentMs = 0;
  int _msSinceLastVoice = 0;
  bool _hasSpeech = false;
  DateTime _segmentStartedAt = DateTime.now().toUtc();

  /// Nombre d'octets qui composent une fenêtre d'analyse de [frameMs].
  int get _frameBytes => (sampleRate * frameMs ~/ 1000) * 2;

  /// Pousse un tampon PCM 16 bits mono, tel qu'Agora le livre.
  ///
  /// Les tampons d'Agora ne tombent pas sur des multiples de la fenêtre d'analyse : on
  /// accumule jusqu'à en remplir une, et le reste attend le tampon suivant. Analyser des
  /// fenêtres de taille variable ferait dépendre le seuil de la taille du tampon.
  void push(Uint8List pcm) {
    _frame.add(pcm);
    while (_frame.length >= _frameBytes) {
      final accumulated = _frame.takeBytes();
      final window = Uint8List.sublistView(accumulated, 0, _frameBytes);
      _analyse(window);
      if (accumulated.length > _frameBytes) {
        _frame.add(Uint8List.sublistView(accumulated, _frameBytes));
      }
    }
  }

  void _analyse(Uint8List window) {
    _segment.add(window);
    _segmentMs += frameMs;

    final level = _rms(window);
    final threshold = math.max(_noiseFloor * floorMargin, absoluteFloor);
    final speaking = level > threshold;

    if (speaking) {
      _onsetAccumulatedMs += frameMs;
      // Une phrase n'est déclarée qu'après un son *continu* : un claquement de porte
      // ou un raclement de gorge ne doit pas ouvrir un segment.
      if (_onsetAccumulatedMs >= onsetMs) {
        _hasSpeech = true;
        _speechMs += frameMs;
        _msSinceLastVoice = 0;
      }
    } else {
      _onsetAccumulatedMs = 0;
      _msSinceLastVoice += frameMs;
      // Le bruit de fond ne s'apprend que dans le silence : sinon la voix ferait monter
      // le seuil, et le système finirait sourd.
      _noiseFloor = _noiseFloor * (1 - floorAlpha) + level * floorAlpha;
    }

    onLevel?.call(math.min(1, level / (threshold * 3)), speaking);

    if (_hasSpeech && !speaking && _msSinceLastVoice >= silenceMs) {
      _close(); // fin de phrase : on coupe dans le silence
    } else if (_hasSpeech && _segmentMs >= maxSegmentMs) {
      _close(); // monologue : on découpe quand même
    } else if (!_hasSpeech && _segmentMs >= idleResetMs) {
      _reset(); // silence prolongé : rien n'est envoyé
    }
  }

  /// Moyenne quadratique du tampon, ramenée dans [0, 1] comme le fait le navigateur.
  static double _rms(Uint8List window) {
    final samples = window.buffer.asInt16List(window.offsetInBytes, window.length ~/ 2);
    double sum = 0;
    for (final sample in samples) {
      final normalised = sample / 32768.0;
      sum += normalised * normalised;
    }
    return math.sqrt(sum / samples.length);
  }

  void _close() {
    final pcm = _segment.takeBytes();
    final keep = _hasSpeech && _speechMs >= minSpeechMs;
    if (keep && pcm.isNotEmpty) {
      onSegment(
        pcm,
        SegmentInfo(
          startedAt: _segmentStartedAt,
          speechMs: _speechMs,
          durationMs: _segmentMs,
        ),
      );
    }
    _reset();
  }

  void _reset() {
    _segment.clear();
    _segmentMs = 0;
    _speechMs = 0;
    _onsetAccumulatedMs = 0;
    _msSinceLastVoice = 0;
    _hasSpeech = false;
    _segmentStartedAt = DateTime.now().toUtc();
  }

  /// Clôt le segment en cours — à appeler quand l'appel se termine.
  void flush() => _close();
}

/// Ce qu'on sait d'une phrase close.
class SegmentInfo {
  final DateTime startedAt;
  final int speechMs;
  final int durationMs;

  const SegmentInfo({
    required this.startedAt,
    required this.speechMs,
    required this.durationMs,
  });
}
