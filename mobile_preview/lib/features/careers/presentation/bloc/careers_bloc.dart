import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/recruiter_job_offer.dart';
import '../../domain/entities/recruiter_test.dart';
import '../../domain/usecases/get_my_job_offers.dart';
import '../../domain/usecases/get_my_tests.dart';

part 'careers_event.dart';
part 'careers_state.dart';

class CareersBloc extends Bloc<CareersEvent, CareersState> {
  final GetMyTests getMyTests;
  final GetMyJobOffers getMyJobOffers;

  CareersBloc({required this.getMyTests, required this.getMyJobOffers})
      : super(const CareersState()) {
    on<CareersStarted>(_onStarted, transformer: restartable());
  }

  Future<void> _onStarted(
      CareersStarted event, Emitter<CareersState> emit) async {
    emit(state.copyWith(status: CareersStatus.loading));
    final tests = await getMyTests(const NoParams());
    final offers = await getMyJobOffers(const NoParams());

    final failure = tests.fold((f) => f, (_) => null) ??
        offers.fold((f) => f, (_) => null);
    if (failure != null) {
      emit(state.copyWith(status: CareersStatus.error, message: failure.message));
      return;
    }
    emit(state.copyWith(
      status: CareersStatus.ready,
      tests: tests.getOrElse(() => const []),
      offers: offers.getOrElse(() => const []),
    ));
  }
}
