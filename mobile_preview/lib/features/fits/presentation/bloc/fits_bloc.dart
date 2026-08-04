import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../domain/entities/fit_item.dart';
import '../../domain/usecases/get_fits.dart';
import '../../domain/usecases/record_swipe.dart';

part 'fits_event.dart';
part 'fits_state.dart';

/// BLoC du deck "Fits" : navigation par swipe (like / pass / undo) et détection
/// de match. Les swipes sont enregistrés en temps réel via POST /swipes.
class FitsBloc extends Bloc<FitsEvent, FitsState> {
  final GetFits getFits;
  final RecordSwipe recordSwipe;

  FitsBloc({required this.getFits, required this.recordSwipe})
      : super(const FitsState()) {
    on<FitsStarted>((e, emit) => _load(emit, state.kind),
        transformer: restartable());
    on<FitsTabChanged>((e, emit) => _load(emit, e.kind),
        transformer: restartable());
    on<FitSwiped>(_onSwiped);
    on<FitUndo>(_onUndo);
    on<MatchDismissed>(_onDismiss);
  }

  Future<void> _load(Emitter<FitsState> emit, FitKind kind) async {
    emit(state.copyWith(
        status: FitsStatus.loading, kind: kind, index: 0, matched: false));
    final result = await getFits(GetFitsParams(kind: kind));
    result.fold(
      (failure) =>
          emit(state.copyWith(status: FitsStatus.error, message: failure.message)),
      (items) => emit(state.copyWith(
          status: FitsStatus.ready, items: items, index: 0, matched: false)),
    );
  }

  Future<void> _onSwiped(FitSwiped event, Emitter<FitsState> emit) async {
    final current = state.current;
    if (current == null) return;

    final direction = event.swipe == FitSwipe.like ? 'LIKE' : 'PASS';
    final targetType = current.kind == FitKind.jobOffer ? 'JOB_OFFER' : 'CANDIDATE';

    // Appel backend (fire-and-forget sur l'erreur : l'UI avance quand même).
    final result = await recordSwipe(RecordSwipeParams(
      targetId: current.id,
      targetType: targetType,
      direction: direction,
    ));

    final backendMatched = result.fold((_) => false, (matched) => matched);

    // Match : score élevé OU backend a confirmé un match mutuel.
    if (event.swipe == FitSwipe.like && !state.matched &&
        (backendMatched || current.fitScore >= 99)) {
      emit(state.copyWith(matched: true));
    } else {
      emit(state.copyWith(index: state.index + 1, matched: false));
    }
  }

  void _onUndo(FitUndo event, Emitter<FitsState> emit) {
    emit(state.copyWith(
        index: state.index > 0 ? state.index - 1 : 0, matched: false));
  }

  void _onDismiss(MatchDismissed event, Emitter<FitsState> emit) {
    emit(state.copyWith(index: state.index + 1, matched: false));
  }
}
