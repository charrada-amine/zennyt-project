import '../../../jobs/domain/entities/job.dart';
import '../entities/candidate_profile.dart';
import '../entities/match_entity.dart';
import '../entities/swipe_result.dart';

/// Abstraction over the Fits API of the integrated backend
/// (`/job-offers`, `/recruiters/me/candidate-feed`, `/swipes`, `/*/matches`).
/// Implementations throw typed `ApiException`s.
abstract class FitsRepository {
  /// `GET /job-offers` — candidate's swipe deck (server-side fit-score sorted).
  Future<List<JobOffer>> getCandidateDeck();

  /// `GET /recruiters/me/job-offers?status=ACTIVE` — offers the recruiter can
  /// source candidates for (the "Sourcing:" context chips above the deck).
  Future<List<JobOffer>> getMyActiveOffers();

  /// `GET /recruiters/me/candidate-feed` — recruiter's fit-scored candidate
  /// deck for one offer, enriched with name/avatar/location by the backend.
  Future<List<CandidateProfile>> getCandidateFeed(String jobOfferId);

  /// `GET /swipes/targets` — ids already swiped, to exclude from the deck.
  Future<List<String>> getSwipedTargetIds({String? jobOfferId});

  /// `POST /swipes`.
  Future<SwipeResult> swipe({
    required String targetId,
    required SwipeTargetType targetType,
    required String jobOfferId,
    required SwipeDirection direction,
  });

  /// `DELETE /swipes/{swipeId}` — undo; the linked match dies in the same
  /// transaction server-side.
  Future<void> undoSwipe(String swipeId);

  /// `GET /candidates/me/matches`.
  Future<List<MatchEntity>> getCandidateMatches();

  /// `GET /recruiters/me/matches`.
  Future<List<MatchEntity>> getRecruiterMatches({String? jobOfferId});
}
