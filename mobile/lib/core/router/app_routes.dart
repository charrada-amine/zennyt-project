/// Centralized route paths and names for the app's [GoRouter] configuration.
///
/// Using constants avoids magic strings scattered across the codebase and keeps
/// navigation type-safe and refactor-friendly.
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';

  static const String onboarding = '/onboarding';

  static const String login = '/login';
  static const String forgotPasswordMethod = '/login/forgot-password';
  static const String forgotPasswordEmail = '/login/forgot-password/email';
  static const String forgotPasswordOtp = '/login/forgot-password/otp';

  static const String signup = '/signup';
  static const String otp = '/signup/otp';
  static const String changePhone = '/signup/change-phone';

  static const String profileSetup = '/profile-setup';
  static const String fieldOfWork = '/profile-setup/field-of-work';

  static const String home = '/home';

  // Jobs, Calls, Chat & Community Features
  static const String jobs = '/jobs';
  static const String call = '/call';
  static const String videoCall = '/video-call';
  static const String chats = '/chats';
  static const String chatDetail = '/chats/:id';
  static const String createPost = '/create-post';
  static const String createPostMedia = '/create-post/media';
  static const String createPostPoll = '/create-post/poll';
  static const String helpCenter = '/help-center';
  static const String helpCenterDetail = '/help-center/:id';
  static const String testFeatures = '/test-features';
  static const String notifications = '/notifications';

  // Games (jeux sérieux cognitifs)
  static const String games = '/games';
  static const String gamesPlanifik = '/games/planifik';
  static const String gamesMoveFast = '/games/move-fast';
  static const String gamesPredictivePuzzle = '/games/predictive-puzzle';
  static const String gamesTaskScheduling = '/games/task-scheduling';
  static const String gamesInvestigate = '/games/investigate';

  static const String profileSettings = '/profile-settings';
  static const String accountCenter = '/profile-settings/account-center';
  static const String personalInformations =
      '/profile-settings/account-center/personal-informations';
  static const String privacyPolicy =
      '/profile-settings/account-center/privacy-policy';
  static const String userProfile = '/user-profile';
  static const String editProfile = '/edit-profile';
  static const String recruiterEditProfile = '/recruiter-edit-profile';
  static const String sharePost = '/share-post';
  static const String languageSettings = '/language-settings';
  static const String accessibility = '/accessibility';
  static const String cvCameraCapture = '/cv-camera-capture';
  static const String cvProcessing = '/cv-processing';
  static const String cvReview = '/cv-review';

  // Route names (used with context.goNamed / pushNamed).
  static const String nSplash = 'splash';
  static const String nOnboarding = 'onboarding';
  static const String nLogin = 'login';
  static const String nForgotPasswordMethod = 'forgotPasswordMethod';
  static const String nForgotPasswordEmail = 'forgotPasswordEmail';
  static const String nForgotPasswordOtp = 'forgotPasswordOtp';
  static const String nSignup = 'signup';
  static const String nOtp = 'otp';
  static const String nChangePhone = 'changePhone';
  static const String nProfileSetup = 'profileSetup';
  static const String nFieldOfWork = 'fieldOfWork';
  static const String nHome = 'home';
  static const String nJobs = 'jobs';
  static const String nCall = 'call';
  static const String nVideoCall = 'videoCall';
  static const String nChats = 'chats';
  static const String nChatDetail = 'chatDetail';
  static const String nCreatePost = 'createPost';
  static const String nCreatePostMedia = 'createPostMedia';
  static const String nCreatePostPoll = 'createPostPoll';
  static const String nHelpCenter = 'helpCenter';
  static const String nHelpCenterDetail = 'helpCenterDetail';
  static const String nTestFeatures = 'testFeatures';
  static const String nNotifications = 'notifications';
  static const String nGames = 'games';
  static const String nGamesPlanifik = 'gamesPlanifik';
  static const String nGamesMoveFast = 'gamesMoveFast';
  static const String nGamesPredictivePuzzle = 'gamesPredictivePuzzle';
  static const String nGamesTaskScheduling = 'gamesTaskScheduling';
  static const String nGamesInvestigate = 'gamesInvestigate';
  static const String nProfileSettings = 'profileSettings';
  static const String nAccountCenter = 'accountCenter';
  static const String nPersonalInformations = 'personalInformations';
  static const String nPrivacyPolicy = 'privacyPolicy';
  static const String nUserProfile = 'userProfile';
  static const String nEditProfile = 'editProfile';
  static const String nRecruiterEditProfile = 'recruiterEditProfile';
  static const String nSharePost = 'sharePost';
  static const String nLanguageSettings = 'languageSettings';
  static const String nAccessibility = 'accessibility';
  static const String nCvCameraCapture = 'cvCameraCapture';
  static const String nCvProcessing = 'cvProcessing';
  static const String nCvReview = 'cvReview';
}
