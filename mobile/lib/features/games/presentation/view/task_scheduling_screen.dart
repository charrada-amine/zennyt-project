import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/game_type.dart';
import '../../domain/entities/mini_game.dart';
import '../../domain/entities/task_scheduling_metrics.dart';
import '../games_providers.dart';
import '../widgets/game_system_components.dart';

/// Planifik #2 — « Ordonnancement de tâches ».
///
/// Le joueur ordonne un lot de tâches (tap-to-place) en respectant leurs
/// DÉPENDANCES (une tâche après ses prérequis) et leurs CONTRAINTES HORAIRES
/// (échéance de position). L'écran MESURE (dépendances respectées ? contraintes
/// ok ? cohérence 0–2 ? nombre de réajustements) et **n'attribue aucun score** :
/// le barème /10 est calculé côté serveur (ou mock hors-ligne).
class TaskSchedulingScreen extends ConsumerStatefulWidget {
  const TaskSchedulingScreen({super.key});

  @override
  ConsumerState<TaskSchedulingScreen> createState() =>
      _TaskSchedulingScreenState();
}

/// Une tâche à ordonnancer. [deps] = index des prérequis ; [deadline] = position
/// maximale autorisée (0-based, null = pas de contrainte horaire).
class _Task {
  const _Task({required this.label, this.deps = const [], this.deadline});
  final String label;
  final List<int> deps;
  final int? deadline;
}

// Lot de 9 tâches (10–12 visé par la fiche ; 9 reste jouable et lisible).
const List<_Task> _caseTasks = [
  _Task(label: 'Gather clues'),
  _Task(label: 'Sort clues', deps: [0]),
  _Task(label: 'Interview A', deps: [0]),
  _Task(label: 'Interview B', deps: [0]),
  _Task(label: 'Inspect scene', deps: [0], deadline: 4),
  _Task(label: 'Cross-check', deps: [2, 3]),
  _Task(label: 'Lab analysis', deps: [4], deadline: 6),
  _Task(label: 'Build timeline', deps: [1, 5]),
  _Task(label: 'Write report', deps: [6, 7]),
];

enum _Stage { intro, howToPlay, gameplay, score }

class _TaskSchedulingScreenState extends ConsumerState<TaskSchedulingScreen> {
  _Stage _stage = _Stage.intro;

  // Emplacements ordonnés (null = vide) + réserve (indices de tâches).
  late List<int?> _slots;
  late List<int> _pool;
  int _adjustmentCount = 0; // réajustements = retraits d'un emplacement rempli
  bool _busy = false;
  bool _reviewingRules = false;

  Future<GameSession>? _sessionStart;
  GameSession? _serverSession;

  @override
  void initState() {
    super.initState();
    _resetBoard();
  }

  void _resetBoard() {
    _slots = List<int?>.filled(_caseTasks.length, null);
    _pool = List<int>.generate(_caseTasks.length, (i) => i)..shuffle();
    _adjustmentCount = 0;
    _serverSession = null;
    _busy = false;
  }

  /// Droit de pause de la partie : une ouverture, 30 s (CdC pause §2-3).
  final GamePauseAllowance _pauseAllowance = GamePauseAllowance();

  void _beginGame() {
    // Nouvelle partie = nouveau droit de pause.
    _pauseAllowance.reset();
    _reviewingRules = false;
    setState(() {
      _resetBoard();
      _stage = _Stage.gameplay;
    });
    _sessionStart = ref
        .read(gamesRepositoryProvider)
        .startSession(GameType.planifik);
  }

  void _place(int taskIndex) {
    final slot = _slots.indexOf(null);
    if (slot < 0) return;
    setState(() {
      _slots[slot] = taskIndex;
      _pool.remove(taskIndex);
    });
  }

  void _removeFromSlot(int slot) {
    if (_slots[slot] == null) return;
    setState(() {
      _pool.add(_slots[slot]!);
      _slots[slot] = null;
      _adjustmentCount++; // un retrait après placement = un réajustement
    });
  }

  // ── Mesures (aucun score attribué ici) ────────────────────────────────────

  bool get _dependenciesRespected {
    final position = <int, int>{};
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i] != null) position[_slots[i]!] = i;
    }
    for (var t = 0; t < _caseTasks.length; t++) {
      final tp = position[t];
      if (tp == null) return false;
      for (final dep in _caseTasks[t].deps) {
        final dp = position[dep];
        if (dp == null || dp >= tp) return false;
      }
    }
    return true;
  }

  bool get _timeConstraintsRespected {
    for (var i = 0; i < _slots.length; i++) {
      final t = _slots[i];
      if (t == null) return false;
      final deadline = _caseTasks[t].deadline;
      if (deadline != null && i > deadline) return false;
    }
    return true;
  }

  /// Nombre de contraintes (dépendance/échéance) violées — pour la cohérence.
  int get _violationCount {
    final position = <int, int>{};
    for (var i = 0; i < _slots.length; i++) {
      if (_slots[i] != null) position[_slots[i]!] = i;
    }
    var violations = 0;
    for (var t = 0; t < _caseTasks.length; t++) {
      final tp = position[t];
      if (tp == null) continue;
      for (final dep in _caseTasks[t].deps) {
        final dp = position[dep];
        if (dp == null || dp >= tp) violations++;
      }
      final deadline = _caseTasks[t].deadline;
      if (deadline != null && tp > deadline) violations++;
    }
    return violations;
  }

  /// Cohérence 0–2 : 0 violation → 2 (clair) · 1-2 → 1 (partiel) · >2 → 0.
  int get _planningCoherence {
    final v = _violationCount;
    if (v == 0) return 2;
    if (v <= 2) return 1;
    return 0;
  }

  TaskSchedulingMetrics _buildMetrics() => TaskSchedulingMetrics(
    dependenciesRespected: _dependenciesRespected,
    timeConstraintsRespected: _timeConstraintsRespected,
    planningCoherence: _planningCoherence,
    adjustmentCount: _adjustmentCount,
  );

  Future<void> _submit() async {
    if (_busy || _slots.contains(null)) return;
    setState(() {
      _busy = true;
      _stage = _Stage.score;
    });
    try {
      final session = await (_sessionStart ??= ref
          .read(gamesRepositoryProvider)
          .startSession(GameType.planifik));
      final updated = await ref
          .read(gamesRepositoryProvider)
          .submitResult(
            sessionId: session.id,
            miniGame: MiniGame.taskScheduling,
            metrics: _buildMetrics(),
          );
      if (!mounted) return;
      setState(() => _serverSession = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Score non synchronisé : $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _stage == _Stage.gameplay;
    return PopScope(
      canPop: _stage == _Stage.intro || _stage == _Stage.score,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _stage != _Stage.intro) {
          setState(() => _stage = _Stage.intro);
        }
      },
      child: Scaffold(
        backgroundColor: isDark ? ZennytGamePalette.gameBlue : Colors.white,
        body: SafeArea(
          child: GameContentFrame(maxWidth: 980, child: _buildStage()),
        ),
      ),
    );
  }

  /// Bouton unique du bandeau : menu de pause tant que la fenêtre est ouverte,
  /// confirmation de sortie ensuite. Voir [GameMenuAffordance].
  Future<void> _openMenu() async {
    if (_stage != _Stage.gameplay) return;
    if (_pauseAllowance.canOpen) return _openPause();
    if (await GameExitConfirmDialog.show(context)) {
      if (mounted) context.go(AppRoutes.games);
    }
  }

  /// Menu pause — même `GamePauseScaffold` que tous les autres jeux : reprise,
  /// réglages son/musique/vibration, règles, sortie.
  Future<void> _openPause() async {
    if (_stage != _Stage.gameplay) return;
    // Une seule fenêtre de pause par partie (CdC pause §2-3).
    if (!_pauseAllowance.canOpen) return;
    SoundService.instance.playSfx(GameSfx.pauseClick);
    _pauseAllowance.open();
    final action = await showDialog<GamePauseAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) => GamePauseScaffold(
        countdown: _pauseAllowance.remaining,
        onCountdownExpired: () =>
            Navigator.of(context).pop(GamePauseAction.resume),
        description:
            'Le plateau est figé. Les tâches déjà posées sont conservées.',
        buttons: [
          GamePrimaryButton(
            label: 'Resume',
            onPressed: () => Navigator.of(context).pop(GamePauseAction.resume),
          ),
          GameOutlineButton(
            label: 'View rules',
            onPressed: () => Navigator.of(context).pop(GamePauseAction.help),
          ),
          GamePauseExitButton(
            label: 'Exit mission',
            onPressed: () => Navigator.of(context).pop(GamePauseAction.exit),
          ),
        ],
      ),
    );
    if (!mounted) return;
    switch (action) {
      case GamePauseAction.help:
        // Relire les règles conserve le plateau et la session courante.
        setState(() {
          _reviewingRules = true;
          _stage = _Stage.howToPlay;
        });
        return;
      case GamePauseAction.exit:
        // Quitter annule la tentative : confirmation explicite d'abord.
        if (await GameExitConfirmDialog.show(context)) {
          if (mounted) context.go(AppRoutes.games);
          return;
        }
      case GamePauseAction.resume:
      case GamePauseAction.restart:
      case null:
        break;
    }
    // La partie repart : le temps passé en pause rejoint le budget consommé, et
    // le bandeau se redessine — le bouton reste « Pause » tant qu'il reste du
    // budget, et bascule sur « Exit mission » une fois les 30 s épuisées.
    _pauseAllowance.close();
    if (mounted) setState(() {});
  }

  void _resumeFromRules() {
    _pauseAllowance.close();
    setState(() {
      _reviewingRules = false;
      _stage = _Stage.gameplay;
    });
  }

  Widget _buildStage() {
    return switch (_stage) {
      _Stage.intro => _IntroView(
        onStart: () => setState(() => _stage = _Stage.howToPlay),
        onBack: () => context.go(AppRoutes.games),
      ),
      _Stage.howToPlay => _HowToPlayView(
        onStart: _reviewingRules ? _resumeFromRules : _beginGame,
        onBack: _reviewingRules
            ? _resumeFromRules
            : () => setState(() => _stage = _Stage.intro),
        reviewing: _reviewingRules,
      ),
      _Stage.gameplay => GameplayMusic(
        child: _GameplayView(
          slots: _slots,
          pool: _pool,
          onPlace: _place,
          onRemove: _removeFromSlot,
          onValidate: _submit,
          onPause: _openMenu,
          affordance: _pauseAllowance.affordance,
        ),
      ),
      _Stage.score => _ScoreView(
        rawScore: _serverSession?.lastAttempt?.score.rawPoints,
        level: _serverSession?.lastAttempt?.score.level,
        busy: _busy,
        onReplay: _beginGame,
        onNext: () => context.go(AppRoutes.gamesPredictivePuzzle),
        onBack: () => context.go(AppRoutes.games),
      ),
    };
  }
}

// ── Gameplay ─────────────────────────────────────────────────────────────────

class _GameplayView extends StatelessWidget {
  const _GameplayView({
    required this.slots,
    required this.pool,
    required this.onPlace,
    required this.onRemove,
    required this.onValidate,
    required this.onPause,
    required this.affordance,
  });

  final List<int?> slots;
  final List<int> pool;
  final ValueChanged<int> onPlace;
  final ValueChanged<int> onRemove;
  final VoidCallback onValidate;
  final VoidCallback onPause;
  final GameMenuAffordance affordance;

  @override
  Widget build(BuildContext context) {
    final full = !slots.contains(null);
    final placed = slots.whereType<int>().length;
    final schedule = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your schedule',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('day-stack-schedule'),
            itemCount: slots.length,
            itemBuilder: (context, i) => _SlotRow(
              position: i + 1,
              taskIndex: slots[i],
              onRemove: slots[i] == null ? null : () => onRemove(i),
            ),
          ),
        ),
      ],
    );
    final tray = GamePanel(
      padding: const EdgeInsets.all(12),
      backgroundColor: ZennytGamePalette.gamePanel,
      borderColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tasks to place · ${pool.length}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Tap a task to fill the next empty slot.',
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ListView.separated(
              key: const ValueKey('day-stack-tray'),
              itemCount: pool.length,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (_, index) => _TaskChip(
                taskIndex: pool[index],
                onTap: () => onPlace(pool[index]),
              ),
            ),
          ),
        ],
      ),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Day Stack',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: affordance.tooltip,
                onPressed: onPause,
                style: IconButton.styleFrom(
                  backgroundColor: ZennytGamePalette.gamePanel,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(48, 48),
                ),
                icon: Icon(affordance.icon),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$placed / ${slots.length} tasks placed',
            key: const ValueKey('day-stack-progress'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: placed / slots.length,
            minHeight: 5,
            color: Colors.white,
            backgroundColor: ZennytGamePalette.gamePanel,
            semanticsLabel: 'Tasks placed',
            semanticsValue: '${(100 * placed / slots.length).round()}%',
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                if (pool.isEmpty) return schedule;
                if (constraints.maxWidth >= 640) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: schedule),
                      const SizedBox(width: 20),
                      Expanded(flex: 2, child: tray),
                    ],
                  );
                }
                return Column(
                  children: [
                    Expanded(flex: 4, child: schedule),
                    const SizedBox(height: 12),
                    Expanded(flex: 3, child: tray),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          GamePrimaryButton(
            label: 'Validate schedule',
            onPressed: full ? onValidate : null,
          ),
        ],
      ),
    );
  }
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.position,
    required this.taskIndex,
    this.onRemove,
  });

  final int position;
  final int? taskIndex;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final task = taskIndex == null ? null : _caseTasks[taskIndex!];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$position',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              button: task != null,
              label: task == null
                  ? 'Empty slot $position'
                  : 'Slot $position: ${task.label}',
              hint: task == null
                  ? 'Choose a task from the tray'
                  : 'Tap to return this task to the tray',
              child: InkWell(
                key: ValueKey('day-stack-slot-$position'),
                onTap: onRemove,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: task == null
                        ? Colors.white.withValues(alpha: 0.10)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: task == null
                      ? Text(
                          'Tap a task below',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        )
                      : _TaskInfo(task: task),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskChip extends StatelessWidget {
  const _TaskChip({required this.taskIndex, required this.onTap});

  final int taskIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final task = _caseTasks[taskIndex];
    return Semantics(
      button: true,
      label: task.label,
      child: InkWell(
        key: ValueKey('day-stack-task-$taskIndex'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: _TaskInfo(task: task),
        ),
      ),
    );
  }
}

class _TaskInfo extends StatelessWidget {
  const _TaskInfo({required this.task});

  final _Task task;

  @override
  Widget build(BuildContext context) {
    final deps = task.deps.map((d) => _caseTasks[d].label).join(', ');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          task.label,
          style: const TextStyle(
            color: ZennytGamePalette.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (task.deps.isNotEmpty || task.deadline != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              [
                if (task.deps.isNotEmpty) 'after: $deps',
                if (task.deadline != null) 'by slot ${task.deadline! + 1}',
              ].join(' · '),
              style: const TextStyle(
                color: ZennytGamePalette.muted,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Intro / How to play (structure Optimal Path) ────────────────────────────

class _IntroView extends StatelessWidget {
  const _IntroView({required this.onStart, required this.onBack});
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: onBack),
          const SizedBox(height: AppSpacing.base),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: ZennytGamePalette.gameBlue,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXxl),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 150,
                  child: GameRuleChip(
                    label: 'Planning',
                    color: Colors.white,
                    filled: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Image.asset(
                  'assets/games icons/Task Scheduling transparent.png',
                  height: 112,
                  semanticLabel: 'Day Stack task scheduling',
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  'Day Stack',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  'Order the tasks so every dependency and deadline is respected.',
                  style: AppTypography.titleMedium.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const Row(
            children: [
              Expanded(
                child: ResultStatTile(label: 'Goal', value: 'Planning'),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(
                  label: 'Planifik',
                  value: 'Mini-jeu 2',
                  valueColor: ZennytGamePalette.magenta,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ResultStatTile(label: 'Format', value: '9 tasks'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxl),
          GamePrimaryButton(label: 'Start', onPressed: onStart),
        ],
      ),
    );
  }
}

class _HowToPlayView extends StatelessWidget {
  const _HowToPlayView({
    required this.onStart,
    required this.onBack,
    this.reviewing = false,
  });
  final bool reviewing;
  final VoidCallback onStart;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    Widget step(IconData icon, String title, String body) => Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: GamePanel(
        backgroundColor: ZennytGamePalette.mist,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: ZennytGamePalette.magenta),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(
                      color: ZennytGamePalette.blue,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: AppTypography.bodyLarge.copyWith(
                      color: ZennytGamePalette.muted,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BackButton(onPressed: onBack),
          const SizedBox(height: AppSpacing.base),
          Text(
            'How to schedule',
            style: AppTypography.displaySmall.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          step(
            Icons.touch_app_outlined,
            'Place tasks',
            'Tap a task to drop it in the next slot. Tap a slot to send it back.',
          ),
          step(
            Icons.link_rounded,
            'Dependencies',
            'A task must come AFTER the tasks listed in "after: …".',
          ),
          step(
            Icons.schedule_rounded,
            'Deadlines',
            'A task marked "by slot n" must be placed at that slot or earlier.',
          ),
          const SizedBox(height: AppSpacing.lg),
          GamePrimaryButton(
            label: reviewing ? 'Resume schedule' : 'I am ready',
            onPressed: onStart,
          ),
        ],
      ),
    );
  }
}

// ── Score ───────────────────────────────────────────────────────────────────

class _ScoreView extends StatelessWidget {
  const _ScoreView({
    required this.rawScore,
    required this.level,
    required this.busy,
    required this.onReplay,
    required this.onNext,
    required this.onBack,
  });

  final int? rawScore;
  final String? level;
  final bool busy;
  final VoidCallback onReplay;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
      child: Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: _BackButton(onPressed: onBack),
          ),
          Text(
            'Results',
            style: AppTypography.displaySmall.copyWith(
              color: ZennytGamePalette.blue,
              letterSpacing: 0,
            ),
          ),
          Text(
            busy ? 'Scoring…' : 'Day Stack · Task scheduling',
            style: AppTypography.bodyMedium.copyWith(
              color: ZennytGamePalette.muted,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: ZennytGamePalette.gameBlue,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            ),
            child: Column(
              children: [
                Text(
                  'Planning score',
                  style: AppTypography.titleSmall.copyWith(
                    color: Colors.white,
                    letterSpacing: 0,
                  ),
                ),
                Text(
                  rawScore == null ? '—' : '$rawScore/10',
                  style: AppTypography.displayLarge.copyWith(
                    color: Colors.white,
                    fontSize: 52,
                    letterSpacing: 0,
                  ),
                ),
                if (level != null)
                  Text(
                    level!,
                    style: AppTypography.bodyLarge.copyWith(
                      color: Colors.white,
                      letterSpacing: 0,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          GamePrimaryButton(label: 'Continue to Hanoï', onPressed: onNext),
          const SizedBox(height: AppSpacing.md),
          GameOutlineButton(label: 'Replay', onPressed: onReplay),
          const SizedBox(height: AppSpacing.md),
          GameOutlineButton(label: 'Back to games', onPressed: onBack),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Back',
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: ZennytGamePalette.mist,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: const Icon(Icons.chevron_left, color: ZennytGamePalette.blue),
        ),
      ),
    );
  }
}
