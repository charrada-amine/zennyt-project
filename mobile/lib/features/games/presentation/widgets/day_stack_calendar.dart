/// Plateau du « Planning journalier » présenté comme un agenda.
///
/// Référence visuelle demandée par le client : la vue Jour d'Outlook Mobile.
/// Une colonne d'heures à gauche, des lignes horaires fines, et chaque tâche
/// posée comme un rendez-vous — fond teinté, liseré de couleur à gauche,
/// titre et plage horaire. Le joueur ne lit plus « 30 min · avant 12h00 » en
/// texte : il VOIT où tombe la tâche dans la journée, et les trous d'attente
/// apparaissent comme des plages vides de l'agenda.
///
/// Le jeu reste un jeu d'ORDRE : l'heure de chaque tâche est calculée par le
/// moteur ([buildDayStackSchedule]) à partir de l'ordre choisi. Déplacer un
/// rendez-vous le fait changer de place dans cet ordre, et tout l'agenda se
/// recalcule.
///
/// ## Échelle
///
/// Les créneaux courts grandissent pour garder leurs consignes lisibles.
/// Les repères horaires suivent chaque segment ; le défilement permet de
/// parcourir la journée sans réduire le texte.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/audio/sound_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/day_stack_bank.dart';
import '../../domain/service/day_stack_schedule.dart';
import 'day_stack_badges.dart';
import 'game_system_components.dart';

/// Hauteur d'une minute dans l'agenda.
const double kDayStackPxPerMinute = 1.6;

/// Largeur de la colonne des heures.
const double kDayStackGutter = 52;

/// Heure lisible : 480 -> « 08h00 ».
String dayStackClock(int minutes) {
  final h = (minutes ~/ 60).toString().padLeft(2, '0');
  final m = (minutes % 60).toString().padLeft(2, '0');
  return '${h}h$m';
}

/// Contrainte horaire en une ligne, pour le joueur.
///
/// On n'affiche PAS le texte brut de la banque : il mêle le métier et la règle
/// (« Repos mini. 1h avant cuisson · Repos : 60 min »). Le joueur a besoin de
/// la règle, pas de sa rédaction.
String? dayStackConstraintLabel(DayStackTask task) {
  final c = task.constraint;
  return switch (c.kind) {
    DayStackConstraintKind.window =>
      '${dayStackClock(c.startMin!)}–${dayStackClock(c.endMin!)}',
    DayStackConstraintKind.deadline => 'avant ${dayStackClock(c.beforeMin!)}',
    DayStackConstraintKind.anchor =>
      '${dayStackClock(c.startMin!)} pile (±${c.toleranceMin} min)',
    DayStackConstraintKind.relative => 'avant une autre tâche',
    DayStackConstraintKind.minDelay => '${c.minDelayMin} min avant la suite',
    // Le bloc fixe sans heure de la banque : rien à annoncer tant que la
    // donnée manque, plutôt qu'une règle inventée.
    DayStackConstraintKind.unspecified || DayStackConstraintKind.none => null,
  };
}

class _Palette {
  static const Color gridLine = Color(0x55FFFFFF);
  static const Color halfLine = Color(0x22FFFFFF);
  static const Color hourText = Colors.white;
  static const Color title = Colors.white;
  static const Color detail = Color(0xFFEAE8FF);
}

/// Agenda réordonnable des tâches d'une manche.
class DayStackCalendar extends StatefulWidget {
  const DayStackCalendar({
    super.key,
    required this.universe,
    required this.slots,
    required this.labelOf,
    required this.onMove,
    required this.onDraggingChanged,
    this.bottomInset = 0,
  });

  final DayStackUniverse universe;

  /// Hauteur recouverte en bas par un élément flottant (le bouton « Valider ») :
  /// la liste réserve cet espace pour que sa dernière tâche puisse remonter au-
  /// dessus, et le défilement automatique d'un glisser démarre avant lui.
  final double bottomInset;

  /// Ordre courant : indices dans `universe.tasks`.
  final List<int> slots;
  final String Function(DayStackTask) labelOf;
  final void Function(int from, int to) onMove;
  final ValueChanged<bool> onDraggingChanged;

  @override
  State<DayStackCalendar> createState() => _DayStackCalendarState();
}

class _DayStackCalendarState extends State<DayStackCalendar> {
  final _scrollController = ScrollController();
  final _viewportKey = GlobalKey();
  final _eventKeys = <int, GlobalKey>{};
  int? _dragStartIndex;
  Offset? _dragPosition;
  Timer? _autoScroll;
  static const _edgeZone = 48.0;
  static const _scrollStep = 10.0;
  static const _scrollInterval = Duration(milliseconds: 16);

  @override
  void dispose() {
    _autoScroll?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _finishDrag() {
    _autoScroll?.cancel();
    _autoScroll = null;
    _dragPosition = null;
    if (_dragStartIndex == null) return;
    _dragStartIndex = null;
    widget.onDraggingChanged(false);
  }

  void _startDrag(int index) {
    _dragStartIndex = index;
    SoundService.instance.vibrateSelection();
    widget.onDraggingChanged(true);
    _autoScroll = Timer.periodic(_scrollInterval, (_) {
      final pointer = _dragPosition;
      final box = _viewportKey.currentContext?.findRenderObject() as RenderBox?;
      if (pointer == null || box == null || !_scrollController.hasClients) {
        return;
      }
      final y = box.globalToLocal(pointer).dy;
      final direction = y < _edgeZone
          ? -((_edgeZone - y) / _edgeZone).clamp(0.0, 1.0)
          : y > box.size.height - widget.bottomInset - _edgeZone
          ? ((y - box.size.height + widget.bottomInset + _edgeZone) / _edgeZone)
                .clamp(0.0, 1.0)
          : 0.0;
      final position = _scrollController.position;
      final offset = (position.pixels + direction * _scrollStep).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      );
      if (offset != position.pixels) _scrollController.jumpTo(offset);
    });
  }

  void _drop() {
    final from = _dragStartIndex;
    final pointer = _dragPosition;
    if (from == null || pointer == null) {
      _finishDrag();
      return;
    }
    // Seules les cartes déterminent l'ordre. Les plages d'attente restent
    // dans l'agenda et ne sont jamais emportées dans le feedback de glissement.
    int? insertion;
    for (var index = 0; index < widget.slots.length; index++) {
      final box =
          _eventKeys[widget.slots[index]]?.currentContext?.findRenderObject()
              as RenderBox?;
      if (box == null || !box.attached) continue;
      insertion ??= index;
      final center = box.localToGlobal(Offset(0, box.size.height / 2));
      if (pointer.dy < center.dy) break;
      insertion = index + 1;
    }
    if (insertion != null) {
      final to = (insertion > from ? insertion - 1 : insertion).clamp(
        0,
        widget.slots.length - 1,
      );
      if (from != to) widget.onMove(from, to);
    }
    _finishDrag();
  }

  @override
  Widget build(BuildContext context) {
    final tasks = widget.universe.tasks;
    final schedule = buildDayStackSchedule(
      universe: widget.universe,
      order: [for (final slot in widget.slots) tasks[slot].id],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: ZennytGamePalette.gameBlue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        key: _viewportKey,
        borderRadius: BorderRadius.circular(12),
        child: Listener(
          onPointerCancel: (_) => _finishDrag(),
          child: DragTarget<int>(
            onWillAcceptWithDetails: (details) =>
                widget.slots.contains(details.data),
            onAcceptWithDetails: (_) => _drop(),
            builder: (context, candidates, rejected) => Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                key: const ValueKey('day-stack-schedule'),
                controller: _scrollController,
                padding: EdgeInsets.fromLTRB(0, 16, 4, 24 + widget.bottomInset),
                itemCount: widget.slots.length + 1,
                itemBuilder: (context, position) {
                  if (position == widget.slots.length) {
                    return _DayEnd(endMin: schedule.endMin);
                  }
                  final index = widget.slots[position];
                  return _CalendarItem(
                    key: ValueKey('day-stack-task-$index'),
                    universeId: widget.universe.id,
                    task: tasks[index],
                    tasks: tasks,
                    labelOf: widget.labelOf,
                    placement: schedule.placements[position],
                    eventKey: _eventKeys.putIfAbsent(index, GlobalKey.new),
                    onDragStarted: () => _startDrag(position),
                    onDragUpdate: (details) =>
                        _dragPosition = details.globalPosition,
                    onDragEnd: (_) => _finishDrag(),
                    data: index,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Un créneau fixe pendant le glissement : attente et repères restent visibles.
class _CalendarItem extends StatelessWidget {
  const _CalendarItem({
    super.key,
    required this.universeId,
    required this.task,
    required this.tasks,
    required this.labelOf,
    required this.placement,
    required this.eventKey,
    required this.onDragStarted,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.data,
  });

  final DayStackTask task;
  final List<DayStackTask> tasks;
  final String Function(DayStackTask) labelOf;
  final DayStackPlacement placement;
  final GlobalKey eventKey;
  final VoidCallback onDragStarted;
  final DragUpdateCallback onDragUpdate;
  final DragEndCallback onDragEnd;
  final int data;

  /// Univers de [task] : l'emote se choisit sur le couple univers + tâche.
  final String universeId;

  Widget _event({bool lifted = false}) => ConstrainedBox(
    constraints: BoxConstraints(
      minHeight: task.durationMin * kDayStackPxPerMinute,
    ),
    child: _CalendarEvent(
      universeId: universeId,
      task: task,
      tasks: tasks,
      labelOf: labelOf,
      placement: placement,
      lifted: lifted,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final wait = placement.waitBeforeMin;
    final waitFrom = placement.startMin - wait;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (wait > 0)
          SizedBox(
            height: wait * kDayStackPxPerMinute,
            child: CustomPaint(
              key: ValueKey('day-stack-wait-${task.id}'),
              painter: _HourGridPainter(
                fromMin: waitFrom,
                toMin: placement.startMin,
                includeStart: true,
              ),
            ),
          ),
        Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _HourGridPainter(
                  fromMin: placement.startMin,
                  toMin: placement.endMin,
                  // Le segment d’attente exclut son heure de fin.
                  // Le rendez-vous doit donc toujours tracer son début.
                  includeStart: true,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: kDayStackGutter),
              child: LayoutBuilder(
                builder: (context, constraints) => SizedBox(
                  key: eventKey,
                  child: LongPressDraggable<int>(
                    data: data,
                    maxSimultaneousDrags: 1,
                    onDragStarted: onDragStarted,
                    onDragUpdate: onDragUpdate,
                    onDragEnd: onDragEnd,
                    feedback: Material(
                      key: const ValueKey('day-stack-drag-proxy'),
                      type: MaterialType.transparency,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: SizedBox(
                        width: constraints.maxWidth,
                        child: _event(lifted: true),
                      ),
                    ),
                    childWhenDragging: Opacity(opacity: 0.35, child: _event()),
                    child: _event(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Le rendez-vous, au style d'un événement Outlook.
class _CalendarEvent extends StatelessWidget {
  const _CalendarEvent({
    required this.universeId,
    required this.task,
    required this.tasks,
    required this.labelOf,
    required this.placement,
    required this.lifted,
  });

  final DayStackTask task;
  final List<DayStackTask> tasks;
  final String Function(DayStackTask) labelOf;
  final DayStackPlacement placement;
  final bool lifted;
  final String universeId;

  @override
  Widget build(BuildContext context) {
    final color = dayStackCategoryColor(task.category);
    // Fond OPAQUE : les lignes horaires passent derrière le rendez-vous au
    // lieu de le traverser.
    const tint = ZennytGamePalette.gamePanel;
    // Les prérequis sont référencés par IDENTIFIANT, mais montrés au joueur
    // avec le libellé effectivement tiré : lui afficher une autre variante que
    // celle qu'il voit dans l'agenda l'empêcherait de faire le lien.
    final deps = task.deps
        .map((id) => labelOf(tasks.firstWhere((t) => t.id == id)))
        .join(', ');
    final constraint = dayStackConstraintLabel(task);
    final rest = task.restMin > 0 ? ' + ${task.restMin} min repos' : '';
    return Container(
      margin: const EdgeInsets.only(top: 2, bottom: 4),
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(8),
        boxShadow: lifted
            ? const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 14,
                  offset: Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            labelOf(task),
                            style: const TextStyle(
                              color: _Palette.title,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Le badge annonce déjà la catégorie ; l'emote reste
                        // décorative.
                        DayStackTaskBadge(
                          category: task.category,
                          icon: task.icon,
                          compact: true,
                          universeId: universeId,
                          taskId: task.id,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${task.durationMin} min$rest',
                      style: const TextStyle(
                        color: _Palette.detail,
                        fontSize: 12.5,
                        height: 1.3,
                      ),
                    ),
                    if (constraint != null) ...[
                      const SizedBox(height: 3),
                      _EventChip(
                        icon: Icons.schedule_rounded,
                        label: constraint,
                        color: color,
                      ),
                    ],
                    if (deps.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        'Après : $deps',
                        style: const TextStyle(
                          color: _Palette.detail,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _Palette.detail),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: _Palette.detail,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fin de journée : dernière ligne de l'agenda, sous le dernier rendez-vous.
class _DayEnd extends StatelessWidget {
  const _DayEnd({required this.endMin});

  final int endMin;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: CustomPaint(
        painter: _HourGridPainter(
          fromMin: endMin,
          toMin: endMin + 25,
          includeStart: true,
          forceStartLabel: true,
        ),
      ),
    );
  }
}

/// Colonne d'heures et lignes horaires d'un segment de l'agenda.
///
/// Les heures pleines tombant dans `[fromMin, toMin[` sont placées à leur
/// position relative dans la hauteur RÉELLE du segment : un rendez-vous étiré
/// pour loger son texte garde ainsi ses heures alignées.
class _HourGridPainter extends CustomPainter {
  _HourGridPainter({
    required this.fromMin,
    required this.toMin,
    required this.includeStart,
    this.forceStartLabel = false,
  });

  final int fromMin;
  final int toMin;
  final bool includeStart;

  /// Trace aussi l'heure exacte du début, même hors heure pleine (fin de
  /// journée).
  final bool forceStartLabel;

  @override
  void paint(Canvas canvas, Size size) {
    final span = toMin - fromMin;
    if (span <= 0) return;
    double yOf(int minute) => (minute - fromMin) / span * size.height;

    final hourPaint = Paint()
      ..color = _Palette.gridLine
      ..strokeWidth = 1;
    final halfPaint = Paint()
      ..color = _Palette.halfLine
      ..strokeWidth = 1;

    if (forceStartLabel) {
      canvas.drawLine(
        Offset(kDayStackGutter - 6, 0),
        Offset(size.width, 0),
        hourPaint,
      );
      _label(canvas, dayStackClock(fromMin), 0);
      return;
    }

    final firstHalf = ((fromMin + 29) ~/ 30) * 30;
    for (var m = firstHalf; m < toMin; m += 30) {
      if (m == fromMin && !includeStart) continue;
      final y = yOf(m);
      if (m % 60 == 0) {
        canvas.drawLine(
          Offset(kDayStackGutter - 6, y),
          Offset(size.width, y),
          hourPaint,
        );
        _label(canvas, dayStackClock(m), y);
      } else {
        canvas.drawLine(
          Offset(kDayStackGutter, y),
          Offset(size.width, y),
          halfPaint,
        );
      }
    }
  }

  void _label(Canvas canvas, String text, double y) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: _Palette.hourText,
          fontFamily: AppTypography.fontFamily,
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: kDayStackGutter - 8);
    painter.paint(
      canvas,
      Offset(kDayStackGutter - 10 - painter.width, y - painter.height / 2),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(_HourGridPainter old) =>
      old.fromMin != fromMin ||
      old.toMin != toMin ||
      old.includeStart != includeStart ||
      old.forceStartLabel != forceStartLabel;
}
