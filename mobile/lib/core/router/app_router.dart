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
import '../../features/games/presentation/view/games_hub_screen.dart';
import '../../features/games/presentation/view/move_fast_screen.dart';
import '../../features/games/presentation/view/planifik_screen.dart';
import '../../features/splash/presentation/view/splash_screen.dart';
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
        builder: (context, state) => const GamesHubScreen(),
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
