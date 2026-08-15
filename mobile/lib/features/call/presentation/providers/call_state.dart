import 'package:equatable/equatable.dart';
import '../../domain/entities/call.dart';

enum CallStatus2 { initial, loading, active, ended, error }

class CallState extends Equatable {
  final CallStatus2 status;
  final Call? call;
  final String? errorMessage;

  const CallState({
    this.status = CallStatus2.initial,
    this.call,
    this.errorMessage,
  });

  CallState copyWith({
    CallStatus2? status,
    Call? call,
    String? errorMessage,
  }) {
    return CallState(
      status: status ?? this.status,
      call: call ?? this.call,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, call, errorMessage];
}
