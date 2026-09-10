import 'package:equatable/equatable.dart';

enum CallType { audio, video }
enum CallStatus { incoming, outgoing, ongoing, ended }

class Call extends Equatable {
  final String id;
  final String contactName;
  final CallType type;
  final CallStatus status;
  final DateTime startTime;
  final Duration? duration;

  const Call({
    required this.id,
    required this.contactName,
    required this.type,
    required this.status,
    required this.startTime,
    this.duration,
  });

  @override
  List<Object?> get props => [id, contactName, type, status, startTime, duration];
}