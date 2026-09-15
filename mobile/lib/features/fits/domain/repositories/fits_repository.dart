import '../../../jobs/domain/entities/job.dart';
import '../entities/candidate_profile.dart';
import '../entities/match_entity.dart';
import '../entities/swipe_result.dart';

/// Abstraction over the Fits API of the integrated backend
/// (`/job-offers/matching-deck`, `/job-offers/{id}/candidates/matching-deck`,
/// `/job-offers/{id}/swipes`, `/*/matches`). Implementations throw typed
/// `ApiException`s.
abstract class FitsRepository {
  /// `GET /job-offers/matching-deck` — candidate's swipe deck (pre-filtered:
  /// already-swiped-LEFT and matched offers are excluded server-side).
  Future<List<JobOffer>> getCandidateDeck();

  /// `GET /recruiters/me/job-offers?status=ACTIVE` — offers the recruiter can
  /// source candidates for (the "Sourcing:" context chips above the deck).
  Future<List<JobOffer>> getMyActiveOffers();

  /// `GET /recruiters/me/candidate-feed` — recruiter's fit-scored candidate
  /// feed for one offer, enriched with name/avatar/location by the backend.
  Future<List<CandidateProfile>> getCandidateFeed(String jobOfferId);

  /// `GET /job-offers/{id}/candidates/matching-deck` — recruiter's swipe deck
  /// (pre-filtered: already-swiped-LEFT and matched candidates excluded).
  Future<List<CandidateProfile>> getCandidateMatchingDeck(String jobOfferId);

  /// Recherche générale de candidats (recruteur), indépendante d'une offre.
  Future<List<CandidateProfile>> searchCandidates({String? query, String? location});

  /// `POST /job-offers/{jobOfferId}/swipes` (candidate) or
  /// `POST /job-offers/{jobOfferId}/candidates/{targetId}/swipes` (recruiter).
  Future<SwipeResult> swipe({
    required String targetId,
    required SwipeTargetType targetType,
    required String jobOfferId,
    required SwipeDirection direction,
  });

  /// `DELETE /job-offers/{jobOfferId}/swipes/me` (candidate) or
  /// `DELETE /job-offers/{jobOfferId}/candidates/{targetId}/swipes/me`
  /// (recruiter) — undo; the linked match dies in the same transaction.
  Future<void> undoSwipe({
    required String jobOfferId,
    required SwipeTargetType targetType,
    required String targetId,
  });

  /// `GET /candidates/me/matches`.
  Future<List<MatchEntity>> getCandidateMatches();

  /// `GET /job-offers/{jobId}/matches`.
  Future<List<MatchEntity>> getRecruiterMatches({required String jobOfferId});
}
