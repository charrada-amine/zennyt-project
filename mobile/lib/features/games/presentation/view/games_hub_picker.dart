part of 'games_hub_screen.dart';

/// Sélecteur de jeu d'une catégorie (bottom sheet haute, aux couleurs de la
/// dimension). Retourne la route choisie (ou `null`), que l'appelant pousse.
Future<String?> _showGamePicker(
  BuildContext context, {
  required _GameCategory category,
  required Set<CatalogGame>? completed,
}) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: _hub(context).barrier,
    isScrollControlled: true,
    builder: (sheetContext) => _GamePickerSheet(
      category: category,
      completed: completed,
      onPick: (route) => Navigator.of(sheetContext).pop(route),
    ),
  );
}

class _GamePickerSheet extends StatelessWidget {
  const _GamePickerSheet({
    required this.category,
    required this.completed,
    required this.onPick,
  });

  final _GameCategory category;
  final Set<CatalogGame>? completed;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final games = category.games;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: media.size.height * 0.88),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        child: ColoredBox(
          color: _hub(context).card,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PickerHero(category: category, completed: completed),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: EdgeInsets.fromLTRB(
                    20,
                    4,
                    20,
                    20 + media.padding.bottom,
                  ),
                  itemCount: games.length + 1,
                  separatorBuilder: (_, index) =>
                      SizedBox(height: index == 0 ? 12 : 10),
                  itemBuilder: (_, index) {
                    if (index == 0) {
                      return Text(
                        'Choisis un jeu',
                        style: TextStyle(
                          color: _hub(context).ink,
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      );
                    }
                    final game = games[index - 1];
                    return _GamePickerTile(
                      game: game,
                      index: index,
                      accent: category.accent,
                      tint: _hub(context).tint(category),
                      played: completed?.contains(game.game) ?? false,
                      onTap: () => onPick(game.route),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// En-tête teinté : poignée, titre, devise, icône et statistiques.
class _PickerHero extends StatelessWidget {
  const _PickerHero({required this.category, required this.completed});

  final _GameCategory category;
  final Set<CatalogGame>? completed;

  @override
  Widget build(BuildContext context) {
    final played = category.playedCount(completed);
    final open = category.playable.length;
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.5;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_hub(context).tint(category), _hub(context).tint(category).withValues(alpha: 0)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 5,
              decoration: BoxDecoration(
                color: category.accent.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.filter.label.toUpperCase(),
                      style: TextStyle(
                        color: category.accent,
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.title,
                      style: AppTypography.headlineLarge.copyWith(
                        color: _hub(context).ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category.tagline,
                      style: TextStyle(
                        color: _hub(context).muted,
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (!largeText) ...[
                const SizedBox(width: 12),
                Container(
                  width: 78,
                  height: 78,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _hub(context).card,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: category.accent.withValues(alpha: 0.20),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(category.iconAsset, fit: BoxFit.contain),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroStat(
                icon: HugeIcons.strokeRoundedClock01,
                label: category.durationLabel,
              ),
              _HeroStat(
                icon: HugeIcons.strokeRoundedGameController03,
                label: '$open sur ${category.games.length} ouverts',
              ),
              if (completed != null)
                _HeroStat(
                  icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                  label: played > 1 ? '$played joués' : '$played joué',
                  color: played > 0 ? _hub(context).success : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.icon, required this.label, this.color});

  final AppIconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? _hub(context).ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: _hub(context).card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _hub(context).line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, color: c, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: _metaStyle(context).copyWith(color: c, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

/// Ligne d'un jeu dans le sélecteur.
class _GamePickerTile extends StatelessWidget {
  const _GamePickerTile({
    required this.game,
    required this.index,
    required this.accent,
    required this.tint,
    required this.played,
    required this.onTap,
  });

  final _GameEntry game;
  final int index;
  final Color accent;
  final Color tint;
  final bool played;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final on = game.enabled;
    // Grisé et inerte, mais toujours lisible : le joueur voit ce que la
    // catégorie contiendra, sans pouvoir l'ouvrir.
    final tile = Material(
      color: on ? _hub(context).card : _hub(context).cardMuted,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: on ? onTap : null,
        borderRadius: BorderRadius.circular(20),
        splashColor: accent.withValues(alpha: 0.10),
        highlightColor: accent.withValues(alpha: 0.05),
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: on ? accent.withValues(alpha: 0.22) : _hub(context).line,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: on ? 1 : 0.45,
                child: Container(
                  width: 64,
                  height: 64,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: tint,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _GameLogoBadge(
                    game: game,
                    contextName: 'picker',
                    size: 52,
                    iconSize: 26,
                    radius: 12,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'JEU ${index.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: on ? accent : _hub(context).muted,
                        fontFamily: AppTypography.fontFamily,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      game.label,
                      style: AppTypography.titleLarge.copyWith(
                        color: on ? _hub(context).ink : _hub(context).muted,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (game.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        game.subtitle!,
                        style: TextStyle(
                          color: _hub(context).muted,
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (played) ...[
                      const SizedBox(height: 6),
                      _MetaLabel(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                        label: 'Joué',
                        color: _hub(context).success,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (on)
                _PlayButton(color: accent, replay: played)
              else
                const _ComingSoonBadge(),
            ],
          ),
        ),
      ),
    );

    // L'état est annoncé aux lecteurs d'écran : un simple gris ne se « voit »
    // pas en synthèse vocale.
    return Semantics(
      enabled: on,
      button: on,
      label: on ? game.label : '${game.label}, bientôt disponible',
      child: tile,
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.color, required this.replay});

  final Color color;
  final bool replay;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: AppIcon(
          replay
              ? HugeIcons.strokeRoundedArrowDataTransferHorizontal
              : HugeIcons.strokeRoundedPlay,
          color: Colors.white,
          size: 20
        ),
      ),
    );
  }
}
