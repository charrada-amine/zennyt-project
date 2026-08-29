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

    _answer.start();
    if (_item.isTimed) {
      _secondsRemaining = _timeLimitSeconds;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _item.isTimed) _startCountdown(reset: false);
      });
    }
  }

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

  Future<void> _openPauseMenu() async {
    SoundService.instance.playSfx(GameSfx.pauseClick);
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
      builder: (_) => const DecisionPauseDialog(),
    );
    if (!mounted) return;
    switch (action) {
      case DecisionPauseAction.rules:
        await showDialog<void>(
          context: context,
          builder: (_) => const DecisionRulesDialog(),
        );
        if (mounted) await _openPauseMenu();
        return;
      case DecisionPauseAction.exit:
        await DecisionProgressStore().saveCheckpoint(itemIndex: _index);
        if (mounted) widget.onClose();
        return;
      case DecisionPauseAction.resume || null:
        if (!mounted) return;
        if (_isChoiceStep) _answer.start();
        if (countdownWasRunning) {
          _startCountdown(reset: false);
        } else if (_timeoutAdvancePending) {
          _scheduleTimeoutAdvance();
        }
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
    final shellColor = _usesLightShell ? const Color(0xFFF7F8FE) : _decisionViolet;
    return ColoredBox(
      color: shellColor,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          child: Column(
            children: [
              _DecisionProgressHeader(
                scenarioNumber: _scenarioNumber,
                xp: _visualXp,
                onPause: _openPauseMenu,
                light: _usesLightShell,
              ),
              const SizedBox(height: 12),
              _JourneyProgress(
                value: _scenarioNumber / widget.form.totalItems,
                light: _usesLightShell,
              ),
              if (_isChoiceStep && _item.isTimed) ...[
                const SizedBox(height: 10),
                _DecisionTimer(
                  secondsRemaining: _secondsRemaining,
                  totalSeconds: _timeLimitSeconds,
                  critical: _secondsRemaining <= _criticalThreshold,
                ),
              ],
              const SizedBox(height: 18),
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
                    key: ValueKey('${_interstitial ?? ''}-$_index-$_resuming'),
                    child: _buildStep(),
                  ),
                ),
              ),
              if (_isChoiceStep && !_timedOut) ...[
                const SizedBox(height: 14),
                GamePrimaryButton(
                  key: const ValueKey('decision-continue'),
                  label: 'Continue',
                  onPressed: _selection == null ? null : _validate,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
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
        DecisionInterstitial.xpFeedback => _XpFeedbackView(onContinue: _leaveInterstitial),
        DecisionInterstitial.checkpoint => _CheckpointView(
          onContinue: _leaveInterstitial,
          onPause: _saveFromCheckpoint,
        ),
        DecisionInterstitial.encouragement =>
          _EncouragementView(onContinue: _leaveInterstitial),
        DecisionInterstitial.badge => _BadgeView(onContinue: _leaveInterstitial),
        DecisionInterstitial.dimensionComplete =>
          _DimensionCompleteView(onContinue: _leaveInterstitial),
      };
    }
    if (_item.isTimed && _timedOut) return const _TimeoutView();

    return _ScenarioView(
      scenario: _scenarioData(_item),
      selected: _selection,
      onSelected: _select,
    );
  }

  /// Projette un item servi par le backend dans le modèle d'affichage.
  ///
  /// La consigne (`task`) sert de titre et la situation (`vignette`) de corps :
  /// aucun libellé de dimension n'est affiché, pour ne pas révéler au candidat ce
  /// que l'item mesure.
  _ScenarioData _scenarioData(DecisionFormItem item) {
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
      options: [for (final option in item.options) _OptionData(title: option.label)],
    );
  }
}


class _DecisionProgressHeader extends StatelessWidget {
  const _DecisionProgressHeader({
    required this.scenarioNumber,
    required this.xp,
    required this.onPause,
    required this.light,
  });

  final int scenarioNumber;
  final int xp;
  final VoidCallback onPause;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Semantics(
            button: true,
            label: 'Pause decision journey',
            child: IconButton(
              key: const ValueKey('decision-pause-button'),
              tooltip: 'Pause',
              onPressed: onPause,
              icon: const Icon(Icons.pause_rounded),
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
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                'Scenario ${scenarioNumber.toString().padLeft(2, '0')} / 30',
                style: AppTypography.titleMedium.copyWith(
                  color: light ? _decisionInk : Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
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

class _ScenarioView extends StatelessWidget {
  const _ScenarioView({
    required this.scenario,
    required this.selected,
    required this.onSelected,
  });

  final _ScenarioData scenario;
  final int? selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _ScenarioCard(data: scenario),
          const SizedBox(height: 22),
          for (var i = 0; i < scenario.options.length; i++) ...[
            _DecisionChoiceCard(
              key: ValueKey('decision-option-$i'),
              data: scenario.options[i],
              selected: selected == i,
              onTap: () => onSelected(i),
            ),
            if (i != scenario.options.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _ScenarioCard extends StatelessWidget {
  const _ScenarioCard({required this.data});

  final _ScenarioData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
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
        children: [
          Row(
            children: [
              Flexible(
                child: _OutlinedChip(
                  label: data.label,
                  accent: _decisionMagenta,
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
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Text(
            data.title,
            style: AppTypography.headlineSmall.copyWith(
              color: _decisionInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data.description,
            style: AppTypography.bodyMedium.copyWith(
              color: _decisionInk,
              fontSize: 15.5,
              height: 1.38,
            ),
          ),
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
    required this.onTap,
  });

  final _OptionData data;
  final bool selected;
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
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
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
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        style: AppTypography.titleLarge.copyWith(
                          color: _decisionInk,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected) ...[
                  const SizedBox(width: 10),
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: _decisionMagenta,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutlinedChip extends StatelessWidget {
  const _OutlinedChip({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 31, minWidth: 82),
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

class _TimeoutView extends StatelessWidget {
  const _TimeoutView();

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 78),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: _decisionSoftPink,
                    shape: BoxShape.circle,
                    border: Border.all(color: _decisionMagenta, width: 2),
                  ),
                  child: const Icon(
                    Icons.front_hand_rounded,
                    color: Color(0xFFFF5B32),
                    size: 58,
                  ),
                ),
                const SizedBox(height: 28),
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
          const SizedBox(height: 30),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
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
                const SizedBox(height: 26),
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
                const SizedBox(height: 20),
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
    return _LightStepScroll(
      children: [
        const SizedBox(height: 18),
        const _BadgeMark(label: 'MB', color: _decisionViolet),
        const SizedBox(height: 20),
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
        const SizedBox(height: 18),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
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
              const SizedBox(height: 12),
              const _JourneyProgress(value: 0.5, light: true),
              const SizedBox(height: 18),
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
        const SizedBox(height: 24),
        GamePrimaryButton(
          key: const ValueKey('decision-checkpoint-continue'),
          label: 'Continue journey',
          onPressed: onContinue,
        ),
        const SizedBox(height: 10),
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
    return Container(
      width: 112,
      height: 112,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
      ),
      child: Container(
        width: 72,
        height: 72,
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
  const DecisionPauseDialog({super.key, this.gameplayActive = true});

  final bool gameplayActive;

  @override
  Widget build(BuildContext context) {
    return GamePauseScaffold(
      titleKey: const ValueKey('decision-pause-dialog'),
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
