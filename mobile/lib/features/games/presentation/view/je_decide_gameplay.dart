import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../data/decision_progress_store.dart';
import '../../domain/entities/decision_form.dart';
import '../../domain/entities/decision_metrics.dart';
import '../widgets/game_system_components.dart';

const _decisionInk = Color(0xFF28234F);
const _decisionMuted = Color(0xFF7E8DB2);
const _decisionBorder = Color(0xFFD8E2F6);
const _decisionMagenta = Color(0xFFD52E83);
const _decisionViolet = Color(0xFF4E46E8);
const _decisionSoftPink = Color(0xFFFFF1F7);
const _decisionTimer = Color(0xFF2BD06F);
const _decisionWarning = Color(0xFFFFA033);


/// Écrans de transition intercalés entre les blocs d'items.
///
/// Purement narratifs : ils rythment les 30 items et ne mesurent rien. Ils sont
/// insérés aux frontières de dimension, jamais au milieu d'un bloc — et jamais
/// entre les deux cadrages d'une paire CS, qui doivent s'enchaîner.
enum DecisionInterstitial { xpFeedback, checkpoint, encouragement, badge, dimensionComplete }

/// Réponse en cours de construction pour UN item.
class _PendingAnswer {
  _PendingAnswer();

  int? selectedIndex;

  /// Changements d'avis avant validation — indicateur `decisionChangesCount` du
  /// contrat. Le premier choix ne compte pas comme un changement.
  int changes = 0;

  /// Temps de délibération accumulé hors pause.
  Duration _accumulated = Duration.zero;

  /// Instant de reprise du chronométrage ; `null` quand il est à l'arrêt.
  DateTime? _startedAt;

  /// Mesuré sur l'horloge ambiante (`package:clock`) plutôt qu'avec un
  /// `Stopwatch` : le temps de réponse est une donnée psychométrique, elle doit
  /// être vérifiable par un test déterministe.
  void start() => _startedAt ??= clock.now();

  void stop() {
    final startedAt = _startedAt;
    if (startedAt == null) return;
    _accumulated += clock.now().difference(startedAt);
    _startedAt = null;
  }

  bool get running => _startedAt != null;

  /// Temps de réponse, arrêté à la VALIDATION et non au premier tap. Choisir
  /// vite puis délibérer longuement doit produire un temps long : c'est ce qui
  /// empêche de contourner la contrainte de temps des items chronométrés. Le
  /// temps passé en pause n'est jamais compté.
  int get elapsedMs {
    final startedAt = _startedAt;
    final live = startedAt == null
        ? Duration.zero
        : clock.now().difference(startedAt);
    return (_accumulated + live).inMilliseconds;
  }
}

/// Boucle de gameplay de « Je Décide » — 30 items servis par le backend.
///
/// Le contenu ne vit plus dans ce fichier : la forme de passation
/// ([DecisionForm]) est tirée serveur à la création de session et récupérée par
/// `GET /games/sessions/{id}/decision/items`. Aucune option ne porte de qualité
/// ni de score : la correction reste serveur.
class DecisionGameplayView extends StatefulWidget {
  const DecisionGameplayView({
    super.key,
    required this.form,
    required this.onClose,
    required this.onComplete,
    this.initialIndex = 0,
  });

  final DecisionForm form;
  final VoidCallback onClose;

  /// Appelé avec les réponses des 30 items, prêtes à être soumises.
  final ValueChanged<List<DecisionItemResponse>> onComplete;

  /// Index de reprise (checkpoint sauvegardé).
  final int initialIndex;

  @override
  State<DecisionGameplayView> createState() => _DecisionGameplayViewState();
}

class _DecisionGameplayViewState extends State<DecisionGameplayView> {
  static const _criticalThreshold = 2;

  /// Repli si le serveur n'a pas envoyé de temps imparti sur un item chronométré.
  static const _fallbackTimeLimitMs = 7000;

  final Map<String, _PendingAnswer> _answers = {};
  Timer? _countdown;
  Timer? _timeoutAdvance;
  bool _timeoutAdvancePending = false;

  int _index = 0;
  DecisionInterstitial? _interstitial;
  bool _resuming = false;
  int _secondsRemaining = 0;
  bool _timedOut = false;

  /// Mode deux temps : l'écran de choix a-t-il été ouvert pour l'item courant ?
  /// Toujours vrai sur un item présenté d'un seul tenant.
  bool _choicesRevealed = false;

  /// Compte à rebours restant à démarrer.
  ///
  /// Il ne peut pas partir depuis [_enterItem] : savoir si l'item est présenté
  /// en deux temps demande la taille de l'écran, qui n'est connue qu'au premier
  /// `build`. Le drapeau est consommé dès que l'écran de CHOIX est à l'affiche —
  /// sur un item d'un seul tenant, c'est immédiatement.
  bool _countdownPending = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.form.items.length - 1);
    _resuming = widget.initialIndex > 0;
    if (!_resuming) _enterItem();
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _timeoutAdvance?.cancel();
    super.dispose();
  }

  bool get _reduceMotion =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  DecisionFormItem get _item => widget.form.items[_index];

  _PendingAnswer get _answer => _answers.putIfAbsent(_item.itemId, _PendingAnswer.new);

  int? get _selection => _answer.selectedIndex;

  bool get _isChoiceStep => _interstitial == null && !_resuming;

  bool get _usesLightShell => !_isChoiceStep;

  /// Numéro affiché : 1-based, sur le total réel de la forme.
  int get _scenarioNumber => _index + 1;

  int get _timeLimitSeconds =>
      ((_item.timeLimitMs ?? _fallbackTimeLimitMs) / 1000).ceil();

  /// XP purement visuel — aucun rapport avec le score, qui est calculé serveur.
  int get _visualXp => _answers.values.where((a) => a.selectedIndex != null).length * 12;

  // ── Cycle de vie d'un item ──────────────────────────────────────────────

  void _enterItem() {
    _countdown?.cancel();
    _timeoutAdvance?.cancel();
    _timeoutAdvancePending = false;
    _timedOut = false;
    _choicesRevealed = false;

    // L'horloge de TEMPS DE RÉPONSE part ici, à l'entrée dans l'item, et couvre
    // donc les deux temps quand l'item est découpé : lire la situation fait
    // partie de la décision, et le temps de lecture ne doit pas disparaître de
    // la mesure parce qu'on a changé la présentation.
    _answer.start();
    if (_item.isTimed) {
      _secondsRemaining = _timeLimitSeconds;
      _countdownPending = true;
    }
  }

  /// Démarre le compte à rebours si l'écran de choix est bien celui qui
  /// s'affiche. Appelé après chaque `build`, une fois la mise en page connue.
  void _armCountdownIfVisible({required bool choicesVisible}) {
    if (!_countdownPending || !choicesVisible) return;
    _countdownPending = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _item.isTimed && !_timedOut) _startCountdown(reset: false);
    });
  }

  /// Passage « lire la situation » → « choisir » sur un item en deux temps.
  ///
  /// N'arrête pas l'horloge de réponse et ne touche pas au compteur de
  /// changements d'avis : c'est une page tournée, pas un nouvel item.
  void _revealChoices() => setState(() => _choicesRevealed = true);

  void _backToSituation() => setState(() => _choicesRevealed = false);

  void _startCountdown({bool reset = true}) {
    _countdown?.cancel();
    if (reset) {
      _secondsRemaining = _timeLimitSeconds;
      _timedOut = false;
    }
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
        return;
      }
      timer.cancel();
      setState(() => _secondsRemaining = 0);
      // Temps écoulé : un choix déjà posé est validé tel quel ; sinon l'item est
      // manqué (`answered: false` → imputation serveur par dimension).
      if (_selection != null) {
        _validate();
        return;
      }
      setState(() => _timedOut = true);
      _scheduleTimeoutAdvance();
    });
  }

  void _scheduleTimeoutAdvance() {
    _timeoutAdvance?.cancel();
    _timeoutAdvancePending = true;
    _timeoutAdvance = Timer(
      _reduceMotion
          ? const Duration(milliseconds: 450)
          : const Duration(milliseconds: 1500),
      () {
        _timeoutAdvancePending = false;
        if (mounted) _validate();
      },
    );
  }

  void _select(int index) {
    if (_timedOut) return;
    SoundService.instance.playSfx(GameSfx.buttonClick);
    setState(() {
      final answer = _answer;
      // Le chronomètre continue de tourner : le temps de réponse est celui de la
      // VALIDATION. Changer d'avis reste permis — c'est un indicateur mesuré
      // (decisionChangesCount), pas une faute.
      if (answer.selectedIndex != null && answer.selectedIndex != index) {
        answer.changes++;
      }
      answer.selectedIndex = index;
    });
  }

  /// Fige la réponse de l'item courant et passe à la suite.
  void _validate() {
    _countdown?.cancel();
    _timeoutAdvance?.cancel();
    _timeoutAdvancePending = false;
    _countdownPending = false;
    _answer.stop();

    final next = _index + 1;
    if (next >= widget.form.items.length) {
      widget.onComplete(_collectResponses());
      return;
    }

    final interstitial = _interstitialBefore(next);
    // Le déverrouillage de badge est l'interstitiel le plus gratifiant du
    // parcours : il s'affichait en silence. Le son avait bien été ajouté, mais
    // sur l'écran de RÉSULTATS (révélation du profil) — pas ici, alors que
    // c'est cet écran-ci qui affiche « Badge unlocked ».
    if (interstitial == DecisionInterstitial.badge) {
      SoundService.instance.playSfx(GameSfx.badgeUnlocked);
    }
    setState(() {
      _index = next;
      _timedOut = false;
      _interstitial = interstitial;
    });
    if (interstitial == null) _enterItem();
  }

  /// Écran de transition à afficher avant l'item [nextIndex], s'il y en a un.
  ///
  /// Uniquement aux frontières de dimension : couper une paire CS par un écran
  /// narratif casserait l'enchaînement des deux cadrages.
  DecisionInterstitial? _interstitialBefore(int nextIndex) {
    final perDimension = widget.form.itemsPerDimension;
    if (perDimension <= 0 || nextIndex % perDimension != 0) return null;
    final block = nextIndex ~/ perDimension;
    const rhythm = [
      DecisionInterstitial.xpFeedback,
      DecisionInterstitial.checkpoint,
      DecisionInterstitial.badge,
      DecisionInterstitial.dimensionComplete,
      DecisionInterstitial.encouragement,
    ];
    return rhythm[(block - 1) % rhythm.length];
  }

  void _leaveInterstitial() {
    setState(() => _interstitial = null);
    _enterItem();
  }

  List<DecisionItemResponse> _collectResponses() {
    return [
      for (final item in widget.form.items)
        () {
          final answer = _answers[item.itemId];
          final chosen = answer?.selectedIndex;
          return DecisionItemResponse(
            itemId: item.itemId,
            dimension: item.dimension,
            selectedOptionId: chosen == null ? null : item.options[chosen].optionId,
            responseTimeMs: answer?.elapsedMs ?? 0,
            answered: chosen != null,
            decisionChangesCount: answer?.changes ?? 0,
          );
        }(),
    ];
  }

  // ── Pause ───────────────────────────────────────────────────────────────

  /// Droit de pause de la passation : une ouverture, 30 s (CdC pause §2-3).
  final GamePauseAllowance _pauseAllowance = GamePauseAllowance();

  /// Ce que propose le bouton de l'en-tête, ou `null` s'il n'y en a pas.
  ///
  /// Pause tant que la fenêtre unique est ouverte, « Exit mission » ensuite —
  /// le bouton ne disparaît plus quand la fenêtre est consommée
  /// ([GameMenuAffordance]).
  ///
  /// Il disparaît en revanche pendant le module « Décision sous Contrainte
  /// Temporelle », et là c'est vrai des DEUX affordances : une boîte de dialogue
  /// modale, fût-elle une confirmation de sortie, offrirait un temps de
  /// réflexion pendant les 7 s — il suffirait de l'ouvrir puis d'annuler. La
  /// contrainte de 7 s EST la mesure. L'absence dure sept secondes, puis le
  /// bouton revient sur l'item suivant.
  GameMenuAffordance? get _menuAffordance {
    if (_isChoiceStep && _item.isTimed) return null;
    return _pauseAllowance.affordance;
  }

  /// Bouton unique de l'en-tête : menu de pause, ou confirmation de sortie.
  Future<void> _openMenu() async {
    if (_isChoiceStep && _item.isTimed) return;
    if (_pauseAllowance.canOpen) return _openPauseMenu();
    // Fenêtre consommée : on ne gèle rien. Geler le temps de réponse ici
    // rendrait la pause renouvelable à volonté par simple ouverture de la
    // boîte, ce que la fenêtre unique existe pour empêcher.
    if (await GameExitConfirmDialog.show(context, missionLabel: 'journey')) {
      await DecisionProgressStore().clearCheckpoint();
      if (mounted) widget.onClose();
    }
  }

  Future<void> _openPauseMenu() async {
    // Module « Décision sous Contrainte Temporelle » : aucune pause, sans
    // exception. Mettre en pause y reviendrait à neutraliser la mesure, qui
    // EST la contrainte de 7 s.
    if (_isChoiceStep && _item.isTimed) return;
    if (!_pauseAllowance.canOpen) return;
    _pauseAllowance.open();
    SoundService.instance.playSfx(GameSfx.pauseClick);
    await _showPauseMenu();
  }

  /// Réaffiché après les règles sur le **temps restant** de la fenêtre.
  Future<void> _showPauseMenu() async {
    final countdownWasRunning =
        _isChoiceStep && _item.isTimed && !_timedOut && _secondsRemaining > 0;
    // La pause gèle TOUT ce qui court : le compte à rebours, son auto-avance, et
    // le chronomètre de temps de réponse — sinon le temps de la pause serait
    // compté comme du temps de délibération.
    _countdown?.cancel();
    _timeoutAdvance?.cancel();
    _answer.stop();

    final action = await showDialog<DecisionPauseAction>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => DecisionPauseDialog(
        countdown: _pauseAllowance.remaining,
        onCountdownExpired: () =>
            Navigator.of(dialogCtx).pop(DecisionPauseAction.resume),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case DecisionPauseAction.rules:
        await showDialog<void>(
          context: context,
          builder: (_) => const DecisionRulesDialog(),
        );
        if (!mounted) return;
        if (_pauseAllowance.canReopen) return _showPauseMenu();
      case DecisionPauseAction.exit:
        // Quitter annule la passation : pas de point de reprise, sinon le
        // message de confirmation serait faux et la règle contournable.
        if (await GameExitConfirmDialog.show(context, missionLabel: 'journey')) {
          await DecisionProgressStore().clearCheckpoint();
          if (mounted) widget.onClose();
          return;
        }
        if (!mounted) return;
        if (_pauseAllowance.canReopen) return _showPauseMenu();
      case DecisionPauseAction.resume || null:
        break;
    }
    if (!mounted) return;
    // Reprise : le temps passé en pause rejoint le budget consommé, et tout ce
    // qui était gelé repart là où il s'était arrêté. Le bouton reste « Pause »
    // tant qu'il reste du budget.
    _pauseAllowance.close();
    setState(() {});
    if (_isChoiceStep) _answer.start();
    if (countdownWasRunning) {
      _startCountdown(reset: false);
    } else if (_timeoutAdvancePending) {
      _scheduleTimeoutAdvance();
    }
  }

  Future<void> _saveFromCheckpoint() async {
    await DecisionProgressStore().saveCheckpoint(itemIndex: _index);
    if (mounted) setState(() => _interstitial = null);
    if (mounted) widget.onClose();
  }

  // ── Rendu ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final animationDuration = _reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 250);
    final shellColor = _usesLightShell
        ? const Color(0xFFF7F8FE)
        : _decisionViolet;
    return ColoredBox(
      color: shellColor,
      child: SafeArea(
        // La hauteur mesurée ICI est celle qui reste APRÈS les barres système.
        // C'était la deuxième cause du défilement : `compact` se décidait sur
        // `MediaQuery.sizeOf().height`, donc sur la hauteur brute de la dalle.
        // Sur un Redmi 360×800 dont les barres mangent 48 px, le code se croyait
        // sur un grand écran et gardait les marges généreuses alors qu'il n'y
        // avait plus la place — 45 px perdus, mesurés.
        child: LayoutBuilder(
          builder: (context, shell) => _buildShell(context, shell, animationDuration),
        ),
      ),
    );
  }

  Widget _buildShell(
    BuildContext context,
    BoxConstraints shell,
    Duration animationDuration,
  ) {
    final textScaler = MediaQuery.textScalerOf(context);
    final compact = shell.maxHeight < _kCompactShellHeight;
    final padH = shell.maxWidth < _kNarrowShellWidth ? 14.0 : 20.0;
    final padTop = compact ? 6.0 : 10.0;
    final padBottom = compact ? 10.0 : 18.0;
    final gapAfterHeader = compact ? 8.0 : 12.0;
    final gapBeforeArea = compact ? 12.0 : 18.0;
    final gapBeforeButton = compact ? 10.0 : 14.0;
    final timerBand = _timerBandHeight(compact: compact, textScaler: textScaler);

    // Hauteur offerte au scénario, calculée et non mesurée : il faut connaître
    // la mise en page (un temps ou deux) AVANT de construire la colonne, parce
    // que le bouton du bas en dépend. `_kShellHeightIsExact` (test) verrouille
    // l'égalité entre ce calcul et la hauteur réellement obtenue.
    final scenarioHeight =
        shell.maxHeight -
        padTop -
        padBottom -
        _kHeaderHeight -
        gapAfterHeader -
        _kProgressHeight -
        timerBand -
        gapBeforeArea -
        gapBeforeButton -
        _kPrimaryButtonHeight;
    final scenarioWidth = shell.maxWidth - padH * 2;

    final plan = _DecisionLayoutPlan.of(
      form: widget.form,
      width: scenarioWidth,
      height: scenarioHeight,
      textScaler: textScaler,
      ambient: DefaultTextStyle.of(context).style,
    );
    final twoSteps =
        _isChoiceStep && plan.layoutOf(_item) == _ScenarioLayout.twoSteps;
    final readingSituation = twoSteps && !_choicesRevealed;
    final choicesVisible = _isChoiceStep && !_timedOut && !readingSituation;
    _armCountdownIfVisible(choicesVisible: choicesVisible);

    // Le chronomètre ne s'affiche que là où il tourne. Pendant la lecture de la
    // situation d'un item chronométré, il restait figé sur « 7 sec » : un
    // compte à rebours qui ne descend pas dit au candidat qu'il a du temps
    // alors que la contrainte n'a pas commencé. Sa bande reste comptée dans
    // `scenarioHeight` — la densité ne bouge donc pas — mais l'écran de lecture
    // récupère ses ~39 px.
    final showTimer = _item.isTimed && choicesVisible;

    return Padding(
      padding: EdgeInsets.fromLTRB(padH, padTop, padH, padBottom),
      child: Column(
        children: [
          _DecisionProgressHeader(
            scenarioNumber: _scenarioNumber,
            totalItems: widget.form.totalItems,
            xp: _visualXp,
            onPause: _openMenu,
            affordance: _menuAffordance,
            light: _usesLightShell,
            onBack: twoSteps && !readingSituation ? _backToSituation : null,
          ),
          SizedBox(height: gapAfterHeader),
          _JourneyProgress(
            value: _scenarioNumber / widget.form.totalItems,
            light: _usesLightShell,
          ),
          // La bande du chronomètre n'est plus réservée en permanence : elle
          // coûtait ~38 px aux 24 items non chronométrés sur 30. Le gel de la
          // densité, lui, reste calculé AVEC elle (voir `scenarioHeight`) : la
          // taille du texte ne varie donc toujours pas entre un item
          // chronométré et un item libre — ce dernier dispose simplement d'un
          // peu de marge en plus.
          if (showTimer) ...[
            SizedBox(height: compact ? 8 : 10),
            _DecisionTimer(
              secondsRemaining: _secondsRemaining,
              totalSeconds: _timeLimitSeconds,
              critical: _secondsRemaining <= _criticalThreshold,
            ),
          ],
          SizedBox(height: gapBeforeArea),
          Expanded(
            child: AnimatedSwitcher(
              duration: animationDuration,
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position:
                      Tween<Offset>(
                        begin: const Offset(0.035, 0),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOut,
                        ),
                      ),
                  child: child,
                ),
              ),
              child: KeyedSubtree(
                key: ValueKey(
                  '${_interstitial ?? ''}-$_index-$_resuming-$readingSituation',
                ),
                child: _buildStep(
                  density: plan.density,
                  readingSituation: readingSituation,
                  twoSteps: twoSteps,
                ),
              ),
            ),
          ),
          if (_isChoiceStep && !_timedOut) ...[
            SizedBox(height: gapBeforeButton),
            if (readingSituation)
              GamePrimaryButton(
                key: const ValueKey('decision-reveal-choices'),
                label: 'See the options',
                icon: Icons.arrow_forward_rounded,
                onPressed: _revealChoices,
              )
            else
              GamePrimaryButton(
                key: const ValueKey('decision-continue'),
                label: 'Continue',
                onPressed: _selection == null ? null : _validate,
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildStep({
    required _ScenarioDensity density,
    required bool readingSituation,
    required bool twoSteps,
  }) {
    if (_resuming) {
      return _ResumeJourneyView(
        scenarioNumber: _scenarioNumber,
        onContinue: () {
          setState(() => _resuming = false);
          _enterItem();
        },
      );
    }
    if (_interstitial != null) {
      return switch (_interstitial!) {
        DecisionInterstitial.xpFeedback => _XpFeedbackView(
          onContinue: _leaveInterstitial,
        ),
        DecisionInterstitial.checkpoint => _CheckpointView(
          onContinue: _leaveInterstitial,
          onPause: _saveFromCheckpoint,
        ),
        DecisionInterstitial.encouragement => _EncouragementView(
          onContinue: _leaveInterstitial,
        ),
        DecisionInterstitial.badge => _BadgeView(onContinue: _leaveInterstitial),
        DecisionInterstitial.dimensionComplete => _DimensionCompleteView(
          onContinue: _leaveInterstitial,
        ),
      };
    }
    if (_item.isTimed && _timedOut) return const _TimeoutView();

    final scenario = _scenarioDataOf(_item);
    if (readingSituation) {
      return _SituationStepView(scenario: scenario, density: density);
    }
    return _ScenarioView(
      scenario: scenario,
      density: density,
      selected: _selection,
      onSelected: _select,
      recallOnly: twoSteps,
    );
  }
}

/// Vide le plan d'affichage mémorisé.
///
/// Un test qui rejoue la même forme sur plusieurs tailles d'écran doit repartir
/// d'un cache propre, sinon il mesure la décision prise au tour précédent.
@visibleForTesting
void resetDecisionLayoutPlanCacheForTest() => _DecisionLayoutPlan._cache.clear();

/// Hauteur d'ossature en dessous de laquelle on resserre les marges. Mesurée
/// APRÈS `SafeArea`, et non sur la hauteur brute de la dalle.
///
/// 760 dp utiles couvre tout le milieu de gamme 360 dp de large, Redmi 13C
/// compris : avec ses barres système en trois boutons il n'offre que 728 dp
/// utiles, et les marges généreuses lui coûtaient les derniers pixels. Le client
/// a tranché — pas de défilement prime sur la respiration.
const double _kCompactShellHeight = 760;

/// Largeur en dessous de laquelle on resserre les marges latérales.
const double _kNarrowShellWidth = 360;

/// Hauteurs fixes de l'ossature, reprises telles quelles dans le calcul du
/// budget offert au scénario. Toute modification de l'un des widgets
/// correspondants doit être répercutée ici — le test `l'ossature réserve
/// exactement ce qu'elle annonce` échoue sinon.
const double _kHeaderHeight = 52;
const double _kProgressHeight = 6;
const double _kPrimaryButtonHeight = 52;

/// Hauteur de la bande du chronomètre : l'écart qui la précède, la barre de
/// progression du temps, son interligne, et la ligne « N sec ».
double _timerBandHeight({
  required bool compact,
  required TextScaler textScaler,
}) =>
    (compact ? 8 : 10) +
    7 +
    5 +
    textScaler.scale(AppTypography.fontSizeSm) * AppTypography.lineHeightNormal;

/// Projette un item servi par le backend dans le modèle d'affichage.
///
/// La consigne (`task`) sert de titre et la situation (`vignette`) de corps :
/// aucun libellé de dimension n'est affiché, pour ne pas révéler au candidat ce
/// que l'item mesure.
///
/// Hors de l'état : [_DecisionLayoutPlan] doit pouvoir mesurer TOUS les items du
/// formulaire, pas seulement celui qui est affiché.
_ScenarioData _scenarioDataOf(DecisionFormItem item) {
  final label = switch (item.format) {
    DecisionItemFormat.temporalDecision => 'Quick choice',
    DecisionItemFormat.coherencePair => 'Two-part scenario',
    DecisionItemFormat.standard => 'Scenario',
  };
  String? part;
  if (item.pairId != null) {
    part = item.itemId.endsWith('b') ? 'Part 2 of 2' : 'Part 1 of 2';
  }
  return _ScenarioData(
    label: label,
    part: part,
    title: item.task,
    description: item.vignette,
    options: [
      for (final option in item.options) _OptionData(title: option.label),
    ],
  );
}


class _DecisionProgressHeader extends StatelessWidget {
  const _DecisionProgressHeader({
    required this.scenarioNumber,
    required this.totalItems,
    required this.xp,
    required this.onPause,
    required this.affordance,
    required this.light,
    this.onBack,
  });

  final int scenarioNumber;

  /// Total réel de la forme servie. Le libellé était figé à « / 30 », ce qui
  /// était faux dès qu'une forme d'une autre longueur était servie — la banque
  /// serveur en compte 120.
  final int totalItems;
  final int xp;
  final VoidCallback onPause;

  /// Retour à l'écran « situation » d'un item présenté en deux temps. Nul
  /// partout ailleurs : il n'existe pas d'autre retour en arrière dans une
  /// passation.
  final VoidCallback? onBack;

  /// Ce que propose le bouton, ou `null` s'il n'y en a pas — le seul cas étant
  /// le module « Décision sous Contrainte Temporelle », où ni la pause ni la
  /// sortie ne sont offertes pendant les 7 s (CdC pause §4).
  final GameMenuAffordance? affordance;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          if (affordance != null) ...[
            Semantics(
              button: true,
              label: affordance!.semanticsLabel,
              child: IconButton(
                key: const ValueKey('decision-pause-button'),
                tooltip: affordance!.tooltip,
                onPressed: onPause,
                icon: Icon(affordance!.icon),
                style: IconButton.styleFrom(
                  fixedSize: const Size(48, 48),
                  backgroundColor: Colors.white,
                  foregroundColor: _decisionInk,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(child: _title(context)),
          Container(
            height: 34,
            constraints: const BoxConstraints(minWidth: 72),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              'XP $xp',
              style: AppTypography.bodySmall.copyWith(
                color: _decisionMagenta,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Le titre porte le retour en arrière du mode deux temps — plutôt qu'un
  /// bouton de plus dans la barre, qui ne tiendrait pas à côté de la pause et du
  /// compteur d'XP sur un écran de 320 dp.
  Widget _title(BuildContext context) {
    final label = Text(
      'Scenario ${scenarioNumber.toString().padLeft(2, '0')} / $totalItems',
      style: AppTypography.titleMedium.copyWith(
        color: light ? _decisionInk : Colors.white,
        fontWeight: FontWeight.w800,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    if (onBack == null) return Semantics(header: true, child: label);
    return Semantics(
      button: true,
      label: 'Back to the situation',
      child: InkWell(
        key: const ValueKey('decision-back-to-situation'),
        onTap: onBack,
        borderRadius: BorderRadius.circular(10),
        child: Row(
          children: [
            Icon(
              Icons.arrow_back_rounded,
              size: 20,
              color: light ? _decisionInk : Colors.white,
            ),
            const SizedBox(width: 6),
            Flexible(child: label),
          ],
        ),
      ),
    );
  }
}

class _JourneyProgress extends StatelessWidget {
  const _JourneyProgress({required this.value, required this.light});

  final double value;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Journey progress ${(value * 100).round()} percent',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(99),
        child: LinearProgressIndicator(
          minHeight: 6,
          value: value.clamp(0, 1),
          backgroundColor: light
              ? _decisionBorder
              : Colors.white.withValues(alpha: 0.88),
          valueColor: const AlwaysStoppedAnimation(_decisionMagenta),
        ),
      ),
    );
  }
}

class _DecisionTimer extends StatelessWidget {
  const _DecisionTimer({
    required this.secondsRemaining,
    required this.totalSeconds,
    required this.critical,
  });

  final int secondsRemaining;
  final int totalSeconds;
  final bool critical;

  @override
  Widget build(BuildContext context) {
    final color = critical ? _decisionWarning : _decisionTimer;
    return Semantics(
      liveRegion: true,
      label: '$secondsRemaining seconds remaining',
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: (secondsRemaining / totalSeconds).clamp(0, 1),
              backgroundColor: Colors.white,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                'Quick choice',
                style: AppTypography.bodySmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
              const Spacer(),
              Text(
                '$secondsRemaining sec',
                key: const ValueKey('decision-timer-label'),
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScenarioData {
  const _ScenarioData({
    required this.label,
    required this.title,
    required this.description,
    required this.options,
    this.part,
  });

  final String label;
  final String? part;
  final String title;
  final String description;
  final List<_OptionData> options;
}

/// Énoncé d'une option. Les items de la banque n'ont qu'un libellé : pas
/// d'accroche, pas de sous-titre, pas d'étiquette.
class _OptionData {
  const _OptionData({required this.title});

  final String title;
}

/// Largeur réservée en permanence à la pastille de validation d'une option.
///
/// Réservée MÊME quand l'option n'est pas sélectionnée : si la pastille ne
/// prenait sa place qu'au moment du tap, le libellé se recomposerait et la
/// carte changerait de hauteur sous le doigt.
///
/// Resserrée de 26+10 à 20+6 : sur un écran de 320 dp, ces 10 px de largeur
/// faisaient basculer un libellé de 64 caractères de deux à trois lignes, soit
/// ~18 px de hauteur par option et ~72 px sur un item à quatre choix. C'était
/// le dernier obstacle au « sans défilement » sur le bas du parc.
const double _optionCheckSize = 20;
const double _optionCheckGap = 6;

/// Bordure d'une carte de choix : 1 px au repos, 2,2 px une fois sélectionnée.
/// La mesure retient la valeur haute, pour que sélectionner une option ne
/// puisse jamais faire grandir la mise en page au-delà de ce qui était prévu.
const double _optionBorder = 2.2;

/// Densité d'affichage d'un scénario.
///
/// Toutes les mesures de [_ScenarioView] dérivent d'un curseur unique `t` :
/// `1` = la mise en page confortable validée en maquette, `0` = la plus
/// compacte encore lisible. Le curseur n'est pas choisi à la main mais calculé
/// par [_ScenarioFit] pour que l'énoncé ET les trois choix tiennent dans la
/// hauteur disponible.
class _ScenarioDensity {
  const _ScenarioDensity._({
    required this.ambient,
    required this.cardPadH,
    required this.cardPadTop,
    required this.cardPadBottom,
    required this.chipHeight,
    required this.titleGap,
    required this.titleSize,
    required this.bodyGap,
    required this.bodySize,
    required this.gapAfterCard,
    required this.optionGap,
    required this.optionMinHeight,
    required this.optionPadH,
    required this.optionPadV,
    required this.optionSize,
  });

  /// [ambient] est le `DefaultTextStyle` sous lequel les textes seront rendus.
  ///
  /// Il doit être connu ICI, et pas seulement au rendu : un `Text` fusionne le
  /// style ambiant avec le sien, et cette fusion peut apporter un
  /// `letterSpacing` ou une graisse qui changent la largeur des glyphes. La
  /// mesure hors rendu qui l'ignorait annonçait 12 lignes là où l'écran en
  /// affichait 13 — 19 px d'écart par bloc de texte, et un item chronométré qui
  /// défilait de 9,75 px sans qu'aucun calcul ne le voie venir.
  factory _ScenarioDensity.at(double t, [TextStyle? ambient]) {
    double lerp(double comfort, double compact) =>
        compact + (comfort - compact) * t;
    return _ScenarioDensity._(
      ambient: ambient,
      cardPadH: lerp(18, 14),
      cardPadTop: lerp(18, 12),
      cardPadBottom: lerp(22, 14),
      chipHeight: lerp(31, 26),
      titleGap: lerp(14, 8),
      titleSize: lerp(18, 15.5),
      bodyGap: lerp(8, 6),
      bodySize: lerp(15.5, 13),
      gapAfterCard: lerp(22, 12),
      optionGap: lerp(12, 8),
      // Le plancher de 92 px était la vraie cause du défilement : à trois
      // options il réservait 300 px avant même que la vignette ait sa place.
      // Une option d'une seule ligne n'a pas besoin de cette hauteur.
      optionMinHeight: lerp(92, 54),
      optionPadH: lerp(18, 12),
      optionPadV: lerp(14, 10),
      optionSize: lerp(17, 14.5),
    );
  }

  final double cardPadH;
  final double cardPadTop;
  final double cardPadBottom;
  final double chipHeight;
  final double titleGap;
  final double titleSize;
  final double bodyGap;
  final double bodySize;
  final double gapAfterCard;
  final double optionGap;
  final double optionMinHeight;
  final double optionPadH;
  final double optionPadV;
  final double optionSize;

  /// Style ambiant sous lequel ces textes seront rendus, ou `null` quand la
  /// densité ne sert qu'à un écran au texte court et fixe.
  final TextStyle? ambient;

  /// Reproduit ce que fait un `Text` : le style ambiant d'abord, celui du widget
  /// par-dessus. Sans quoi la mesure et le rendu ne parlent pas de la même
  /// police.
  TextStyle _effective(TextStyle style) =>
      ambient == null ? style : ambient!.merge(style);

  TextStyle get titleStyle => _effective(
    AppTypography.headlineSmall.copyWith(
      color: _decisionInk,
      fontSize: titleSize,
      fontWeight: FontWeight.w800,
    ),
  );

  TextStyle get bodyStyle => _effective(
    AppTypography.bodyMedium.copyWith(
      color: _decisionInk,
      fontSize: bodySize,
      height: 1.38,
    ),
  );

  TextStyle get optionStyle => _effective(
    AppTypography.titleLarge.copyWith(
      color: _decisionInk,
      fontSize: optionSize,
      fontWeight: FontWeight.w800,
      height: 1.2,
    ),
  );
}

/// Les deux mises en page possibles d'un item.
///
/// Retour client, formulé deux fois : « il faut adapter le UI selon la taille de
/// l'écran afin que le scénario et les choix s'affichent entièrement sans
/// défilement ; le défilement ajoute de la friction et une perte de temps ».
///
/// La première tentative gardait « on défile » comme repli quand un item ne
/// tenait pas. C'était l'erreur de fond : tant que le défilement est le repli,
/// la remarque revient au premier item un peu long sur le premier téléphone un
/// peu petit. Le repli est désormais [twoSteps] — découper, jamais défiler.
enum _ScenarioLayout {
  /// Énoncé et choix sur un seul écran. Le cas visé, et le cas de la totalité
  /// de la banque de démo sur tout le parc mesuré.
  single,

  /// L'item ne tient pas sur un écran, même à la densité plancher : on le
  /// présente en deux temps — « lire la situation », puis « choisir ». Chacun
  /// des deux écrans tient, donc aucun ne défile.
  ///
  /// Concerne les 24 items « Intégration d'Information » de la banque serveur
  /// (jusqu'à 1167 caractères, quatre justifications dont une de 273) : ils ne
  /// tiennent sur AUCUN téléphone, quelle que soit la densité. Ce n'est pas un
  /// problème de réglage, c'est de l'arithmétique.
  twoSteps,
}

/// ⚠️ PARAMÈTRE PROVISOIRE — plancher dur de lisibilité.
///
/// La densité gelée ne descend jamais en dessous : sous ce seuil le corps de
/// texte passe sous 13,5 px, ce qu'on refuse de servir à un candidat évalué au
/// temps de réponse. Quand le plancher mord, l'item bascule en [twoSteps] — on
/// découpe, on ne rend pas de l'illisible.
///
/// Non validé à l'œil sur appareil : à confirmer avant de le considérer comme
/// définitif.
const double _kMinDensity = 0.2;

/// Plan d'affichage d'une passation : UNE densité pour toute la session, et la
/// liste des dimensions présentées en deux temps.
///
/// **Pourquoi geler la densité.** « Je décide » mesure des temps de réponse. Si
/// la taille du texte changeait d'un item au suivant — 15,5 px sur un scénario
/// court, 13,3 px sur un long — la vitesse de lecture varierait avec elle, et
/// cette variation entrerait dans le temps mesuré sans rien mesurer de la
/// décision. La présentation doit être constante pour que seule la décision
/// varie. La densité suit la taille de l'écran, jamais le scénario affiché.
///
/// **Pourquoi calibrer sur le formulaire servi.** La version précédente calibrait
/// sur une constante écrite à la main (l'item CS-12b, deux options courtes)
/// alors que les 30 items du build de démo en ont tous QUATRE. La densité
/// calculée pour un item à deux options était appliquée à des items qui en ont
/// quatre : environ 200 px de trop, et 27 items sur 27 qui défilaient sur le
/// parc réel. On mesure désormais le contenu qui sera réellement affiché.
///
/// **Pourquoi par dimension et non par item.** Si un seul item d'une dimension
/// exige deux temps, toute sa dimension y passe : sinon la vitesse de lecture
/// varierait d'un item à l'autre à l'intérieur d'une même dimension notée —
/// exactement la variation que le gel de densité existe pour supprimer.
class _DecisionLayoutPlan {
  const _DecisionLayoutPlan._({
    required this.density,
    required this.twoStepDimensions,
  });

  final _ScenarioDensity density;
  final Set<DecisionDimension> twoStepDimensions;

  _ScenarioLayout layoutOf(DecisionFormItem item) =>
      twoStepDimensions.contains(item.dimension)
      ? _ScenarioLayout.twoSteps
      : _ScenarioLayout.single;

  static final Map<String, _DecisionLayoutPlan> _cache = {};

  /// [height] est la hauteur du PIRE cas : celle qui reste au scénario quand la
  /// bande du chronomètre est affichée. Un item libre dispose en réalité d'un
  /// peu plus — c'est de la marge, pas de la densité en plus, sans quoi le gel
  /// ne tiendrait pas entre un item chronométré et un item libre.
  static _DecisionLayoutPlan of({
    required DecisionForm form,
    required double width,
    required double height,
    required TextScaler textScaler,
    required TextStyle ambient,
  }) {
    final key =
        '${_signatureOf(form)}·$width×$height'
        '×${textScaler.scale(100)}×${ambient.hashCode}';
    return _cache.putIfAbsent(key, () {
      final data = {
        for (final item in form.items) item.itemId: _scenarioDataOf(item),
      };

      // 1. Qui ne tient pas sur un écran, même au plancher ? Sa dimension
      //    entière passe en deux temps.
      final floor = _ScenarioDensity.at(_kMinDensity, ambient);
      final twoStep = <DecisionDimension>{};
      for (final item in form.items) {
        final needed = _ScenarioFit.singleHeight(
          data[item.itemId]!,
          floor,
          width,
          textScaler,
        );
        if (needed > height) twoStep.add(item.dimension);
      }

      // 2. La densité la plus confortable où TOUS les items tiennent, chacun
      //    dans le mode qui vient d'être retenu pour sa dimension.
      for (var i = 0; i < _ScenarioFit._steps; i++) {
        final t = 1 - i / (_ScenarioFit._steps - 1);
        if (t < _kMinDensity) break;
        final density = _ScenarioDensity.at(t, ambient);
        final fits = form.items.every(
          (item) => _fits(
            data[item.itemId]!,
            density,
            width,
            height,
            textScaler,
            twoStep.contains(item.dimension),
          ),
        );
        if (fits) {
          return _DecisionLayoutPlan._(
            density: density,
            twoStepDimensions: twoStep,
          );
        }
      }
      return _DecisionLayoutPlan._(density: floor, twoStepDimensions: twoStep);
    });
  }

  /// Empreinte du CONTENU du formulaire, et pas seulement de son code.
  ///
  /// Une clé bâtie sur `formCode` et le nombre d'items faisait collisionner deux
  /// formulaires distincts portant le même code : le second héritait du plan du
  /// premier, donc d'une densité calculée pour un autre texte, et son énoncé se
  /// retrouvait coupé. Repéré par une capture de référence.
  static String _signatureOf(DecisionForm form) {
    final parts = <Object>[form.formCode];
    for (final item in form.items) {
      parts
        ..add(item.itemId)
        ..add(item.task.length)
        ..add(item.vignette.length)
        ..add(item.options.length);
      for (final option in item.options) {
        parts.add(option.label.length);
      }
    }
    return '${form.items.length}#${Object.hashAll(parts)}';
  }

  static bool _fits(
    _ScenarioData data,
    _ScenarioDensity density,
    double width,
    double height,
    TextScaler textScaler,
    bool twoSteps,
  ) {
    if (!twoSteps) {
      return _ScenarioFit.singleHeight(data, density, width, textScaler) <=
          height;
    }
    return _ScenarioFit.situationHeight(data, density, width, textScaler) <=
            height &&
        _ScenarioFit.choiceHeight(data, density, width, textScaler) <= height;
  }
}

class _ScenarioFit {
  const _ScenarioFit._();

  /// Nombre de crans testés entre le confort (`t = 1`) et le compact (`t = 0`).
  static const int _steps = 9;

  /// Marge d'arrondi. Se tromper vers le bas coûte un cran de compacité de
  /// trop, invisible ; se tromper vers le haut coûte un défilement.
  static const double _safety = 8;

  /// Hauteur d'un item présenté sur un seul écran : carte d'énoncé + choix.
  static double singleHeight(
    _ScenarioData data,
    _ScenarioDensity density,
    double width,
    TextScaler textScaler,
  ) =>
      _cardHeight(data, density, width, textScaler, withDescription: true) +
      density.gapAfterCard +
      _safety +
      optionsHeight(data, density, width, textScaler);

  /// Hauteur de l'écran 1 du mode deux temps : la carte d'énoncé seule, sans
  /// puce.
  ///
  /// La puce (« Scenario », « Quick choice ») saute en mode deux temps : elle
  /// répète ce que l'en-tête affiche déjà, et ses 36 px décidaient à eux seuls
  /// du défilement de la plus longue situation de la banque sur un écran de
  /// 320 dp. Le bouton « Voir les choix » vit dans l'ossature, hors de cette
  /// mesure, exactement comme le bouton « Continue » de l'écran de choix.
  static double situationHeight(
    _ScenarioData data,
    _ScenarioDensity density,
    double width,
    TextScaler textScaler,
  ) =>
      _cardHeight(
        data,
        density,
        width,
        textScaler,
        withChip: false,
        withDescription: true,
      ) +
      _safety;

  /// Hauteur de l'écran 2 du mode deux temps : la consigne rappelée + les choix.
  ///
  /// La situation n'y est PAS reprise — c'est tout l'intérêt du découpage. Seule
  /// la consigne l'est, parce qu'un candidat qui choisit doit pouvoir relire ce
  /// qu'on lui demande sans revenir en arrière. Et elle est rappelée en TEXTE
  /// NU, sans carte : le fond blanc, ses marges et son ombre coûtaient ~55 px
  /// pour ne rien ajouter à la lecture d'une seule ligne de consigne.
  static double choiceHeight(
    _ScenarioData data,
    _ScenarioDensity density,
    double width,
    TextScaler textScaler,
  ) =>
      recallHeight(data, density, width, textScaler) +
      density.gapAfterCard +
      _safety +
      optionsHeight(data, density, width, textScaler);

  /// Hauteur de la consigne rappelée en texte nu.
  static double recallHeight(
    _ScenarioData data,
    _ScenarioDensity density,
    double width,
    TextScaler textScaler,
  ) => textHeight(data.title, density.titleStyle, width, textScaler);

  static double _cardHeight(
    _ScenarioData data,
    _ScenarioDensity density,
    double width,
    TextScaler textScaler, {
    required bool withDescription,
    bool withChip = true,
  }) {
    final innerWidth = width - density.cardPadH * 2;
    final head =
        density.cardPadTop +
        (withChip ? density.chipHeight + density.titleGap : 0) +
        textHeight(data.title, density.titleStyle, innerWidth, textScaler);
    if (!withDescription) return head + density.cardPadBottom;
    return head +
        density.bodyGap +
        textHeight(
          data.description,
          density.bodyStyle,
          innerWidth,
          textScaler,
        ) +
        density.cardPadBottom;
  }

  static double optionsHeight(
    _ScenarioData data,
    _ScenarioDensity density,
    double width,
    TextScaler textScaler,
  ) {
    var total = 0.0;
    for (var i = 0; i < data.options.length; i++) {
      total += optionHeight(data.options[i], density, width, textScaler);
      if (i != data.options.length - 1) total += density.optionGap;
    }
    return total;
  }

  static double optionHeight(
    _OptionData option,
    _ScenarioDensity density,
    double width,
    TextScaler textScaler,
  ) {
    // `- _optionBorder * 2` : la bordure ne s'ajoute pas qu'à la HAUTEUR de la
    // carte, elle retranche aussi de la largeur offerte au libellé. Oubliée, la
    // prédiction était de 4,4 px trop large — assez pour croire qu'un libellé
    // tenait en deux lignes quand il en prenait trois, soit ~18 px de retard par
    // option et le défilement résiduel de 16 à 21 px mesuré sur un 320 dp.
    final innerWidth =
        width -
        density.optionPadH * 2 -
        _optionBorder * 2 -
        _optionCheckSize -
        _optionCheckGap;
    final label = textHeight(
      option.title,
      density.optionStyle,
      innerWidth,
      textScaler,
    );
    // `+ _optionBorder * 2` : la bordure d'un [Container] s'ajoute à sa taille.
    // Oubliée, elle produisait un débordement de deux pixels par carte.
    final needed = label + density.optionPadV * 2 + _optionBorder * 2;
    return needed > density.optionMinHeight ? needed : density.optionMinHeight;
  }

  static double textHeight(
    String text,
    TextStyle style,
    double maxWidth,
    TextScaler textScaler,
  ) {
    if (maxWidth <= 0) return 0;
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout(maxWidth: maxWidth);
    return painter.height;
  }
}

/// Écran 1 du mode deux temps : la situation, seule, en grand.
///
/// Le bouton qui mène aux choix vit dans l'ossature, à la place du bouton
/// « Continue » : la hauteur réservée en bas de l'écran est ainsi la même sur
/// les deux temps, et la densité gelée reste valable pour les deux.
class _SituationStepView extends StatelessWidget {
  const _SituationStepView({required this.scenario, required this.density});

  final _ScenarioData scenario;
  final _ScenarioDensity density;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _ScenarioCard(
        key: const ValueKey('decision-situation-card'),
        data: scenario,
        density: density,
        showChip: false,
      ),
    );
  }
}

/// Écran d'un item : soit l'ensemble énoncé + choix ([_ScenarioLayout.single]),
/// soit le seul écran de choix du mode deux temps, où la consigne est rappelée
/// mais pas la situation.
///
/// **Pourquoi un [SingleChildScrollView] alors que rien ne doit défiler.** La
/// hauteur est PRÉDITE, par mesure de texte hors rendu. Une prédiction basse de
/// deux pixels — une bordure oubliée, un arrondi de police — produirait sinon un
/// débordement de rendu, c'est-à-dire du contenu définitivement inatteignable.
/// Le conteneur défilable est un filet de sécurité, pas une mise en page : que
/// son extension de défilement soit nulle sur les 150 items des deux banques et
/// sur sept tailles d'écran est vérifié par
/// `test/features/games/presentation/je_decide_no_scroll_test.dart`.
class _ScenarioView extends StatelessWidget {
  const _ScenarioView({
    required this.scenario,
    required this.density,
    required this.selected,
    required this.onSelected,
    this.recallOnly = false,
  });

  final _ScenarioData scenario;
  final _ScenarioDensity density;
  final int? selected;
  final ValueChanged<int> onSelected;

  /// Vrai sur l'écran de choix du mode deux temps : la carte ne porte que la
  /// consigne, la situation ayant été lue à l'écran précédent.
  final bool recallOnly;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (recallOnly)
            // Consigne rappelée en texte nu : la carte blanche, ses marges et
            // son ombre coûtaient ~55 px pour une seule ligne déjà lue à
            // l'écran précédent.
            Text(
              scenario.title,
              key: const ValueKey('decision-task-recall'),
              style: density.titleStyle,
            )
          else
            _ScenarioCard(data: scenario, density: density),
          SizedBox(height: density.gapAfterCard),
          for (var i = 0; i < scenario.options.length; i++) ...[
            _DecisionChoiceCard(
              key: ValueKey('decision-option-$i'),
              data: scenario.options[i],
              selected: selected == i,
              density: density,
              onTap: () => onSelected(i),
            ),
            if (i != scenario.options.length - 1)
              SizedBox(height: density.optionGap),
          ],
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({
    super.key,
    required this.data,
    this.density,
    this.showChip = true,
  });

  final _ScenarioData data;

  /// Absente sur les écrans intercalaires, dont le texte est court et fixe :
  /// ils gardent la densité de confort.
  final _ScenarioDensity? density;

  /// Faux en mode deux temps : la puce répète ce que l'en-tête affiche déjà, et
  /// ses 36 px décidaient du défilement de la plus longue situation de la
  /// banque sur un écran de 320 dp.
  final bool showChip;

  @override
  Widget build(BuildContext context) {
    final density = this.density ?? _ScenarioDensity.at(1);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        density.cardPadH,
        density.cardPadTop,
        density.cardPadH,
        density.cardPadBottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A211A63),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showChip) ...[
            SizedBox(
              height: density.chipHeight,
              child: Row(
                children: [
                  Flexible(
                    child: _OutlinedChip(
                      label: data.label,
                      accent: _decisionMagenta,
                      height: density.chipHeight,
                    ),
                  ),
                  if (data.part != null) ...[
                    const SizedBox(width: 10),
                    Flexible(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: _OutlinedChip(
                          label: data.part!,
                          accent: _decisionMuted,
                          height: density.chipHeight,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            SizedBox(height: density.titleGap),
          ],
          Text(data.title, style: density.titleStyle),
          SizedBox(height: density.bodyGap),
          Text(data.description, style: density.bodyStyle),
        ],
      ),
    );
  }
}

class _DecisionChoiceCard extends StatelessWidget {
  const _DecisionChoiceCard({
    super.key,
    required this.data,
    required this.selected,
    required this.density,
    required this.onTap,
  });

  final _OptionData data;
  final bool selected;
  final _ScenarioDensity density;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Semantics(
      button: true,
      selected: selected,
      label: data.title,
      child: Material(
        color: selected ? _decisionSoftPink : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          // Sélection d'une option : c'est le geste le plus fréquent du jeu, et
          // il était muet.
          //
          // Le son est NEUTRE (clic générique) et le restera : « Je Décide » ne
          // dit jamais si un choix est bon — les scores ne quittent pas le
          // backend. Un son de réussite ou d'erreur ici divulguerait la clé de
          // correction que la projection s'applique justement à retirer.
          onTap: () {
            SoundService.instance.playSfx(GameSfx.buttonClick);
            onTap();
          },
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            width: double.infinity,
            constraints: BoxConstraints(minHeight: density.optionMinHeight),
            padding: EdgeInsets.symmetric(
              horizontal: density.optionPadH,
              vertical: density.optionPadV,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? _decisionMagenta : _decisionBorder,
                width: selected ? 2.2 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12211A63),
                  blurRadius: 14,
                  offset: Offset(0, 7),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: Text(data.title, style: density.optionStyle)),
                const SizedBox(width: _optionCheckGap),
                // Gouttière réservée en permanence : voir [_optionCheckSize].
                SizedBox(
                  width: _optionCheckSize,
                  height: _optionCheckSize,
                  child: selected
                      ? const DecoratedBox(
                          decoration: BoxDecoration(
                            color: _decisionMagenta,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedChip extends StatelessWidget {
  const _OutlinedChip({
    required this.label,
    required this.accent,
    this.height = 31,
  });

  final String label;
  final Color accent;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: height, minWidth: 82),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
      decoration: BoxDecoration(
        color: accent == _decisionMagenta ? _decisionSoftPink : Colors.white,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: _decisionBorder),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppTypography.bodySmall.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Mesures des écrans intercalaires (XP, badge, checkpoint, encouragement,
/// fin de dimension, expiration).
///
/// Ces écrans sont décoratifs et ne portent qu'un bouton, mais leurs valeurs
/// fixes — pastille de 100 px, respirations de 26 à 78 px — débordaient de 52 px
/// sur un écran de 320×568 et imposaient un défilement. Le client ne fait pas la
/// différence entre « défiler sur un scénario » et « défiler dans Je décide » :
/// on resserre donc aussi ces écrans-là.
///
/// Seuil à 640 px de haut : mesuré, un 360×640 ne défile déjà pas.
class _InterstitialMetrics {
  _InterstitialMetrics(BuildContext context)
    : compact = MediaQuery.sizeOf(context).height < 640;

  final bool compact;

  /// Écart entre la carte décorative et la carte blanche.
  double get gapAfterCard => compact ? 12 : 30;

  /// Le même écart pour l'écran d'expiration, qui l'avait à 78 px. Réduit pour
  /// TOUTES les tailles : à 78 px, cet écran défilait déjà sur un 360×640, un
  /// gabarit très courant, et il est atteint par tout candidat qui laisse filer
  /// les 7 secondes du module chronométré.
  double get gapAfterCardWide => compact ? 12 : 24;

  /// Diamètre de la pastille ronde.
  double get medallion => compact ? 74 : 100;

  double get padTop => compact ? 20 : 30;
  double get gapAfterMedallion => compact ? 14 : 26;
  double get gapBeforeButton => compact ? 14 : 20;

  /// Respirations des écrans « clairs » (checkpoint, encouragement, fin de
  /// dimension), dont la structure diffère : une pastille, deux blocs de texte,
  /// une carte, un ou deux boutons.
  double get lightGapSm => compact ? 8 : 18;
  double get lightGapMd => compact ? 10 : 20;
  double get lightGapLg => compact ? 12 : 24;
  double get lightCardPad => compact ? 13 : 18;

  /// Diamètre du médaillon de badge des écrans clairs.
  double get badgeMark => compact ? 84 : 112;
}

class _TimeoutView extends StatelessWidget {
  const _TimeoutView();

  @override
  Widget build(BuildContext context) {
    final m = _InterstitialMetrics(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          const _ScenarioCard(
            data: _ScenarioData(
              label: 'Quick choice',
              title: 'Choose quickly',
              description: 'The timed choice has ended.',
              options: [],
            ),
          ),
          SizedBox(height: m.gapAfterCardWide),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, m.padTop, 24, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                Container(
                  width: m.medallion,
                  height: m.medallion,
                  decoration: BoxDecoration(
                    color: _decisionSoftPink,
                    shape: BoxShape.circle,
                    border: Border.all(color: _decisionMagenta, width: 2),
                  ),
                  child: Icon(
                    Icons.front_hand_rounded,
                    color: const Color(0xFFFF5B32),
                    size: m.medallion * 0.58,
                  ),
                ),
                SizedBox(height: m.gapAfterMedallion),
                Text(
                  'Time’s up - moving on.',
                  key: const ValueKey('decision-timeout-title'),
                  textAlign: TextAlign.center,
                  style: AppTypography.headlineSmall.copyWith(
                    color: _decisionInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'No worries. The journey continues.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _decisionMuted,
                  ),
                ),
                const SizedBox(height: 22),
                GamePrimaryButton(label: 'Continuing...', onPressed: null),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _XpFeedbackView extends StatelessWidget {
  const _XpFeedbackView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final m = _InterstitialMetrics(context);
    return SingleChildScrollView(
      child: Column(
        children: [
          const _ScenarioCard(
            data: _ScenarioData(
              label: 'Scenario',
              title: 'Reward timing',
              description: 'Your selected choice is saved for the journey.',
              options: [],
            ),
          ),
          SizedBox(height: m.gapAfterCard),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, m.padTop, 24, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                Container(
                  width: m.medallion,
                  height: m.medallion,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _decisionSoftPink,
                    shape: BoxShape.circle,
                    border: Border.all(color: _decisionMagenta, width: 2),
                  ),
                  child: Text(
                    '+12 XP',
                    style: AppTypography.titleLarge.copyWith(
                      color: _decisionMagenta,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                SizedBox(height: m.gapAfterMedallion),
                Text(
                  'Reflection complete',
                  key: const ValueKey('decision-xp-title'),
                  style: AppTypography.headlineSmall.copyWith(
                    color: _decisionInk,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your choice has been saved.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _decisionMuted,
                  ),
                ),
                SizedBox(height: m.gapBeforeButton),
                GamePrimaryButton(
                  key: const ValueKey('decision-next-scenario'),
                  label: 'Next scenario',
                  onPressed: onContinue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeView extends StatelessWidget {
  const _BadgeView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            children: [
              Container(
                width: 126,
                height: 126,
                decoration: const BoxDecoration(
                  color: Color(0xFFF1EEFF),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 92,
                    height: 92,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC5DE49),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: _decisionWarning,
                      size: 58,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'Badge unlocked',
                key: const ValueKey('decision-badge-title'),
                style: AppTypography.headlineMedium.copyWith(
                  color: _decisionInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Steady Explorer',
                style: AppTypography.titleLarge.copyWith(
                  color: _decisionMagenta,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'You’re building a thoughtful\ndecision journey.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: _decisionMuted,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 22),
              GamePrimaryButton(
                key: const ValueKey('decision-badge-continue'),
                label: 'Continue',
                onPressed: onContinue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckpointView extends StatelessWidget {
  const _CheckpointView({required this.onContinue, required this.onPause});

  final VoidCallback onContinue;
  final VoidCallback onPause;

  @override
  Widget build(BuildContext context) {
    final m = _InterstitialMetrics(context);
    return _LightStepScroll(
      children: [
        SizedBox(height: m.lightGapSm),
        const _BadgeMark(label: 'MB', color: _decisionViolet),
        SizedBox(height: m.lightGapMd),
        Text(
          'Halfway there',
          key: const ValueKey('decision-checkpoint-title'),
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: _decisionInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You’ve completed 15 of 30 scenarios.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: _decisionMuted),
        ),
        SizedBox(height: m.lightGapSm),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(m.lightCardPad),
          decoration: _lightCardDecoration(),
          child: Column(
            children: [
              const Row(
                children: [
                  Expanded(
                    child: Text(
                      'Journey progress',
                      style: TextStyle(
                        color: _decisionInk,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '50%',
                    style: TextStyle(
                      color: _decisionMagenta,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              SizedBox(height: m.compact ? 8 : 12),
              const _JourneyProgress(value: 0.5, light: true),
              SizedBox(height: m.lightGapSm),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: const [
                  _MilestoneChip(label: 'Thoughtful'),
                  _MilestoneChip(label: 'Focused'),
                  _MilestoneChip(label: 'Adaptive'),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: m.lightGapLg),
        GamePrimaryButton(
          key: const ValueKey('decision-checkpoint-continue'),
          label: 'Continue journey',
          onPressed: onContinue,
        ),
        SizedBox(height: m.compact ? 8 : 10),
        GameOutlineButton(
          key: const ValueKey('decision-checkpoint-pause'),
          label: 'Take a short pause',
          onPressed: onPause,
        ),
      ],
    );
  }
}

class _EncouragementView extends StatelessWidget {
  const _EncouragementView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _LightStepScroll(
      children: [
        const SizedBox(height: 48),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
          decoration: _lightCardDecoration(),
          child: Column(
            children: [
              const _BadgeMark(label: '16', color: _decisionMagenta),
              const SizedBox(height: 28),
              Text(
                'Nice reflection. Let’s continue.',
                key: const ValueKey('decision-encouragement-title'),
                textAlign: TextAlign.center,
                style: AppTypography.headlineSmall.copyWith(
                  color: _decisionInk,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Another scenario is ready.',
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(color: _decisionMuted),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          key: const ValueKey('decision-encouragement-continue'),
          label: 'Continue',
          onPressed: onContinue,
        ),
      ],
    );
  }
}



class _ResumeJourneyView extends StatelessWidget {
  const _ResumeJourneyView({required this.scenarioNumber, required this.onContinue});

  final int scenarioNumber;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _LightStepScroll(
      children: [
        const SizedBox(height: 30),
        const _BadgeMark(label: 'SE', color: _decisionMagenta),
        const SizedBox(height: 22),
        Text(
          'Welcome back',
          key: const ValueKey('decision-welcome-back'),
          style: AppTypography.headlineMedium.copyWith(
            color: _decisionInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'You’re halfway through your decision journey.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: _decisionMuted),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: _lightCardDecoration(),
          child: const Column(
            children: [
              _CompletionLine(label: 'Completed', value: '15 / 30'),
              SizedBox(height: 16),
              _JourneyProgress(value: 0.5, light: true),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          key: const ValueKey('decision-resume-continue'),
          label: 'Continue from scenario $scenarioNumber',
          onPressed: onContinue,
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline_rounded, color: _decisionMagenta),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'Your previous choices are saved.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(color: _decisionMuted),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DimensionCompleteView extends StatelessWidget {
  const _DimensionCompleteView({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return _LightStepScroll(
      children: [
        const SizedBox(height: 20),
        const _BadgeMark(label: 'RN', color: _decisionMagenta),
        const SizedBox(height: 20),
        Text(
          'New milestone',
          style: AppTypography.bodyMedium.copyWith(color: _decisionMuted),
        ),
        const SizedBox(height: 5),
        Text(
          'Risk Navigator',
          key: const ValueKey('decision-dimension-complete'),
          style: AppTypography.headlineMedium.copyWith(
            color: _decisionInk,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: _lightCardDecoration(),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MiniBadge(label: 'AE', active: true),
              _MiniBadge(label: 'RN', active: true),
              _MiniBadge(label: 'QC', active: false),
              _MiniBadge(label: 'SE', active: false),
              _MiniBadge(label: 'SP', active: false),
            ],
          ),
        ),
        const SizedBox(height: 28),
        GamePrimaryButton(
          key: const ValueKey('decision-dimension-continue'),
          label: 'Continue',
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _LightStepScroll extends StatelessWidget {
  const _LightStepScroll({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: Column(children: children));
  }
}

class _BadgeMark extends StatelessWidget {
  const _BadgeMark({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final size = _InterstitialMetrics(context).badgeMark;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
      ),
      child: Container(
        width: size * 0.64,
        height: size * 0.64,
        alignment: Alignment.center,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Text(
          label,
          style: AppTypography.headlineSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? _decisionMagenta : const Color(0xFFF0F2F8),
        shape: BoxShape.circle,
        border: Border.all(color: active ? _decisionMagenta : _decisionBorder),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: active ? Colors.white : _decisionMuted,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _MilestoneChip extends StatelessWidget {
  const _MilestoneChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: _decisionSoftPink,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: _decisionMagenta,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CompletionLine extends StatelessWidget {
  const _CompletionLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: _decisionInk)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: _decisionInk,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

BoxDecoration _lightCardDecoration() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: _decisionBorder),
  boxShadow: const [
    BoxShadow(color: Color(0x12211A63), blurRadius: 18, offset: Offset(0, 8)),
  ],
);

enum DecisionPauseAction { resume, rules, exit }

class DecisionPauseDialog extends StatelessWidget {
  const DecisionPauseDialog({
    super.key,
    this.gameplayActive = true,
    this.countdown,
    this.onCountdownExpired,
  });

  final bool gameplayActive;

  /// Temps restant sur la fenêtre unique de pause. Null hors passation (menu
  /// de parcours), où aucune mesure ne court.
  final Duration? countdown;
  final VoidCallback? onCountdownExpired;

  @override
  Widget build(BuildContext context) {
    return GamePauseScaffold(
      titleKey: const ValueKey('decision-pause-dialog'),
      countdown: countdown,
      onCountdownExpired: onCountdownExpired,
      description: gameplayActive
          ? 'Your current choice and timer are safely paused.'
          : 'Take a break, review the rules or leave the journey.',
      buttons: [
        GamePrimaryButton(
          key: const ValueKey('decision-pause-dialog-resume'),
          label: gameplayActive ? 'Resume' : 'Continue',
          onPressed: () =>
              Navigator.of(context).pop(DecisionPauseAction.resume),
        ),
        GameOutlineButton(
          key: const ValueKey('decision-view-rules'),
          label: 'View rules / Help',
          onPressed: () =>
              Navigator.of(context).pop(DecisionPauseAction.rules),
        ),
        GamePauseExitButton(
          label: gameplayActive ? 'Save and exit' : 'Exit journey',
          onPressed: () => Navigator.of(context).pop(DecisionPauseAction.exit),
        ),
      ],
    );
  }
}

class DecisionRulesDialog extends StatelessWidget {
  const DecisionRulesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('How to play'),
      content: const SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RuleLine(
              icon: Icons.article_outlined,
              text: 'Read each everyday scenario.',
            ),
            _RuleLine(
              icon: Icons.touch_app_rounded,
              text: 'Choose what feels natural — there is no right or wrong.',
            ),
            _RuleLine(
              icon: Icons.timer_outlined,
              text: 'Quick choices allow 7 seconds and move on calmly.',
            ),
            _RuleLine(
              icon: Icons.link_rounded,
              text: 'Two-part scenarios always stay together.',
            ),
            _RuleLine(
              icon: Icons.lock_outline_rounded,
              text: 'Your individual choices stay private.',
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          key: const ValueKey('decision-rules-back'),
          onPressed: () {
                  SoundService.instance.playSfx(GameSfx.buttonClick);
                  Navigator.of(context).pop();
                },
          child: const Text('Back'),
        ),
      ],
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _decisionMagenta),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: _decisionInk, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
