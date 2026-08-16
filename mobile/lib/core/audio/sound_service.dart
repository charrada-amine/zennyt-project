import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Effets sonores généralisés des jeux (dossier `assets/sounds/`).
///
/// Les chemins sont relatifs à `assets/` (convention `AssetSource` d'audioplayers).
enum GameSfx {
  /// Bon choix / bonne réponse.
  correctChoice('sounds/correct-choice-sfx.mp3'),

  /// Mauvais choix / mauvaise réponse.
  wrongChoice('sounds/wrong-choice-sfx.mp3'),

  /// Félicitations / affichage d'un badge.
  congrats('sounds/congrats-sfx.mp3'),

  /// Clic générique de bouton (menus) — quand aucun son spécifique.
  buttonClick('sounds/in-game-button-click-sfx.mp3'),

  /// Ouverture du menu pause.
  pauseClick('sounds/pause-menu-click-sfx.mp3'),

  /// Apparition d'un écran de score / tableau final.
  scoreboard('sounds/scoreboard-show-sfx.mp3'),

  /// Tic des dernières secondes (compte à rebours qui descend).
  timerDecrease('sounds/timer-decrease-sfx.mp3'),

  /// Fin du temps imparti.
  timerEnd('sounds/timer-end-sfx.mp3'),

  // --- Je bouge (avion) ---
  /// Le multiplicateur augmente.
  increaseMultiplier('sounds/increase-multiplier-sfx.mp3'),

  /// Le mouvement de l'avion (direction attendue) change.
  planeMovementChange('sounds/plane-movement-change-sfx.mp3'),

  /// L'orientation/couleur de l'avion change.
  planeOrientationChange('sounds/plane-orientation-change-sfx.mp3'),

  /// Le compteur / la série est remis à zéro (erreur).
  resetCounter('sounds/reset-counter-sfx.mp3'),

  // --- J'investigue (mémoire) ---
  /// Intervalle blanc entre deux stimuli (chiffres).
  blankInterval('sounds/blank-interval-sfx.mp3'),

  /// Début de glisser d'un objet.
  imageDrag('sounds/image-drag-sfx.mp3'),

  /// Dépôt d'un objet dans un emplacement.
  imageDrop('sounds/image-drop-sfx.mp3'),

  /// Clic sur un chiffre (mémorisation).
  numberClick('sounds/number-click-sfx.mp3'),

  /// Clic sur un chiffre — variante alternée.
  numberClickV2('sounds/number-click-v2-sfx.mp3'),

  // --- Je planifie · Optimal-Path ---
  /// Sélection d'un point du chemin (départ + intermédiaires).
  startPoint('sounds/start-point-sfx.mp3'),

  /// Atteinte du point d'arrivée.
  goalPoint('sounds/goal-point-sfx.mp3'),

  // --- Je planifie · Predictive-Puzzle (Tour de Hanoï) ---
  /// Début de glisser d'un disque.
  diskDrag('sounds/disk-drag-sfx.mp3'),

  /// Dépôt d'un disque sur une tour.
  diskDrop('sounds/disk-drop-sfx.mp3');

  const GameSfx(this.asset);

  final String asset;
}

/// Service audio central des jeux : musique de fond en boucle + effets sonores
/// ponctuels. Singleton pour un accès simple depuis les widgets partagés.
///
/// Contrainte fiche « Non-specific » : la musique de fond ne dépasse pas 40 %
/// du volume des SFX ([_musicVolume] = 0.4 × [_sfxVolume]).
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  static const String _bgMusicAsset = 'sounds/bg-music.mp3';
  // Volume sonore par défaut à 40 %. La musique de fond reste ≤ 40 % du volume
  // des SFX (fiche « Non-specific ») → 0.4 × 0.4 = 0.16.
  static const double _sfxVolume = 0.4;
  static const double _musicVolume = 0.16;

  final AudioPlayer _musicPlayer = AudioPlayer(playerId: 'zennyt-bg-music');
  // Lecteur dédié au son du tableau de score : on doit pouvoir le couper
  // précisément quand l'animation de comptage se termine.
  final AudioPlayer _scoreboardPlayer =
      AudioPlayer(playerId: 'zennyt-scoreboard');

  // Synthèse vocale native (moteur TTS de la plateforme, hors ligne, sans API) :
  // lit à voix haute les chiffres révélés dans « J'investigue » (mémoire).
  FlutterTts? _tts;
  String? _ttsLanguage; // dernière langue configurée sur le moteur

  bool _musicEnabled = true;
  bool _sfxEnabled = true;
  bool _musicPlaying = false;
  bool _configured = false;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;

  /// Configure la session audio globale une seule fois : lecture même en mode
  /// silencieux (iOS) et cohabitation avec d'autres sons. Idempotent.
  Future<void> _ensureConfigured() async {
    if (_configured) return;
    _configured = true;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContextConfig(
          focus: AudioContextConfigFocus.mixWithOthers,
          respectSilence: false,
        ).build(),
      );
    } catch (error) {
      _configured = false;
      _log('_ensureConfigured', error);
    }
  }

  /// Démarre (ou reprend) la musique de fond en boucle. Sans effet si la
  /// musique est désactivée ou déjà en cours.
  Future<void> startMusic() async {
    if (!_musicEnabled || _musicPlaying) return;
    _musicPlaying = true;
    await _ensureConfigured();
    try {
      await _musicPlayer.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer.setVolume(_musicVolume);
      await _musicPlayer.play(
        AssetSource(_bgMusicAsset),
        volume: _musicVolume,
      );
    } catch (error) {
      _musicPlaying = false;
      _log('startMusic', error);
    }
  }

  /// Arrête la musique de fond (par ex. en quittant un jeu).
  Future<void> stopMusic() async {
    _musicPlaying = false;
    try {
      await _musicPlayer.stop();
    } catch (error) {
      _log('stopMusic', error);
    }
  }

  /// Joue un effet sonore ponctuel (ignoré si les SFX sont coupés).
  ///
  /// Un lecteur jetable est créé par tir puis libéré à la fin, ce qui autorise
  /// des sons superposés sans se couper mutuellement.
  Future<void> playSfx(GameSfx sfx) async {
    if (!_sfxEnabled) return;
    await _ensureConfigured();
    final player = AudioPlayer();
    try {
      await player.setReleaseMode(ReleaseMode.release);
      await player.play(AssetSource(sfx.asset), volume: _sfxVolume);
      // Libère le lecteur jetable à la fin (ou en cas d'erreur du flux).
      player.onPlayerComplete.listen(
        (_) => _safeDispose(player),
        onError: (_) => _safeDispose(player),
      );
    } catch (error) {
      await _safeDispose(player);
      _log('playSfx(${sfx.name})', error);
    }
  }

  /// Joue le son du tableau de score sur un lecteur dédié, arrêtable via
  /// [stopScoreboard] dès la fin de l'animation de comptage.
  Future<void> playScoreboard() async {
    if (!_sfxEnabled) return;
    await _ensureConfigured();
    try {
      await _scoreboardPlayer.stop();
      await _scoreboardPlayer.setReleaseMode(ReleaseMode.stop);
      await _scoreboardPlayer.play(
        AssetSource(GameSfx.scoreboard.asset),
        volume: _sfxVolume,
      );
    } catch (error) {
      _log('playScoreboard', error);
    }
  }

  /// Coupe le son du tableau de score (appelé quand le comptage 0 → score se
  /// termine).
  Future<void> stopScoreboard() async {
    try {
      await _scoreboardPlayer.stop();
    } catch (error) {
      _log('stopScoreboard', error);
    }
  }

  /// Prépare (une seule fois) le moteur de synthèse vocale natif.
  Future<FlutterTts?> _ensureTts() async {
    var tts = _tts;
    if (tts != null) return tts;
    try {
      tts = FlutterTts();
      // Ne pas bloquer l'appelant : la lecture est déclenchée « fire-and-forget »
      // et cadencée par les délais d'affichage du jeu.
      await tts.awaitSpeakCompletion(false);
      await tts.setVolume(1.0);
      await tts.setSpeechRate(0.5); // débit posé, adapté à un chiffre isolé
      await tts.setPitch(1.0);
      _tts = tts;
      return tts;
    } catch (error) {
      _tts = null;
      _log('_ensureTts', error);
      return null;
    }
  }

  /// Lit à voix haute un chiffre révélé, dans la langue courante du jeu
  /// (`'fr'` → français, sinon anglais). Moteur natif, aucun appel réseau.
  /// Ignoré si les effets sonores sont coupés.
  Future<void> speakNumber(int number, {required String languageCode}) async {
    if (!_sfxEnabled) return;
    final tts = await _ensureTts();
    if (tts == null) return;
    final target = languageCode == 'fr' ? 'fr-FR' : 'en-US';
    try {
      await tts.stop(); // coupe le chiffre précédent s'il parle encore
      if (_ttsLanguage != target) {
        await tts.setLanguage(target);
        _ttsLanguage = target;
      }
      await tts.speak(number.toString());
    } catch (error) {
      _log('speakNumber', error);
    }
  }

  /// Interrompt toute lecture vocale en cours (sortie de jeu, pause…).
  Future<void> stopSpeaking() async {
    try {
      await _tts?.stop();
    } catch (error) {
      _log('stopSpeaking', error);
    }
  }

  Future<void> _safeDispose(AudioPlayer player) async {
    try {
      await player.dispose();
    } catch (_) {
      // Ignoré : environnement sans plugin audio (tests) ou déjà libéré.
    }
  }

  /// Active/coupe la musique de fond (relié aux réglages du menu pause).
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (enabled) {
      startMusic();
    } else {
      stopMusic();
    }
  }

  /// Active/coupe les effets sonores (relié aux réglages du menu pause).
  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
    if (!enabled) stopSpeaking(); // coupe aussi la voix des chiffres
  }

  void _log(String where, Object error) {
    if (kDebugMode) debugPrint('SoundService.$where error: $error');
  }
}

/// À mélanger dans le `State` d'un écran de jeu : démarre la musique de fond à
/// l'entrée et l'arrête à la sortie. Fonctionne aussi avec `ConsumerState`.
mixin GameMusicMixin<T extends StatefulWidget> on State<T> {
  @override
  void initState() {
    super.initState();
    SoundService.instance.startMusic();
  }

  @override
  void dispose() {
    SoundService.instance.stopMusic();
    super.dispose();
  }
}
