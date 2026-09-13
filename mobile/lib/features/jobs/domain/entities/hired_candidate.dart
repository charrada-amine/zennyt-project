import 'package:equatable/equatable.dart';

/// Recrutement confirmé d'un recruteur (maquette 258), avec compte à rebours
/// de la période d'essai.
class HiredCandidate extends Equatable {
  final String id;
  final String candidateId;
  final String? fullName;
  final String? avatarUrl;
  final String title;
  final String status;
  final DateTime? hiredAt;
  final DateTime? probationEndsAt;
  final int? daysRemaining;
  final bool cancellable;

  const HiredCandidate({
    required this.id,
    required this.candidateId,
    required this.title,
    required this.status,
    this.fullName,
    this.avatarUrl,
    this.hiredAt,
    this.probationEndsAt,
    this.daysRemaining,
    this.cancellable = false,
  });

  String get displayName =>
      (fullName != null && fullName!.isNotEmpty) ? fullName! : 'Candidate';

  bool get isCancelled => status == 'CANCELLED';

  factory HiredCandidate.fromJson(Map<String, dynamic> json) => HiredCandidate(
        id: json['id']?.toString() ?? '',
        candidateId: json['candidateId']?.toString() ?? '',
        fullName: json['fullName'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
        title: json['title'] as String? ?? '',
        status: json['status'] as String? ?? 'CONFIRMED',
        hiredAt: json['hiredAt'] != null ? DateTime.tryParse(json['hiredAt'] as String) : null,
        probationEndsAt: json['probationEndsAt'] != null
            ? DateTime.tryParse(json['probationEndsAt'] as String)
            : null,
        daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
        cancellable: json['cancellable'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [id, status, daysRemaining, cancellable];
}
