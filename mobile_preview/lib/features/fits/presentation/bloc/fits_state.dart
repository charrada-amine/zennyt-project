part of 'fits_bloc.dart';

enum FitsStatus { initial, loading, ready, error }

class FitsState extends Equatable {
  final FitsStatus status;
  final FitKind kind;
  final List<FitItem> items;
  final int index;
  final bool matched;
  final String message;

  const FitsState({
    this.status = FitsStatus.initial,
    this.kind = FitKind.jobOffer,
    this.items = const [],
    this.index = 0,
    this.matched = false,
    this.message = '',
  });

  FitItem? get current =>
      index >= 0 && index < items.length ? items[index] : null;

  bool get deckFinished => status == FitsStatus.ready && current == null;

  FitsState copyWith({
    FitsStatus? status,
    FitKind? kind,
    List<FitItem>? items,
    int? index,
    bool? matched,
    String? message,
  }) {
    return FitsState(
      status: status ?? this.status,
      kind: kind ?? this.kind,
      items: items ?? this.items,
      index: index ?? this.index,
      matched: matched ?? this.matched,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, kind, items, index, matched, message];
}
