import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../di/injection.dart';
import '../../features/jobs/presentation/bloc/job_list_bloc.dart';
import '../../features/jobs/presentation/pages/job_list_page.dart';
import '../../features/home/presentation/bloc/feed_bloc.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/search/presentation/bloc/search_bloc.dart';
import '../../features/search/presentation/pages/search_page.dart';
import '../../features/fits/domain/entities/fit_item.dart';
import '../../features/fits/presentation/bloc/fits_bloc.dart';
import '../../features/fits/presentation/pages/fits_page.dart';
import '../../features/fits/presentation/pages/filter_page.dart';
import '../../features/fits/presentation/pages/job_detail_page.dart';
import '../../features/assessment/presentation/pages/assessment_test_page.dart';
import '../../features/matches/presentation/pages/matches_page.dart';
import '../../features/notifications/presentation/bloc/notifications_bloc.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/chat/domain/entities/chat_summary.dart';
import '../../features/chat/presentation/bloc/chat_list_bloc.dart';
import '../../features/chat/presentation/bloc/conversation_bloc.dart';
import '../../features/chat/presentation/pages/chats_page.dart';
import '../../features/chat/presentation/pages/conversation_page.dart';
import '../../features/chat/presentation/pages/video_call_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/careers/domain/entities/recruiter_job_offer.dart';
import '../../features/careers/presentation/bloc/careers_bloc.dart';
import '../../features/careers/presentation/pages/careers_page.dart';
import '../../features/careers/presentation/pages/recruiter_job_offer_page.dart';
import '../../features/careers/presentation/pages/hard_skills_scores_page.dart';
import '../../features/careers/presentation/pages/add_job_offer_page.dart';
import '../../features/careers/presentation/pages/job_description_editor_page.dart';
import '../../features/careers/presentation/pages/select_assessment_page.dart';
import '../../features/careers/presentation/pages/my_tests_page.dart';
import '../../features/careers/presentation/pages/create_test_page.dart';
import '../../features/careers/presentation/pages/add_questions_page.dart';
import '../../features/careers/presentation/pages/add_assessment_page.dart';
import '../../features/careers/presentation/pages/generate_test_ai_page.dart';
import '../../features/profile/presentation/pages/candidate_profile_page.dart';
import '../../features/profile/presentation/pages/resume_ai_page.dart';

/// Router central (GoRouter). Chaque feature déclare ses routes ; le BLoC est
/// fourni au niveau de la route via BlocProvider + GetIt.
///
/// Le `redirect` (commenté) brancherait la garde d'authentification une fois
/// le feature auth implémenté.
class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/home',
      // redirect: (context, state) { /* garde auth : si non connecté -> /auth/login */ },
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<FeedBloc>()..add(const FeedStarted()),
            child: const HomePage(),
          ),
        ),
        GoRoute(
          path: '/search',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<SearchBloc>()..add(const SearchStarted()),
            child: const SearchPage(),
          ),
        ),
        GoRoute(
          path: '/fits',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<FitsBloc>()..add(const FitsStarted()),
            child: const FitsPage(),
          ),
        ),
        GoRoute(path: '/filter', builder: (context, state) => const FilterPage()),
        GoRoute(
            path: '/job-detail',
            builder: (context, state) =>
                JobDetailPage(item: state.extra as FitItem?)),
        GoRoute(
            path: '/assessment',
            builder: (context, state) {
              final args = state.extra as Map<String, String?>?;
              return AssessmentTestPage(
                assessmentId: args?['assessmentId'],
                jobOfferId: args?['jobOfferId'],
              );
            }),
        GoRoute(
            path: '/matches', builder: (context, state) => const MatchesPage()),
        GoRoute(
          path: '/notifications',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<NotificationsBloc>()..add(const NotificationsStarted()),
            child: const NotificationsPage(),
          ),
        ),
        GoRoute(
          path: '/chats',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<ChatListBloc>()..add(const ChatListStarted()),
            child: const ChatsPage(),
          ),
        ),
        GoRoute(
          path: '/conversation',
          builder: (context, state) {
            final chat = state.extra as ChatSummary;
            return BlocProvider(
              create: (_) =>
                  sl<ConversationBloc>()..add(ConversationStarted(chat.id)),
              child: ConversationPage(chat: chat),
            );
          },
        ),
        GoRoute(
          path: '/call',
          builder: (context, state) =>
              VideoCallPage(chat: state.extra as ChatSummary),
        ),
        GoRoute(path: '/profile', builder: (context, state) => const ProfilePage()),
        GoRoute(
          path: '/careers',
          builder: (context, state) => BlocProvider(
            create: (_) => sl<CareersBloc>()..add(const CareersStarted()),
            child: const CareersPage(),
          ),
        ),
        GoRoute(
          path: '/recruiter/job-offer',
          builder: (context, state) =>
              RecruiterJobOfferPage(offer: state.extra as RecruiterJobOffer),
        ),
        GoRoute(
          path: '/recruiter/scores',
          builder: (context, state) =>
              HardSkillsScoresPage(offer: state.extra as RecruiterJobOffer),
        ),
        GoRoute(
            path: '/recruiter/add-offer',
            builder: (context, state) => const AddJobOfferPage()),
        GoRoute(
            path: '/recruiter/offer-description',
            builder: (context, state) => const JobDescriptionEditorPage()),
        GoRoute(
            path: '/recruiter/select-assessment',
            builder: (context, state) => const SelectAssessmentPage()),
        GoRoute(
            path: '/recruiter/my-tests',
            builder: (context, state) => const MyTestsPage()),
        GoRoute(
            path: '/recruiter/create-test',
            builder: (context, state) => const CreateTestPage()),
        GoRoute(
            path: '/recruiter/add-questions',
            builder: (context, state) =>
                AddQuestionsPage(title: state.extra as String? ?? 'Test')),
        GoRoute(
            path: '/recruiter/add-assessment',
            builder: (context, state) => const AddAssessmentPage()),
        GoRoute(
            path: '/recruiter/generate-ai',
            builder: (context, state) => const GenerateTestAiPage()),
        GoRoute(
            path: '/candidate-profile',
            builder: (context, state) => const CandidateProfilePage()),
        GoRoute(
            path: '/resume-ai', builder: (context, state) => const ResumeAiPage()),
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
