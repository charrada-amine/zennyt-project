import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/enums/user_role.dart';
import '../../../auth/presentation/current_user_provider.dart';
import '../../../games/presentation/view/games_hub_screen.dart';
import '../../../jobs/presentation/pages/recruiter/home/recruiter_home_page.dart';

/// Onglet du milieu, dont le contenu dépend du rôle (comme sur REC-04) :
/// candidat/étudiant -> hub des jeux sérieux cognitifs ("Progress") ;
/// recruteur -> hub offres + tests ("Careers", RecruiterHomePage).
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return user?.role == UserRole.recruiter
        ? const RecruiterHomePage()
        : const GamesHubScreen();
  }
}
