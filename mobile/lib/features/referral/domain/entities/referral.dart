import 'package:equatable/equatable.dart';

/// Statut d'un parrainage (contrat engagement).
enum ReferralStatus {
  invited('INVITED'),
  registered('REGISTERED'),
  hired('HIRED'),
  cancelled('CANCELLED');

  final String value;
  const ReferralStatus(this.value);

  static ReferralStatus fromString(String? v) => ReferralStatus.values
      .firstWhere((e) => e.value == v, orElse: () => ReferralStatus.invited);

  String get label {
    switch (this) {
      case ReferralStatus.invited:
        return 'Invited';
      case ReferralStatus.registered:
        return 'In progress';
      case ReferralStatus.hired:
        return 'Hired';
      case ReferralStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class Referral extends Equatable {
  final String id;
  final String inviteeEmail;
  final String? inviteeName;
  final String? inviteeAvatarUrl;
  final ReferralStatus status;
  final DateTime? createdAt;

  /// Jours restants avant la fin de la période d'essai (statut HIRED).
  final int? daysRemaining;

  const Referral({
    required this.id,
    required this.inviteeEmail,
    required this.status,
    this.inviteeName,
    this.inviteeAvatarUrl,
    this.createdAt,
    this.daysRemaining,
  });

  String get displayName =>
      (inviteeName != null && inviteeName!.isNotEmpty) ? inviteeName! : inviteeEmail;

  factory Referral.fromJson(Map<String, dynamic> json) => Referral(
        id: json['id']?.toString() ?? '',
        inviteeEmail: json['inviteeEmail'] as String? ?? '',
        inviteeName: json['inviteeName'] as String?,
        inviteeAvatarUrl: json['inviteeAvatarUrl'] as String?,
        status: ReferralStatus.fromString(json['status'] as String?),
        createdAt: json['createdAt'] != null
            ? DateTime.tryParse(json['createdAt'] as String)
            : null,
        daysRemaining: (json['daysRemaining'] as num?)?.toInt(),
      );

  @override
  List<Object?> get props => [id, inviteeEmail, status, daysRemaining];
}

class ReferralLink extends Equatable {
  final String code;
  final String url;
  final int bonusAmount;
  final String bonusCurrency;

  const ReferralLink({
    required this.code,
    required this.url,
    required this.bonusAmount,
    required this.bonusCurrency,
  });

  factory ReferralLink.fromJson(Map<String, dynamic> json) => ReferralLink(
        code: json['code'] as String? ?? '',
        url: json['url'] as String? ?? '',
        bonusAmount: (json['bonusAmount'] as num?)?.toInt() ?? 0,
        bonusCurrency: json['bonusCurrency'] as String? ?? 'USD',
      );

  @override
  List<Object?> get props => [code, url, bonusAmount, bonusCurrency];
}
