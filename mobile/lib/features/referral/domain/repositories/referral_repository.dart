import '../entities/referral.dart';

/// Parrainage (programme Ambassadeur) — contrat engagement.
abstract class ReferralRepository {
  /// `GET /referrals/me`
  Future<List<Referral>> getMyReferrals();

  /// `POST /referrals/invite`
  Future<Referral> invite(String email);

  /// `GET /referrals/me/link`
  Future<ReferralLink> getMyLink();
}
