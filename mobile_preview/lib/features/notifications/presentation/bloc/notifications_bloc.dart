import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/usecase/usecase.dart';
import '../../domain/entities/app_notification.dart';
import '../../domain/usecases/get_notifications.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final GetNotifications getNotifications;

  NotificationsBloc({required this.getNotifications})
      : super(const NotificationsState()) {
    on<NotificationsStarted>(_onStarted, transformer: restartable());
    on<NotificationMarkedRead>(_onRead);
  }

  Future<void> _onStarted(
      NotificationsStarted event, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(status: NotifStatus.loading));
    final result = await getNotifications(const NoParams());
    result.fold(
      (f) => emit(state.copyWith(status: NotifStatus.error, message: f.message)),
      (items) => emit(state.copyWith(status: NotifStatus.ready, items: items)),
    );
  }

  void _onRead(NotificationMarkedRead event, Emitter<NotificationsState> emit) {
    final updated = state.items
        .map((n) => n.id == event.id ? n.copyWith(read: true) : n)
        .toList();
    emit(state.copyWith(items: updated));
  }
}
