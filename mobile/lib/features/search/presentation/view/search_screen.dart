import 'package:flutter/material.dart';

import '../pages/search_candidate_page.dart';

/// Onglet « Search » : porté depuis REC-04 (mobile/zennyt), branché sur le
/// backend intégré. Même écran pour candidat et recruteur — la source des
/// résultats bascule selon le rôle dans searchResultsProvider.
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SearchCandidatePage();
  }
}
