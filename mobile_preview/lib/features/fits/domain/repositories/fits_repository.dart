import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/fit_item.dart';

/// Port du domaine pour le deck "Fits".
abstract class FitsRepository {
  Future<Either<Failure, List<FitItem>>> getFits({required FitKind kind});

  /// Enregistre un swipe (LIKE/PASS) et retourne si un match a été créé.
  Future<Either<Failure, bool>> recordSwipe({
    required String targetId,
    required String targetType,
    required String direction,
    String? jobOfferId,
  });
}
