import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/injection.dart';
import '../../features/jobs/presentation/bloc/job_list_bloc.dart';
import '../../features/jobs/presentation/pages/job_list_page.dart';

/// Router central (GoRouter). Chaque feature déclare ses routes ; le BLoC est
/// fourni au niveau de la route via BlocProvider + GetIt.
///
/// Le `redirect` (commenté) brancherait la garde d'authentification une fois
/// le feature auth implémenté.
class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/jobs',
      // redirect: (context, state) { /* garde auth : si non connecté -> /auth/login */ },
      routes: [
        GoRoute(
          path: '/jobs',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<JobListBloc>()..add(const JobsLoaded()),
            child: const JobListPage(),
          ),
        ),
        // GoRoute(path: '/auth/login', ...) — feature auth
        // GoRoute(path: '/profile', ...)   — feature profile
      ],
    );
  }
}
