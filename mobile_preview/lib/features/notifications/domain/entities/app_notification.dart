import 'package:equatable/equatable.dart';

enum NotifType {
  jobOpportunity,
  interestConfirmed,
  comment,
  like,
  training,
  applicationRejected,
  applicationApproved,
  recruited,
  identityRequired,
  identitySuccess,
  identityFailure,
}

enum NotifGroup { today, yesterday }

/// Notification affichée dans l'écran Notifications. Pure (sans framework).
class AppNotification extends Equatable {
  final String id;
  final NotifType type;
  final String title;
  final String subtitle;
  final String time;
  final bool read;
  final NotifGroup group;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.time,
    this.read = false,
    this.group = NotifGroup.today,
  });

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        type: type,
        title: title,
        subtitle: subtitle,
        time: time,
        read: read ?? this.read,
        group: group,
      );

  @override
  List<Object?> get props => [id, type, title, subtitle, time, read, group];
}
