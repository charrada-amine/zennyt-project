import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/fits_repository.dart';

/// Enregistre un swipe (LIKE ou PASS) via POST /swipes.
/// Retourne `true` si le backend a détecté un match mutuel.
class RecordSwipe extends UseCase<bool, RecordSwipeParams> {
  final FitsRepository repository;
  RecordSwipe(this.repository);

  @override
  Future<Either<Failure, bool>> call(RecordSwipeParams params) {
    return repository.recordSwipe(
      targetId: params.targetId,
      targetType: params.targetType,
      direction: params.direction,
      jobOfferId: params.jobOfferId,
    );
  }
}

class RecordSwipeParams extends Equatable {
  final String targetId;
  final String targetType; // "JOB_OFFER" | "CANDIDATE"
  final String direction;  // "LIKE" | "PASS"
  final String? jobOfferId;

  const RecordSwipeParams({
    required this.targetId,
    required this.targetType,
    required this.direction,
    this.jobOfferId,
  });

  @override
  List<Object?> get props => [targetId, targetType, direction, jobOfferId];
}
