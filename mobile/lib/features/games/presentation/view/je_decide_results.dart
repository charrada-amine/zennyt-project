import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/game_session.dart';
import '../../domain/entities/score_breakdown.dart';
import '../widgets/game_system_components.dart';

const _ink = Color(0xFF28234F);
const _muted = Color(0xFF7E8DB2);
const _border = Color(0xFFD8E2F6);
const _canvas = Color(0xFFF7F8FE);
const _magenta = Color(0xFFD52E83);
const _violet = Color(0xFF4E46E8);
const _cyan = Color(0xFF17B2C6);
const _orange = Color(0xFFFF963A);
const _green = Color(0xFF2BC66D);
const _softPink = Color(0xFFFFF1F7);

/// Profil de décision RÉEL, dérivé de la réponse du serveur.
///
/// Rien n'est calculé ici : le SCW /100, le niveau et le détail /18 par dimension
/// sont notés côté backend (catalogue des 120 items) et arrivent dans la session.
/// Le client ne fait que projeter. Les libellés et descriptions de dimension sont
/// du texte de référence — ils expliquent ce que mesure une dimension, ils ne
/// décrivent pas le candidat.
class DecisionProfile {
  const DecisionProfile({
    required this.score,
    required this.level,
    required this.dimensions,
  });

  /// Score composite standardisé pondéré /100.
  final int score;

  /// Élevé · Normal · Borderline · Fragile (seuils serveur).
  final String level;

  final List<DecisionDimensionResult> dimensions;

  List<int> get values => [for (final d in dimensions) d.percent];

  /// Construit le profil à partir de la session soumise.
  ///
  /// Le détail par dimension est lu dans `scoreBreakdown` : une ligne critère par
  /// dimension (II/ER/DT/CS/RE), notée /18. Une dimension non exploitable
  /// (> 2 items manquants) arrive en ligne `info` et vaut 0 %.
  factory DecisionProfile.fromSession(GameSession session) {
    final score = session.lastAttempt?.score;
    final byCode = <String, ScoreBreakdownLine>{
      for (final line in session.scoreBreakdown)
        if (_dimensionOrder.contains(line.label)) line.label: line,
    };
    return DecisionProfile(
      score: score?.rawPoints ?? 0,
      level: score?.level ?? '—',
      dimensions: [
        for (final code in _dimensionOrder)
          DecisionDimensionResult(
            code: code,
            label: _dimensionLabels[code]!,
            shortLabel: _dimensionShortLabels[code]!,
            description: _dimensionDescriptions[code]!,
            points: byCode[code]?.points,
            maxPoints: byCode[code]?.maxPoints ?? 18,
            // Le serveur suffixe le détail quand la dimension ne discrimine pas
            // encore (modèles λ / k / cohérence de paire non implémentés).
            provisional:
                byCode[code]?.detail?.contains('notation provisoire') ?? false,
          ),
      ],
    );
  }

  static const _dimensionOrder = ['II', 'ER', 'DT', 'CS', 'RE'];

  static const _dimensionLabels = {
    'II': 'Analytical Thinking',
    'ER': 'Risk Balance',
    'DT': 'Quick Choice',
    'CS': 'Decision Stability',
    'RE': 'Self-Control',
  };

  static const _dimensionShortLabels = {
    'II': 'Analytical',
    'ER': 'Risk',
    'DT': 'Quick',
    'CS': 'Stability',
    'RE': 'Control',
  };

  static const _dimensionDescriptions = {
    'II': 'How you identify and compare the constraints of a situation before choosing.',
    'ER': 'How you weigh a guaranteed outcome against an uncertain one.',
    'DT': 'How you decide when time is limited.',
    'CS': 'How stable your choices stay across equivalent situations.',
    'RE': 'How you weigh an immediate reward against a larger delayed one.',
  };

  static const shortLabels = ['Analytical', 'Risk', 'Quick', 'Stability', 'Control'];
}

/// Résultat d'UNE dimension.
class DecisionDimensionResult {
  const DecisionDimensionResult({
    required this.code,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.points,
    required this.maxPoints,
    required this.provisional,
  });

  final String code;
  final String label;
  final String shortLabel;
  final String description;

  /// Score /18, ou `null` si le bloc n'est pas exploitable.
  final int? points;
  final int maxPoints;

  /// true → tous les items servis sur cette dimension sont en notation neutre :
  /// le score ne discrimine pas encore, il ne faut pas le lire comme une
  /// performance.
  final bool provisional;

  bool get exploitable => points != null;

  int get percent =>
      points == null || maxPoints == 0 ? 0 : (points! * 100 / maxPoints).round();
}

enum DecisionResultsStep {
  journeyComplete,
  preparing,
  profile,
  details,
  export,
}

class DecisionResultsFlow extends StatefulWidget {
  const DecisionResultsFlow({
    super.key,
    required this.profile,
    required this.onClose,
    required this.onDone,
    this.initialStep = DecisionResultsStep.journeyComplete,
  });

  final DecisionProfile profile;
  final VoidCallback onClose;
  final VoidCallback onDone;
  final DecisionResultsStep initialStep;

  @override
  State<DecisionResultsFlow> createState() => _DecisionResultsFlowState();
}

class _DecisionResultsFlowState extends State<DecisionResultsFlow> {
  late DecisionResultsStep _step;

  @override
  void initState() {
    super.initState();
    _step = widget.initialStep;
  }

  void _go(DecisionResultsStep step) {
    // Révélation du profil (badge/score) → son de félicitations.
    if (step == DecisionResultsStep.profile) {
      SoundService.instance.playSfx(GameSfx.congrats);
    }
    setState(() => _step = step);
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return ColoredBox(
      color: _canvas,
      child: SafeArea(
        child: Column(
          children: [
            _ResultsHeader(
              eyebrow: _step == DecisionResultsStep.journeyComplete
                  ? 'Decision Journey'
                  : 'Your decision profile',
              title: _title,
              onClose: widget.onClose,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 250),
                child: KeyedSubtree(
                  key: ValueKey(_step),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
                    child: _buildStep(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _title => switch (_step) {
    DecisionResultsStep.journeyComplete => 'Journey complete',
    DecisionResultsStep.preparing => 'Preparing your profile',
    DecisionResultsStep.profile => 'Decision profile',
    DecisionResultsStep.details => 'Detailed insights',
    DecisionResultsStep.export => 'Export & share',
  };

  Widget _buildStep() => switch (_step) {
    DecisionResultsStep.journeyComplete => _JourneyCompleteView(
      onReveal: () => _go(DecisionResultsStep.preparing),
      onBack: widget.onClose,
    ),
    DecisionResultsStep.preparing => _PreparingProfileView(
      profile: widget.profile,
      onReady: () => _go(DecisionResultsStep.profile),
    ),
    DecisionResultsStep.profile => _ProfileView(
      profile: widget.profile,
      onInsights: () => _go(DecisionResultsStep.details),
      onShare: () => _go(DecisionResultsStep.export),
    ),
    DecisionResultsStep.details => _DetailsView(
      profile: widget.profile,
      onExport: () => _go(DecisionResultsStep.export),
      onBack: () => _go(DecisionResultsStep.profile),
    ),
    DecisionResultsStep.export => _ExportView(
      profile: widget.profile,
      onDone: widget.onDone,
    ),
  };
}

class _ResultsHeader extends StatelessWidget {
  const _ResultsHeader({
    required this.eyebrow,
    required this.title,
    required this.onClose,
  });

  final String eyebrow;
  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
      child: Row(
        children: [
          IconButton(
            key: const ValueKey('decision-results-close'),
            tooltip: 'Close',
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded),
            style: IconButton.styleFrom(
              fixedSize: const Size(48, 48),
              foregroundColor: _ink,
              backgroundColor: Colors.white,
              side: const BorderSide(color: _border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: AppTypography.bodySmall.copyWith(color: _muted),
                ),
                Text(
                  title,
                  style: AppTypography.titleLarge.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.more_horiz_rounded, color: _ink, size: 32),
        ],
      ),
    );
  }
}

class _JourneyCompleteView extends StatelessWidget {
  const _JourneyCompleteView({required this.onReveal, required this.onBack});

  final VoidCallback onReveal;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _ScrollableResult(
      children: [
        const SizedBox(height: 24),
        const _HeroMark(icon: Icons.auto_awesome_rounded, color: _magenta),
        const SizedBox(height: 24),
        _TitleBlock(
          key: const ValueKey('decision-journey-complete'),
          title: 'Journey complete',
          body:
              'You explored 30 everyday choices. Your personal decision profile is ready.',
        ),
        const SizedBox(height: 22),
        const _CompletionCard(),
        const SizedBox(height: 28),
        GamePrimaryButton(
          key: const ValueKey('decision-reveal-profile'),
          label: 'Reveal my profile',
          onPressed: onReveal,
        ),
        const SizedBox(height: 10),
        GameOutlineButton(label: 'Back to journey', onPressed: onBack),
      ],
    );
  }
}

class _PreparingProfileView extends StatefulWidget {
  const _PreparingProfileView({required this.profile, required this.onReady});

  final DecisionProfile profile;

  final VoidCallback onReady;

  @override
  State<_PreparingProfileView> createState() => _PreparingProfileViewState();
}

class _PreparingProfileViewState extends State<_PreparingProfileView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      await Future<void>.delayed(
        reduceMotion
            ? const Duration(milliseconds: 250)
            : const Duration(milliseconds: 1400),
      );
      if (mounted) widget.onReady();
    });
  }

  @override
  Widget build(BuildContext context) {
    return _ScrollableResult(
      children: [
        const SizedBox(height: 20),
        SizedBox(
          width: 250,
          height: 250,
          child: _DecisionRadar(
            values: widget.profile.values,
            labels: [for (final d in widget.profile.dimensions) d.label],
          ),
        ),
        const SizedBox(height: 18),
        const _TitleBlock(
          key: ValueKey('decision-preparing-profile'),
          title: 'Building your profile',
          body: 'We’re turning your journey into a simple, private reflection.',
        ),
        const SizedBox(height: 24),
        const _PreparationStep(
          icon: Icons.check_circle_rounded,
          label: 'Reading your journey',
          complete: true,
        ),
        const _PreparationStep(
          icon: Icons.balance_rounded,
          label: 'Balancing dimensions',
          complete: true,
        ),
        const _PreparationStep(
          icon: Icons.auto_graph_rounded,
          label: 'Building profile',
          complete: false,
        ),
        const SizedBox(height: 18),
        Text(
          'Generating…',
          textAlign: TextAlign.center,
          style: AppTypography.titleSmall.copyWith(
            color: _magenta,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({
    required this.profile,
    required this.onInsights,
    required this.onShare,
  });

  final DecisionProfile profile;

  final VoidCallback onInsights;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return _ScrollableResult(
      children: [
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ScoreRing(score: profile.score),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Decision profile',
                    key: const ValueKey('decision-profile-title'),
                    style: AppTypography.headlineSmall.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Niveau calculé serveur (seuils de la fiche + couche provisoire).
                  _Pill(label: profile.level, color: _green),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ResultCard(
          child: SizedBox(
            height: 280,
            child: _DecisionRadar(
              values: profile.values,
              labels: [for (final d in profile.dimensions) d.label],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          profile.dimensions.any((d) => d.provisional)
              ? 'Some dimensions are still scored neutrally while their model is '
                    'being finalised — they do not yet tell you apart.'
              : 'Each dimension is scored out of 18 by the server, then combined '
                    'into a single weighted score.',
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: _muted, height: 1.4),
        ),
        const SizedBox(height: 24),
        GamePrimaryButton(
          key: const ValueKey('decision-view-insights'),
          label: 'View insights',
          onPressed: onInsights,
        ),
        const SizedBox(height: 10),
        GameOutlineButton(label: 'Share profile', onPressed: onShare),
      ],
    );
  }
}


class _DetailsView extends StatelessWidget {
  const _DetailsView({
    required this.profile,
    required this.onExport,
    required this.onBack,
  });

  final DecisionProfile profile;

  final VoidCallback onExport;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return _ScrollableResult(
      children: [
        const SizedBox(height: 8),
        for (var i = 0; i < profile.dimensions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DimensionCard(
              label: profile.dimensions[i].label,
              value: profile.dimensions[i].percent,
              description: profile.dimensions[i].provisional
                  ? '${profile.dimensions[i].description} '
                        '(Notation provisoire : cette dimension ne discrimine pas encore.)'
                  : profile.dimensions[i].description,
              color: const [_violet, _magenta, _orange, _green, _cyan][i],
            ),
          ),
        const SizedBox(height: 12),
        GamePrimaryButton(
          key: const ValueKey('decision-export-summary'),
          label: 'Export summary',
          onPressed: onExport,
        ),
        const SizedBox(height: 10),
        GameOutlineButton(label: 'Back to profile', onPressed: onBack),
      ],
    );
  }
}

class _ExportView extends StatelessWidget {
  const _ExportView({required this.profile, required this.onDone});

  final DecisionProfile profile;
  final VoidCallback onDone;

  String get _summary =>
      'Decision profile — ${profile.score}/100 (${profile.level})\n'
      '${profile.dimensions.map((d) => '${d.label}: ${d.percent}/100'
          '${d.provisional ? ' (provisional)' : ''}').join('\n')}';

  Future<void> _copy(BuildContext context, String message) async {
    await Clipboard.setData(ClipboardData(text: _summary));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return _ScrollableResult(
      children: [
        const SizedBox(height: 22),
        const _HeroMark(icon: Icons.ios_share_rounded, color: _violet),
        const SizedBox(height: 22),
        const _TitleBlock(
          key: ValueKey('decision-export-share'),
          title: 'Keep your profile',
          body:
              'Choose how you want to keep this simple snapshot of your journey.',
        ),
        const SizedBox(height: 24),
        _ExportOption(
          icon: Icons.picture_as_pdf_rounded,
          title: 'Export summary',
          subtitle: 'Copy a PDF-ready overview',
          color: _magenta,
          onTap: () => _copy(context, 'Summary copied and ready to export.'),
        ),
        const SizedBox(height: 12),
        _ExportOption(
          icon: Icons.share_rounded,
          title: 'Share profile',
          subtitle: 'Copy a simple profile snapshot',
          color: _violet,
          onTap: () => _copy(context, 'Profile snapshot copied.'),
        ),
        const SizedBox(height: 12),
        _ExportOption(
          icon: Icons.home_rounded,
          title: 'Return to Zennyt',
          subtitle: 'Finish and return to the games menu',
          color: _cyan,
          onTap: onDone,
        ),
        const SizedBox(height: 18),
        const _PrivacyNote(),
        const SizedBox(height: 24),
        GamePrimaryButton(
          key: const ValueKey('decision-results-done'),
          label: 'Done',
          onPressed: onDone,
        ),
      ],
    );
  }
}

class _ScrollableResult extends StatelessWidget {
  const _ScrollableResult({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: math.max(0, MediaQuery.sizeOf(context).height - 112),
        ),
        child: Column(children: children),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.child, this.accent});

  final Widget child;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent ?? _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12211A63),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _HeroMark extends StatelessWidget {
  const _HeroMark({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      height: 126,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.35), width: 2),
      ),
      child: Icon(icon, size: 62, color: color),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppTypography.headlineMedium.copyWith(
            color: _ink,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          body,
          textAlign: TextAlign.center,
          style: AppTypography.bodyMedium.copyWith(color: _muted, height: 1.4),
        ),
      ],
    );
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard();

  @override
  Widget build(BuildContext context) {
    return const _ResultCard(
      child: Column(
        children: [
          _CompletionRow(
            icon: Icons.check_circle_rounded,
            label: 'Scenarios complete',
            value: '30 / 30',
          ),
          Divider(color: _border, height: 24),
          _CompletionRow(
            icon: Icons.lock_rounded,
            label: 'Choices',
            value: 'Saved privately',
          ),
          Divider(color: _border, height: 24),
          _CompletionRow(
            icon: Icons.auto_graph_rounded,
            label: 'Decision profile',
            value: 'Ready',
          ),
        ],
      ),
    );
  }
}

class _CompletionRow extends StatelessWidget {
  const _CompletionRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _magenta),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: const TextStyle(color: _ink)),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _PreparationStep extends StatelessWidget {
  const _PreparationStep({
    required this.icon,
    required this.label,
    required this.complete,
  });

  final IconData icon;
  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _ResultCard(
        child: Row(
          children: [
            Icon(icon, color: complete ? _green : _magenta),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (complete) const Icon(Icons.check_rounded, color: _green),
          ],
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Profile score $score out of 100',
      child: SizedBox(
        width: 106,
        height: 106,
        // Anneau + nombre s'animent ensemble de 0 vers le score final.
        child: TweenAnimationBuilder<double>(
          key: ValueKey<int>(score),
          tween: Tween<double>(begin: 0, end: score.toDouble()),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutCubic,
          builder: (context, animated, _) => Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: animated / 100,
                  strokeWidth: 10,
                  backgroundColor: _border,
                  valueColor: const AlwaysStoppedAnimation(_magenta),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${animated.round()}',
                    style: AppTypography.headlineMedium.copyWith(
                      color: _ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    '/ 100',
                    style: AppTypography.bodySmall.copyWith(color: _muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: AppTypography.bodySmall.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}




class _DimensionCard extends StatelessWidget {
  const _DimensionCard({
    required this.label,
    required this.value,
    required this.description,
    required this.color,
  });

  final String label;
  final int value;
  final String description;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return _ResultCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.titleMedium.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                '$value',
                style: AppTypography.titleLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value / 100,
              minHeight: 7,
              backgroundColor: _border,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: AppTypography.bodySmall.copyWith(
              color: _muted,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExportOption extends StatelessWidget {
  const _ExportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 84),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: _border),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(color: _muted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: _muted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  const _PrivacyNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _softPink,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _magenta.withValues(alpha: 0.25)),
      ),
      child: const Row(
        children: [
          Icon(Icons.lock_outline_rounded, color: _magenta),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Your individual choices stay private.',
              style: TextStyle(color: _ink, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _DecisionRadar extends StatelessWidget {
  const _DecisionRadar({required this.values, required this.labels});

  /// Libellés complets — lus par les lecteurs d'écran. Le tracé, lui, utilise
  /// les libellés courts, faute de place.
  final List<String> labels;

  final List<int> values;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: labels
          .asMap()
          .entries
          .map((entry) => '${entry.value} ${values[entry.key]} out of 100')
          .join(', '),
      child: CustomPaint(
        painter: _DecisionRadarPainter(values),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DecisionRadarPainter extends CustomPainter {
  const _DecisionRadarPainter(this.values);

  final List<int> values;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 + 4);
    final radius = math.min(size.width, size.height) * 0.31;
    const sides = 5;
    final grid = Paint()
      ..color = _border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final axis = Paint()
      ..color = _border.withValues(alpha: 0.8)
      ..strokeWidth = 1;

    Offset point(double factor, int index) {
      final angle = -math.pi / 2 + (math.pi * 2 * index / sides);
      return Offset(
        center.dx + math.cos(angle) * radius * factor,
        center.dy + math.sin(angle) * radius * factor,
      );
    }

    for (var ring = 1; ring <= 4; ring++) {
      final path = Path();
      for (var index = 0; index < sides; index++) {
        final p = point(ring / 4, index);
        index == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      path.close();
      canvas.drawPath(path, grid);
    }
    for (var index = 0; index < sides; index++) {
      canvas.drawLine(center, point(1, index), axis);
    }

    final profile = Path();
    for (var index = 0; index < sides; index++) {
      final p = point(values[index] / 100, index);
      index == 0 ? profile.moveTo(p.dx, p.dy) : profile.lineTo(p.dx, p.dy);
    }
    profile.close();
    canvas.drawPath(
      profile,
      Paint()
        ..color = _magenta.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill,
    );
    canvas.drawPath(
      profile,
      Paint()
        ..color = _magenta
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    for (var index = 0; index < sides; index++) {
      final p = point(values[index] / 100, index);
      canvas.drawCircle(p, 4, Paint()..color = _magenta);
      final labelPoint = point(1.28, index);
      final painter = TextPainter(
        text: TextSpan(
          text: DecisionProfile.shortLabels[index],
          style: const TextStyle(
            color: _ink,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        maxLines: 1,
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        labelPoint - Offset(painter.width / 2, painter.height / 2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DecisionRadarPainter oldDelegate) =>
      oldDelegate.values != values;
}
