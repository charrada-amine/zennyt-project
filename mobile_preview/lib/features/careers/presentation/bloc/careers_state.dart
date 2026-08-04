part of 'careers_bloc.dart';

enum CareersStatus { initial, loading, ready, error }

class CareersState extends Equatable {
  final CareersStatus status;
  final List<RecruiterTest> tests;
  final List<RecruiterJobOffer> offers;
  final String message;

  const CareersState({
    this.status = CareersStatus.initial,
    this.tests = const [],
    this.offers = const [],
    this.message = '',
  });

  CareersState copyWith({
    CareersStatus? status,
    List<RecruiterTest>? tests,
    List<RecruiterJobOffer>? offers,
    String? message,
  }) {
    return CareersState(
      status: status ?? this.status,
      tests: tests ?? this.tests,
      offers: offers ?? this.offers,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [status, tests, offers, message];
}
