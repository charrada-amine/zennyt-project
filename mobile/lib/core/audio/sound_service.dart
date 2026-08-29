import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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

  /// Félicitations / fin de parcours réussie.
  congrats('sounds/congrats-sfx.mp3'),

  /// Déverrouillage d'un badge / révélation d'un niveau de profil.
  ///
  /// ⚠️ Pas d'asset dédié à ce jour : pointe volontairement sur le même fichier
  /// que [congrats]. L'entrée existe pour que les écrans nomment le bon moment
  /// — brancher un vrai son « badge unlocked » ne coûtera qu'un changement de
  /// chemin ici, sans toucher aux appelants.
  badgeUnlocked('sounds/congrats-sfx.mp3'),

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
/// Volume de la musique de fond : [_musicVolume] (25 % du volume système),
/// réglé par le client après écoute — voir le commentaire de la constante.
class SoundService {
  SoundService._();

  static final SoundService instance = SoundService._();

  static const String _bgMusicAsset = 'sounds/bg-music.mp3';

  /// Volume des effets sonores — 40 % du volume système.
  static const double _sfxVolume = 0.4;

  /// Volume de la musique de fond — **25 % du volume système**.
  ///
  /// Valeur fixée par le client à l'écoute, en deux temps : la version d'abord
  /// livrée à 16 % (la fiche « Non-specific » exprimait un RAPPORT — musique
  /// ≤ 40 % des SFX) a été jugée inaudible, celle à 40 % trop forte. 25 % est
  /// l'arbitrage retenu.
  ///
  /// Exprimé en valeur ABSOLUE, et non plus en fraction de [_sfxVolume] :
  /// c'est ainsi que le client raisonne (« le volume passe à 25 % »), et un
  /// ratio rendait le réglage dépendant du volume des effets.
  static const double _musicVolume = 0.25;

  /// Sons qui marquent une erreur — ils déclenchent aussi la vibration.
  static const Set<GameSfx> _errorSfx = {
    GameSfx.wrongChoice,
    GameSfx.resetCounter,
  };

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
  bool _hapticsEnabled = true;
  bool _musicPlaying = false;
  /// Musique chargée puis mise en pause — distinct de « jamais démarrée ».
  bool _musicPaused = false;
  bool _configured = false;

  bool get musicEnabled => _musicEnabled;
  bool get sfxEnabled => _sfxEnabled;
  bool get hapticsEnabled => _hapticsEnabled;

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
    if (!_musicEnabled) return;
    if (_musicPaused) return resumeMusic();
    if (_musicPlaying) return;
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
    _musicPaused = false;
    try {
      await _musicPlayer.stop();
    } catch (error) {
      _log('stopMusic', error);
    }
  }

  /// Met la musique de fond en **pause** (position conservée).
  ///
  /// Distinct de [stopMusic] : le toggle du menu pause utilisait `stop`, donc
  /// réactiver la musique la relançait depuis le début au lieu de reprendre où
  /// elle en était.
  Future<void> pauseMusic() async {
    if (!_musicPlaying || _musicPaused) return;
    _musicPaused = true;
    try {
      await _musicPlayer.pause();
    } catch (error) {
      _musicPaused = false;
      _log('pauseMusic', error);
    }
  }

  /// Reprend la musique de fond là où [pauseMusic] l'a laissée.
  Future<void> resumeMusic() async {
    if (!_musicEnabled || !_musicPaused) return;
    _musicPaused = false;
    try {
      await _musicPlayer.resume();
    } catch (error) {
      _log('resumeMusic', error);
    }
  }

  // ── Retour haptique ───────────────────────────────────────────────────
  // Centralisé ici pour une seule raison : le réglage « Vibration » du menu
  // pause doit pouvoir tout couper. Un appel direct à HapticFeedback dans un
  // écran échapperait au réglage — c'était le cas de la seule vibration
  // existante (case interdite d'Optimal Path).

  /// Erreur : vibration franche.
  ///
  /// [HapticFeedback.vibrate] et non `heavyImpact` : le client signalait que la
  /// vibration d'erreur d'Optimal Path « ne fonctionne pas » alors que le
  /// câblage était bon. La cause est le mapping Android de Flutter —
  /// `heavyImpact` y devient `HapticFeedbackConstants.CONTEXT_CLICK`, l'effet le
  /// plus discret du système, souvent imperceptible voire ignoré selon les
  /// réglages du téléphone. `vibrate` mappe sur `LONG_PRESS`, le plus franc.
  ///
  /// ⚠️ Aucun retour haptique n'existe sur simulateur iOS ni sur la plupart des
  /// émulateurs Android : ce point ne peut se valider que sur appareil réel.
  Future<void> vibrateError() => _vibrate(HapticFeedback.vibrate);

  /// Réussite / franchissement d'un palier : vibration moyenne.
  Future<void> vibrateSuccess() => _vibrate(HapticFeedback.mediumImpact);

  /// Sélection, pose d'un élément : vibration discrète.
  Future<void> vibrateSelection() => _vibrate(HapticFeedback.selectionClick);

  Future<void> _vibrate(Future<void> Function() effect) async {
    if (!_hapticsEnabled) return;
    try {
      await effect();
    } catch (error) {
      // Appareil sans moteur haptique, ou plateforme de test sans plugin.
      _log('_vibrate', error);
    }
  }

  /// Joue un effet sonore ponctuel (ignoré si les SFX sont coupés).
  ///
  /// Un lecteur jetable est créé par tir puis libéré à la fin, ce qui autorise
  /// des sons superposés sans se couper mutuellement.
  Future<void> playSfx(GameSfx sfx) async {
    // Le retour haptique accompagne les sons d'ERREUR, et il est déclenché AVANT
    // le test sur [_sfxEnabled] : son et vibration sont deux canaux distincts,
    // avec deux interrupteurs distincts dans le menu pause. Couper le son ne doit
    // pas couper la vibration.
    //
    // Centraliser ici plutôt que dans chaque écran a un avantage décisif : tout
    // jeu qui signale déjà une erreur par un son gagne la vibration sans une
    // ligne de plus, et aucun écran ne peut contourner le réglage.
    if (_errorSfx.contains(sfx)) {
      vibrateError();
    }
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

  /// Active/coupe la musique de fond (réglage du menu pause).
  ///
  /// Met en **pause** plutôt qu'arrêter : réactiver reprend le morceau où il en
  /// était. Si la musique n'a jamais démarré (réglage basculé hors gameplay),
  /// [startMusic] reste sans effet — c'est le plateau qui la lance.
  void setMusicEnabled(bool enabled) {
    _musicEnabled = enabled;
    if (enabled) {
      startMusic();
    } else {
      pauseMusic();
    }
  }

  /// Active/coupe le retour haptique (réglage du menu pause).
  void setHapticsEnabled(bool enabled) => _hapticsEnabled = enabled;

  /// Active/coupe les effets sonores (relié aux réglages du menu pause).
  void setSfxEnabled(bool enabled) {
    _sfxEnabled = enabled;
    if (!enabled) stopSpeaking(); // coupe aussi la voix des chiffres
  }

  void _log(String where, Object error) {
    if (kDebugMode) debugPrint('SoundService.$where error: $error');
  }
}

/// Enveloppe le **plateau** d'un jeu : la musique de fond tourne tant que ce
/// sous-arbre est monté, et s'arrête dès qu'il est démonté.
///
/// Remplace l'ancien `GameMusicMixin`, qui démarrait la musique dans `initState`
/// — donc dès l'écran d'introduction, et jusqu'au tableau de score. En
/// l'accrochant au seul widget de gameplay, la musique ne peut plus déborder sur
/// les règles ni sur le score : il n'y a rien à se rappeler d'appeler à la sortie.
class GameplayMusic extends StatefulWidget {
  const GameplayMusic({super.key, required this.child});

  final Widget child;

  @override
  State<GameplayMusic> createState() => _GameplayMusicState();
}

class _GameplayMusicState extends State<GameplayMusic> {
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

  @override
  Widget build(BuildContext context) => widget.child;
}
