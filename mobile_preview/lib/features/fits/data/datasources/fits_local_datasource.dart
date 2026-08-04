import '../../domain/entities/fit_item.dart';
import '../models/fit_item_model.dart';

abstract class FitsLocalDataSource {
  Future<List<FitItemModel>> getFits(FitKind kind);

  /// Enregistre un swipe via POST /swipes.
  /// Retourne `true` si le swipe a produit un match.
  Future<bool> recordSwipe({
    required String targetId,
    required String targetType, // "JOB_OFFER" | "CANDIDATE"
    required String direction,  // "LIKE" | "PASS"
    String? jobOfferId,
  });
}

/// Implémentation **mock** du deck Fits (offres + professionnels).
class FitsMockDataSource implements FitsLocalDataSource {
  static const _logo = 'https://logo.clearbit.com/google.com';
  static const _about =
      "At Google, we're on a mission to organize the world's information and "
      "make it universally accessible and useful. As a UX/UI Designer, you'll "
      "play a critical role in shaping the future of our products and services.";

  static const _jobs = <FitItemModel>[
    FitItemModel(id: 'f1', kind: FitKind.jobOffer, fitScore: 100,
        name: 'Google inc', imageUrl: _logo, role: 'UX/UI Designer',
        location: 'California, USA',
        tags: ['Senior', 'Full-time', 'Hybride', 'International candidates welcome'],
        salary: '\$15K/Mo', about: _about),
    FitItemModel(id: 'f2', kind: FitKind.jobOffer, fitScore: 98,
        name: 'Google inc', imageUrl: _logo, role: 'Product Designer',
        location: 'California, USA',
        tags: ['Lead', 'Full-time', 'Remote'],
        salary: '\$22K/Mo', about: _about),
    FitItemModel(id: 'f3', kind: FitKind.jobOffer, fitScore: 91,
        name: 'Google inc', imageUrl: _logo, role: 'Frontend Engineer',
        location: 'California, USA',
        tags: ['Senior', 'Contract', 'On-site'],
        salary: '\$30K/Mo', about: _about),
  ];

  static const _pros = <FitItemModel>[
    FitItemModel(id: 'p1', kind: FitKind.professional, fitScore: 100,
        name: 'Alberta Flores', imageUrl: 'https://i.pravatar.cc/150?img=47',
        role: 'UX Designer | Senior', location: 'California, USA',
        targetRole: 'UX Designer | Senior',
        tags: ['Any type of contrat', 'Internationally', 'Immediately'],
        softSkills: [
          'Decision Making: High',
          'Cognitive Flexibility: Strong',
          'Emotional Regulation: Medium'
        ],
        hardSkills: ['InDesign: 88%', 'Figma: 85%']),
    FitItemModel(id: 'p2', kind: FitKind.professional, fitScore: 96,
        name: 'Kristin Watson', imageUrl: 'https://i.pravatar.cc/150?img=31',
        role: 'Engineer DEV | Senior', location: 'California, USA',
        targetRole: 'Engineer DEV | Senior',
        tags: ['Contract', 'Internationally', 'Immediately'],
        softSkills: [
          'Decision Making: Strong',
          'Cognitive Flexibility: High',
          'Emotional Regulation: High'
        ],
        hardSkills: ['Flutter: 90%', 'Dart: 88%']),
    FitItemModel(id: 'p3', kind: FitKind.professional, fitScore: 89,
        name: 'Sophia Martin', imageUrl: 'https://i.pravatar.cc/150?img=20',
        role: 'Product Designer | Mid', location: 'California, USA',
        targetRole: 'Product Designer | Mid',
        tags: ['Full-time', 'Locally', 'In 1 month'],
        softSkills: [
          'Decision Making: Medium',
          'Cognitive Flexibility: Strong',
          'Emotional Regulation: Medium'
        ],
        hardSkills: ['Figma: 92%', 'Sketch: 80%']),
  ];

  @override
  Future<List<FitItemModel>> getFits(FitKind kind) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return kind == FitKind.jobOffer ? _jobs : _pros;
  }

  @override
  Future<bool> recordSwipe({
    required String targetId,
    required String targetType,
    required String direction,
    String? jobOfferId,
  }) async {
    // Mock : un LIKE sur une carte à fitScore 100 produit un match.
    return false;
  }
}
