import '../../domain/entities/suggestion.dart';
import '../models/suggestion_model.dart';

/// Source de données de recherche.
abstract class SearchLocalDataSource {
  Future<List<SuggestionModel>> getSuggestions(SuggestionKind kind);
}

/// Implémentation **mock** — données factices en dur (cf. maquette Search).
/// À remplacer plus tard par un `SearchRemoteDataSource` (Dio) sans toucher l'UI.
class SearchMockDataSource implements SearchLocalDataSource {
  static const _logo = 'https://logo.clearbit.com/google.com';

  static const _jobs = <SuggestionModel>[
    SuggestionModel(id: 'j1', kind: SuggestionKind.jobOffer, fitScore: 100,
        name: 'Google inc', imageUrl: _logo, role: 'Developer',
        location: 'California, USA', tags: ['Lead', 'Full-time', 'On-site'],
        salary: '\$25K/Mo'),
    SuggestionModel(id: 'j2', kind: SuggestionKind.jobOffer, fitScore: 99,
        name: 'Google inc', imageUrl: _logo, role: 'Engineer DEV',
        location: 'California, USA', tags: ['Lead', 'Full-time', 'Hybrid'],
        salary: '\$30K/Mo'),
    SuggestionModel(id: 'j3', kind: SuggestionKind.jobOffer, fitScore: 98,
        name: 'Google inc', imageUrl: _logo, role: 'Developer',
        location: 'California, USA', tags: ['Manager', 'Contract', 'Remote'],
        salary: '\$35K/Mo'),
    SuggestionModel(id: 'j4', kind: SuggestionKind.jobOffer, fitScore: 89,
        name: 'Google inc', imageUrl: _logo, role: 'Engineer DEV',
        location: 'California, USA', tags: ['Junior', 'Full-time', 'Hybrid'],
        salary: '\$12K/Mo'),
    SuggestionModel(id: 'j5', kind: SuggestionKind.jobOffer, fitScore: 88,
        name: 'Google inc', imageUrl: _logo, role: 'Product Designer',
        location: 'California, USA', tags: ['Senior', 'Full-time', 'On-site'],
        salary: '\$28K/Mo'),
    SuggestionModel(id: 'j6', kind: SuggestionKind.jobOffer, fitScore: 87,
        name: 'Google inc', imageUrl: _logo, role: 'Data Engineer',
        location: 'California, USA', tags: ['Lead', 'Contract', 'Remote'],
        salary: '\$32K/Mo'),
  ];

  static const _pros = <SuggestionModel>[
    SuggestionModel(id: 'p1', kind: SuggestionKind.professional, fitScore: 100,
        name: 'Alberta Flores', imageUrl: 'https://i.pravatar.cc/150?img=47',
        role: 'Developer | Senior', location: 'California, USA',
        tags: ['Contract', 'Internationally', 'Immediately']),
    SuggestionModel(id: 'p2', kind: SuggestionKind.professional, fitScore: 99,
        name: 'Kristin Watson', imageUrl: 'https://i.pravatar.cc/150?img=31',
        role: 'Engineer DEV | Senior', location: 'California, USA',
        tags: ['Contract', 'Internationally', 'Immediately']),
    SuggestionModel(id: 'p3', kind: SuggestionKind.professional, fitScore: 98,
        name: 'Alberta Flores', imageUrl: 'https://i.pravatar.cc/150?img=45',
        role: 'Developer | Junior', location: 'California, USA',
        tags: ['Contract', 'Internationally', 'Immediately']),
    SuggestionModel(id: 'p4', kind: SuggestionKind.professional, fitScore: 97,
        name: 'Alberta Flores', imageUrl: 'https://i.pravatar.cc/150?img=44',
        role: 'Engineer DEV | Senior', location: 'California, USA',
        tags: ['Contract', 'Internationally', 'Immediately']),
    SuggestionModel(id: 'p5', kind: SuggestionKind.professional, fitScore: 89,
        name: 'Alberta Flores', imageUrl: 'https://i.pravatar.cc/150?img=48',
        role: 'Product Designer | Mid', location: 'California, USA',
        tags: ['Full-time', 'Internationally', 'Immediately']),
    SuggestionModel(id: 'p6', kind: SuggestionKind.professional, fitScore: 87,
        name: 'Alberta Flores', imageUrl: 'https://i.pravatar.cc/150?img=43',
        role: 'Developer | Senior', location: 'California, USA',
        tags: ['Contract', 'Locally', 'Immediately']),
  ];

  @override
  Future<List<SuggestionModel>> getSuggestions(SuggestionKind kind) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return kind == SuggestionKind.jobOffer ? _jobs : _pros;
  }
}
