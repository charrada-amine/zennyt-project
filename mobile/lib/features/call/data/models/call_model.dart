import '../../domain/entities/call.dart';

class CallModel {
  final String id;
  final String contactName;
  final CallType type;
  final CallStatus status;
  final DateTime startTime;
  final Duration? duration;

  const CallModel({
    required this.id,
    required this.contactName,
    required this.type,
    required this.status,
    required this.startTime,
    this.duration,
  });

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      id: json['id'] as String,
      contactName: json['contactName'] as String,
      type: CallType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => CallType.video,
      ),
      status: CallStatus.values.firstWhere(
        (e) => e.name == json['status'] as String,
        orElse: () => CallStatus.ongoing,
      ),
      startTime: DateTime.parse(json['startTime'] as String),
      duration: json['duration'] != null
          ? Duration(milliseconds: json['duration'] as int)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'contactName': contactName,
        'type': type.name,
        'status': status.name,
        'startTime': startTime.toIso8601String(),
        'duration': duration?.inMilliseconds,
      };

  CallModel copyWith({
    String? id,
    String? contactName,
    CallType? type,
    CallStatus? status,
    DateTime? startTime,
    Duration? duration,
  }) {
    return CallModel(
      id: id ?? this.id,
      contactName: contactName ?? this.contactName,
      type: type ?? this.type,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
    );
  }

  Call toEntity() => Call(
        id: id,
        contactName: contactName,
        type: type,
        status: status,
        startTime: startTime,
        duration: duration,
      );
}