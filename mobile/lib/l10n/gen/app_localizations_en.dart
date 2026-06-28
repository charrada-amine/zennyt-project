// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'ZENNYT';

  @override
  String get appTagline => 'Careers';

  @override
  String get onbWelcomeTitle => 'Welcome to Zennyt Careers !';

  @override
  String get onbWelcomeBody => 'Reveal your true professional potential.';

  @override
  String get onbGamesBody =>
      'Play cognitive games grounded in research and discover your strengths.';

  @override
  String get onbSkillsBody =>
      'Turn your performance into measurable insights that recruiters understand.';

  @override
  String get onbOpportunitiesBody =>
      'Get matched based on skills — not just a resume.';

  @override
  String get next => 'Next';

  @override
  String get getStarted => 'Get started';

  @override
  String get loginTitle => 'Log in to your account';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get signIn => 'Sign In';

  @override
  String get orLogInWith => 'Or log in with';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithGitHub => 'Continue with GitHub';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUp => 'Sign up';

  @override
  String get haveAccount => 'Already have an account? ';

  @override
  String get createAccountTitle => 'Create your account';

  @override
  String get firstName => 'First name';

  @override
  String get lastName => 'Last name';

  @override
  String get emailHyphen => 'E-mail';

  @override
  String get phone => 'Phone number';

  @override
  String get cityCountry => 'City / Country';

  @override
  String get country => 'Country';

  @override
  String get city => 'City';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get continueLabel => 'Continue';

  @override
  String get acceptPrefix => 'I accept the ';

  @override
  String get termsAndConditions => 'terms and conditions';

  @override
  String fieldRequired(String field) {
    return '$field is required.';
  }

  @override
  String get emailRequired => 'Email is required.';

  @override
  String get emailInvalid => 'Enter a valid email address.';

  @override
  String get phoneRequired => 'Phone number is required.';

  @override
  String get phoneInvalid => 'Enter a valid phone number.';

  @override
  String get passwordRequired => 'Password is required.';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters.';

  @override
  String get confirmPasswordRequired => 'Please confirm your password.';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match.';

  @override
  String get cityCountryRequired => 'Please select your city / country.';

  @override
  String get countryRequired => 'Please select your country.';

  @override
  String get cityRequired => 'Please enter your city.';

  @override
  String get termsRequired => 'You must accept the terms and conditions.';

  @override
  String get incorrectPassword =>
      'Incorrect password. Try again or click \"Forgot your password\" to reset it.';

  @override
  String get connectionErrorTitle => 'Error connecting';

  @override
  String get connectionFailed => 'There is an error during your connection !';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get changeLanguage => 'Change language';

  @override
  String get language => 'Language';

  @override
  String get languageScreenHint => 'Choose the language used across the app.';

  @override
  String get profileAndSettings => 'Profile & Settings';

  @override
  String get seeYourProfile => 'See your profile';

  @override
  String get addYourCard => 'Add your card';

  @override
  String get inviteFriends => 'Invite Friends';

  @override
  String get referral => 'Referral';

  @override
  String get accountCenter => 'Account Center';

  @override
  String get notifications => 'Notifications';

  @override
  String get theme => 'Theme';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get helpCenter => 'Help Center';

  @override
  String get termsOfServiceAndConditions => 'Terms of Service & Conditions';

  @override
  String get logOut => 'Log out';

  @override
  String get profileUserName => 'Millie Brown';

  @override
  String get personalInformations => 'Personal informations';

  @override
  String get changePassword => 'Change Password';

  @override
  String get currentPassword => 'Current password';

  @override
  String lastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get securityMonitoring => 'Security monitoring';

  @override
  String get securityMonitoringDesc =>
      'To ensure a fair and secure assessment process, monitoring measures will be in place and are required to proceed.';

  @override
  String get viewPrivacyPolicy => 'View Privacy Policy';

  @override
  String get cookiesPreferences => 'Cookies preferences';

  @override
  String get necessaryCookies => 'Necessary Cookies';

  @override
  String get necessaryCookiesDesc =>
      'Required for core plateform functionality and security.';

  @override
  String get analyticsCookies => 'Analytics Cookies';

  @override
  String get analyticsCookiesDesc =>
      'Help us understand platform usage and improve performance.';

  @override
  String get marketingCookies => 'Marketing Cookies';

  @override
  String get marketingCookiesDesc =>
      'Used to measure campaign performance and deliver relevant ads';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get currentLocation => 'Current location';

  @override
  String get displayCurrentCity => 'Display your current city on your profile';

  @override
  String get saveChanges => 'Save changes';
}
