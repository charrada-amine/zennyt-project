import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/login/view/login_screen.dart';
import '../../features/auth/presentation/forgot_password/view/forgot_password_method_screen.dart';
import '../../features/auth/presentation/forgot_password/view/forgot_password_email_screen.dart';
import '../../features/auth/presentation/forgot_password/view/forgot_password_otp_screen.dart';
import '../../features/auth/presentation/signup/view/change_phone_screen.dart';
import '../../features/auth/presentation/signup/view/create_account_screen.dart';
import '../../features/auth/presentation/signup/view/otp_screen.dart';
import '../../features/onboarding/presentation/view/onboarding_screen.dart';
import '../../features/profile_setup/presentation/view/field_of_work_screen.dart';
import '../../features/profile_setup/presentation/view/profile_setup_screen.dart';
import '../../features/profile_settings/presentation/view/accessibility_screen.dart';
import '../../features/profile_settings/presentation/view/language_settings_screen.dart';
import '../../features/profile_settings/presentation/view/profile_settings_screen.dart';
import '../../features/profile_settings/presentation/view/user_profile_screen.dart';
import '../../features/profile_settings/presentation/view/edit_profile_screen.dart';
import '../../features/profile_settings/presentation/view/recruiter_edit_profile_screen.dart';
import '../../features/profile_settings/presentation/view/share_post_screen.dart';
import '../../features/profile_settings/presentation/view/account_center_screen.dart';
import '../../features/profile_settings/presentation/view/personal_informations_screen.dart';
import '../../features/profile_settings/presentation/view/privacy_policy_screen.dart';
import '../../features/navigation/presentation/view/main_navigation_screen.dart';
import '../../features/games/presentation/view/emotional_radar_screen.dart';
import '../../features/games/presentation/view/continuous_attention_screen.dart';
import '../../features/games/presentation/view/coordination_tracking_screen.dart';
import '../../features/games/presentation/view/investigate_screen.dart';
import '../../features/games/presentation/view/je_place_screen.dart';
import '../../features/games/presentation/view/je_decide_screen.dart';
import '../../features/games/presentation/view/move_fast_screen.dart';
import '../../features/games/presentation/view/planifik_screen.dart';
import '../../features/games/presentation/view/predictive_puzzle_screen.dart';
import '../../features/games/presentation/view/reflective_pause_screen.dart';
import '../../features/games/presentation/view/task_scheduling_screen.dart';
import '../../features/splash/presentation/view/splash_screen.dart';
import '../../features/profile_settings/cv_autofill/presentation/view/cv_camera_capture_screen.dart';
import '../../features/profile_settings/cv_autofill/presentation/view/cv_processing_screen.dart';
import '../../features/profile_settings/cv_autofill/presentation/view/cv_review_screen.dart';
import '../../features/search/presentation/pages/candidate_filter_page.dart';
import '../../features/jobs/domain/entities/assessment.dart';
import '../../features/jobs/domain/entities/job.dart';
import '../../features/jobs/presentation/pages/recruiter/assessments/assessment_detail_page.dart';
import '../../features/jobs/presentation/pages/recruiter/assessments/create_assessment_page.dart';
import '../../features/jobs/presentation/pages/recruiter/jobs/create/create_job_offer_page.dart';
import '../../features/jobs/presentation/pages/recruiter/jobs/create/select_assessment_page.dart';
import 'app_routes.dart';

/// Routes the user can reach while signed out (onboarding + the whole sign-up
/// flow, since registration is deferred until the end of profile setup).
const _publicRoutes = <String>{
  AppRoutes.splash,
  AppRoutes.onboarding,
  AppRoutes.login,
  AppRoutes.forgotPasswordMethod,
  AppRoutes.forgotPasswordEmail,
  AppRoutes.forgotPasswordOtp,
  AppRoutes.signup,
  AppRoutes.otp,
  AppRoutes.changePhone,
  AppRoutes.profileSetup,
  AppRoutes.fieldOfWork,
};

/// Routes a signed-in user should be bounced away from (back to home).
const _authOnlyEntryRoutes = <String>{
  AppRoutes.login,
  AppRoutes.forgotPasswordMethod,
  AppRoutes.forgotPasswordEmail,
  AppRoutes.forgotPasswordOtp,
  AppRoutes.signup,
  AppRoutes.otp,
  AppRoutes.changePhone,
  AppRoutes.profileSetup,
  AppRoutes.fieldOfWork,
  AppRoutes.onboarding,
};

/// Auth-aware [GoRouter]. Redirects are driven by the [authControllerProvider]
/// session; [refreshListenable] re-evaluates them whenever the session changes.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;

      // While the session is being restored on cold start, hold on splash.
      if (auth.isLoading) {
        return loc == AppRoutes.splash ? null : AppRoutes.splash;
      }

      final loggedIn = auth.value != null;

      if (!loggedIn) {
        // Let the splash animation decide onboarding vs login.
        if (loc == AppRoutes.splash) return null;
        return _publicRoutes.contains(loc) ? null : AppRoutes.login;
      }

      // Signed in: keep users out of the auth/onboarding flow.
      if (loc == AppRoutes.splash || _authOnlyEntryRoutes.contains(loc)) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: AppRoutes.nSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: AppRoutes.nOnboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: AppRoutes.nLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordMethod,
        name: AppRoutes.nForgotPasswordMethod,
        builder: (context, state) => const ForgotPasswordMethodScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordEmail,
        name: AppRoutes.nForgotPasswordEmail,
        builder: (context, state) => const ForgotPasswordEmailScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPasswordOtp,
        name: AppRoutes.nForgotPasswordOtp,
        builder: (context, state) {
          final email = state.extra as String? ?? '';
          return ForgotPasswordOtpScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.signup,
        name: AppRoutes.nSignup,
        builder: (context, state) => const CreateAccountScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: AppRoutes.nOtp,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: AppRoutes.changePhone,
        name: AppRoutes.nChangePhone,
        builder: (context, state) => const ChangePhoneScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        name: AppRoutes.nProfileSetup,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.fieldOfWork,
        name: AppRoutes.nFieldOfWork,
        builder: (context, state) => const FieldOfWorkScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        name: AppRoutes.nHome,
        builder: (context, state) => const MainNavigationScreen(),
      ),
      // Games (jeux sérieux cognitifs)
      GoRoute(
        path: AppRoutes.games,
        name: AppRoutes.nGames,
        builder: (context, state) => const MainNavigationScreen(initialTab: 2),
      ),
      GoRoute(
        path: AppRoutes.gamesPlanifik,
        name: AppRoutes.nGamesPlanifik,
        builder: (context, state) => const PlanifikScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesMoveFast,
        name: AppRoutes.nGamesMoveFast,
        builder: (context, state) => const MoveFastScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesJeContinue,
        name: AppRoutes.nGamesJeContinue,
        builder: (context, state) => const ContinuousAttentionScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesJeCoordonne,
        name: AppRoutes.nGamesJeCoordonne,
        builder: (context, state) => const CoordinationTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesPredictivePuzzle,
        name: AppRoutes.nGamesPredictivePuzzle,
        builder: (context, state) => const PredictivePuzzleScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesTaskScheduling,
        name: AppRoutes.nGamesTaskScheduling,
        builder: (context, state) => const TaskSchedulingScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesInvestigate,
        name: AppRoutes.nGamesInvestigate,
        builder: (context, state) => const InvestigateScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesJePlace,
        name: AppRoutes.nGamesJePlace,
        builder: (context, state) => const JePlaceScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesJeDecide,
        name: AppRoutes.nGamesJeDecide,
        builder: (context, state) => const JeDecideScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesEmotionalRadar,
        name: AppRoutes.nGamesEmotionalRadar,
        builder: (context, state) => const EmotionalRadarScreen(),
      ),
      GoRoute(
        path: AppRoutes.gamesReflectivePause,
        name: AppRoutes.nGamesReflectivePause,
        builder: (context, state) => const ReflectivePauseScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSettings,
        name: AppRoutes.nProfileSettings,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const ProfileSettingsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  // Slide in from the left, like a drawer
                  const begin = Offset(-1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  final offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.languageSettings,
        name: AppRoutes.nLanguageSettings,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const LanguageSettingsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  final offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.accessibility,
        name: AppRoutes.nAccessibility,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AccessibilityScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  final offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.userProfile,
        name: AppRoutes.nUserProfile,
        builder: (context, state) => const UserProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.cvCameraCapture,
        name: AppRoutes.nCvCameraCapture,
        builder: (context, state) => const CvCameraCaptureScreen(),
      ),
      GoRoute(
        path: AppRoutes.cvProcessing,
        name: AppRoutes.nCvProcessing,
        builder: (context, state) {
          final filePath = state.uri.queryParameters['filePath'];
          final imagePaths = state.uri.queryParameters['imagePaths'];
          final url = state.uri.queryParameters['url'];
          return CvProcessingScreen(
            filePath: filePath,
            imagePaths: imagePaths,
            url: url,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.cvReview,
        name: AppRoutes.nCvReview,
        builder: (context, state) => const CvReviewScreen(),
      ),
      GoRoute(
        path: AppRoutes.searchFilter,
        name: AppRoutes.nSearchFilter,
        builder: (context, state) => const CandidateFilterPage(),
      ),
      GoRoute(
        path: AppRoutes.createJob,
        name: AppRoutes.nCreateJob,
        builder: (context, state) => const CreateJobOfferPage(),
      ),
      GoRoute(
        path: AppRoutes.jobDetail,
        name: AppRoutes.nJobDetail,
        builder: (context, state) => _NotYetPortedPage(
          title: 'Job offer',
          message: 'The job offer detail page (description, company, assessment tabs) '
              "hasn't been ported from REC-04 yet.",
        ),
      ),
      GoRoute(
        path: AppRoutes.editJob,
        name: AppRoutes.nEditJob,
        builder: (context, state) => CreateJobOfferPage(existingJob: state.extra as JobOffer?),
      ),
      GoRoute(
        path: AppRoutes.jobResults,
        name: AppRoutes.nJobResults,
        builder: (context, state) => _NotYetPortedPage(
          title: 'Results',
          message: "The hard-skills results page hasn't been ported from REC-04 yet.",
        ),
      ),
      GoRoute(
        path: AppRoutes.createAssessment,
        name: AppRoutes.nCreateAssessment,
        builder: (context, state) => const CreateAssessmentPage(),
      ),
      GoRoute(
        path: AppRoutes.assessmentDetail,
        name: AppRoutes.nAssessmentDetail,
        builder: (context, state) => AssessmentDetailPage(
          assessmentId: state.pathParameters['assessmentId']!,
        ),
      ),
      GoRoute(
        path: AppRoutes.editAssessment,
        name: AppRoutes.nEditAssessment,
        builder: (context, state) =>
            CreateAssessmentPage(existingAssessment: state.extra as Assessment?),
      ),
      GoRoute(
        path: AppRoutes.selectAssessment,
        name: AppRoutes.nSelectAssessment,
        builder: (context, state) => SelectAssessmentPage(
          currentSelectedId: state.extra as String?,
        ),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: AppRoutes.nEditProfile,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const EditProfileScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  final offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.recruiterEditProfile,
        name: AppRoutes.nRecruiterEditProfile,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const RecruiterEditProfileScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  final offsetAnimation = animation.drive(tween);

                  return SlideTransition(
                    position: offsetAnimation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.sharePost,
        name: AppRoutes.nSharePost,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const SharePostScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0); // Slide up
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: child,
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.accountCenter,
        name: AppRoutes.nAccountCenter,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const AccountCenterScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.personalInformations,
        name: AppRoutes.nPersonalInformations,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const PersonalInformationsScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
          );
        },
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        name: AppRoutes.nPrivacyPolicy,
        pageBuilder: (context, state) {
          return CustomTransitionPage(
            key: state.pageKey,
            child: const PrivacyPolicyScreen(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  const begin = Offset(1.0, 0.0);
                  const end = Offset.zero;
                  const curve = Curves.easeOutCubic;

                  final tween = Tween(
                    begin: begin,
                    end: end,
                  ).chain(CurveTween(curve: curve));
                  return SlideTransition(
                    position: animation.drive(tween),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
          );
        },
      ),
    ],
  );
});

/// Placeholder for Careers screens not yet ported from REC-04.
class _NotYetPortedPage extends StatelessWidget {
  const _NotYetPortedPage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
