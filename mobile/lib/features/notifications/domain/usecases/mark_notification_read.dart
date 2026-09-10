import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/notification_repository.dart';

class MarkNotificationRead
    implements UseCase<void, MarkNotificationReadParams> {
  final NotificationRepository repository;
  MarkNotificationRead(this.repository);

  @override
  Future<Either<Failure, void>> call(MarkNotificationReadParams params) {
    return repository.markAsRead(params.id, params.userId);
  }
}

class MarkNotificationReadParams extends Equatable {
  final String id;
  final String userId;
  const MarkNotificationReadParams({required this.id, required this.userId});

  @override
  List<Object?> get props => [id, userId];
}
