import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'ZENNYT'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In en, this message translates to:
  /// **'Careers'**
  String get appTagline;

  /// No description provided for @onbWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to Zennyt Careers !'**
  String get onbWelcomeTitle;

  /// No description provided for @onbWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Reveal your true professional potential.'**
  String get onbWelcomeBody;

  /// No description provided for @onbGamesBody.
  ///
  /// In en, this message translates to:
  /// **'Play cognitive games grounded in research and discover your strengths.'**
  String get onbGamesBody;

  /// No description provided for @onbSkillsBody.
  ///
  /// In en, this message translates to:
  /// **'Turn your performance into measurable insights that recruiters understand.'**
  String get onbSkillsBody;

  /// No description provided for @onbOpportunitiesBody.
  ///
  /// In en, this message translates to:
  /// **'Get matched based on skills — not just a resume.'**
  String get onbOpportunitiesBody;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @getStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get getStarted;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in to your account'**
  String get loginTitle;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// No description provided for @orLogInWith.
  ///
  /// In en, this message translates to:
  /// **'Or log in with'**
  String get orLogInWith;

  /// No description provided for @continueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// No description provided for @continueWithGitHub.
  ///
  /// In en, this message translates to:
  /// **'Continue with GitHub'**
  String get continueWithGitHub;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get haveAccount;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccountTitle;

  /// No description provided for @firstName.
  ///
  /// In en, this message translates to:
  /// **'First name'**
  String get firstName;

  /// No description provided for @lastName.
  ///
  /// In en, this message translates to:
  /// **'Last name'**
  String get lastName;

  /// No description provided for @emailHyphen.
  ///
  /// In en, this message translates to:
  /// **'E-mail'**
  String get emailHyphen;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phone;

  /// No description provided for @cityCountry.
  ///
  /// In en, this message translates to:
  /// **'City / Country'**
  String get cityCountry;

  /// No description provided for @country.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get country;

  /// No description provided for @city.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get city;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @acceptPrefix.
  ///
  /// In en, this message translates to:
  /// **'I accept the '**
  String get acceptPrefix;

  /// No description provided for @termsAndConditions.
  ///
  /// In en, this message translates to:
  /// **'terms and conditions'**
  String get termsAndConditions;

  /// Generic required-field validation message
  ///
  /// In en, this message translates to:
  /// **'{field} is required.'**
  String fieldRequired(String field);

  /// No description provided for @emailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required.'**
  String get emailRequired;

  /// No description provided for @emailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get emailInvalid;

  /// No description provided for @phoneRequired.
  ///
  /// In en, this message translates to:
  /// **'Phone number is required.'**
  String get phoneRequired;

  /// No description provided for @phoneInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get phoneInvalid;

  /// No description provided for @passwordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get passwordRequired;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters.'**
  String get passwordTooShort;

  /// No description provided for @confirmPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get confirmPasswordRequired;

  /// No description provided for @passwordsDoNotMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get passwordsDoNotMatch;

  /// No description provided for @cityCountryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select your city / country.'**
  String get cityCountryRequired;

  /// No description provided for @countryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please select your country.'**
  String get countryRequired;

  /// No description provided for @cityRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your city.'**
  String get cityRequired;

  /// No description provided for @termsRequired.
  ///
  /// In en, this message translates to:
  /// **'You must accept the terms and conditions.'**
  String get termsRequired;

  /// No description provided for @incorrectPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Try again or click \"Forgot your password\" to reset it.'**
  String get incorrectPassword;

  /// No description provided for @connectionErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Error connecting'**
  String get connectionErrorTitle;

  /// No description provided for @connectionFailed.
  ///
  /// In en, this message translates to:
  /// **'There is an error during your connection !'**
  String get connectionFailed;

  /// No description provided for @errorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorGeneric;

  /// No description provided for @changeLanguage.
  ///
  /// In en, this message translates to:
  /// **'Change language'**
  String get changeLanguage;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageScreenHint.
  ///
  /// In en, this message translates to:
  /// **'Choose the language used across the app.'**
  String get languageScreenHint;

  /// No description provided for @profileAndSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileAndSettings;

  /// No description provided for @seeYourProfile.
  ///
  /// In en, this message translates to:
  /// **'See your profile'**
  String get seeYourProfile;

  /// No description provided for @addYourCard.
  ///
  /// In en, this message translates to:
  /// **'Add your card'**
  String get addYourCard;

  /// No description provided for @inviteFriends.
  ///
  /// In en, this message translates to:
  /// **'Invite Friends'**
  String get inviteFriends;

  /// No description provided for @referral.
  ///
  /// In en, this message translates to:
  /// **'Referral'**
  String get referral;

  /// No description provided for @accountCenter.
  ///
  /// In en, this message translates to:
  /// **'Account Center'**
  String get accountCenter;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @accessibility.
  ///
  /// In en, this message translates to:
  /// **'Accessibility'**
  String get accessibility;

  /// No description provided for @helpCenter.
  ///
  /// In en, this message translates to:
  /// **'Help Center'**
  String get helpCenter;

  /// No description provided for @termsOfServiceAndConditions.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service & Conditions'**
  String get termsOfServiceAndConditions;

  /// No description provided for @hiredCandidates.
  ///
  /// In en, this message translates to:
  /// **'Hired candidates'**
  String get hiredCandidates;

  /// No description provided for @plansAndPricing.
  ///
  /// In en, this message translates to:
  /// **'Plans & Pricing'**
  String get plansAndPricing;

  /// No description provided for @contrast.
  ///
  /// In en, this message translates to:
  /// **'Contrast'**
  String get contrast;

  /// No description provided for @textSize.
  ///
  /// In en, this message translates to:
  /// **'Text Size'**
  String get textSize;

  /// No description provided for @preview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get preview;

  /// No description provided for @accessibilityPreviewText.
  ///
  /// In en, this message translates to:
  /// **'The application text adjusts based on your selected font size.'**
  String get accessibilityPreviewText;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @profileUserName.
  ///
  /// In en, this message translates to:
  /// **'Millie Brown'**
  String get profileUserName;

  /// No description provided for @personalInformations.
  ///
  /// In en, this message translates to:
  /// **'Personal informations'**
  String get personalInformations;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @lastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdated(String date);

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @securityMonitoring.
  ///
  /// In en, this message translates to:
  /// **'Security monitoring'**
  String get securityMonitoring;

  /// No description provided for @securityMonitoringDesc.
  ///
  /// In en, this message translates to:
  /// **'To ensure a fair and secure assessment process, monitoring measures will be in place and are required to proceed.'**
  String get securityMonitoringDesc;

  /// No description provided for @viewPrivacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'View Privacy Policy'**
  String get viewPrivacyPolicy;

  /// No description provided for @cookiesPreferences.
  ///
  /// In en, this message translates to:
  /// **'Cookies preferences'**
  String get cookiesPreferences;

  /// No description provided for @necessaryCookies.
  ///
  /// In en, this message translates to:
  /// **'Necessary Cookies'**
  String get necessaryCookies;

  /// No description provided for @necessaryCookiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Required for core plateform functionality and security.'**
  String get necessaryCookiesDesc;

  /// No description provided for @analyticsCookies.
  ///
  /// In en, this message translates to:
  /// **'Analytics Cookies'**
  String get analyticsCookies;

  /// No description provided for @analyticsCookiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Help us understand platform usage and improve performance.'**
  String get analyticsCookiesDesc;

  /// No description provided for @marketingCookies.
  ///
  /// In en, this message translates to:
  /// **'Marketing Cookies'**
  String get marketingCookies;

  /// No description provided for @marketingCookiesDesc.
  ///
  /// In en, this message translates to:
  /// **'Used to measure campaign performance and deliver relevant ads'**
  String get marketingCookiesDesc;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccount;

  /// No description provided for @currentLocation.
  ///
  /// In en, this message translates to:
  /// **'Current location'**
  String get currentLocation;

  /// No description provided for @displayCurrentCity.
  ///
  /// In en, this message translates to:
  /// **'Display your current city on your profile'**
  String get displayCurrentCity;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// No description provided for @chooseResetMethod.
  ///
  /// In en, this message translates to:
  /// **'How would you like to reset your password?'**
  String get chooseResetMethod;

  /// No description provided for @resetViaEmail.
  ///
  /// In en, this message translates to:
  /// **'Reset via Email'**
  String get resetViaEmail;

  /// No description provided for @resetViaEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code to your email address'**
  String get resetViaEmailDesc;

  /// No description provided for @resetViaSms.
  ///
  /// In en, this message translates to:
  /// **'Reset via SMS'**
  String get resetViaSms;

  /// No description provided for @resetViaSmsDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a verification code to your phone number'**
  String get resetViaSmsDesc;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// No description provided for @enterYourEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterYourEmail;

  /// No description provided for @enterEmailDesc.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a 6-digit verification code to your email address to reset your password.'**
  String get enterEmailDesc;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send Code'**
  String get sendCode;

  /// No description provided for @otpVerificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Code'**
  String get otpVerificationTitle;

  /// No description provided for @otpVerificationSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email}'**
  String otpVerificationSubtitle(String email);

  /// No description provided for @resendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @resetPasswordBtn.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPasswordBtn;

  /// No description provided for @passwordResetSuccess.
  ///
  /// In en, this message translates to:
  /// **'Your password has been reset successfully!'**
  String get passwordResetSuccess;

  /// No description provided for @backToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLogin;

  /// No description provided for @updatePassword.
  ///
  /// In en, this message translates to:
  /// **'Update Password'**
  String get updatePassword;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @passwordChangedSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated successfully!'**
  String get passwordChangedSuccess;

  /// No description provided for @currentPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordHint;

  /// No description provided for @newPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordHint;

  /// No description provided for @confirmNewPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPasswordHint;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.'**
  String get deleteAccountMessage;

  /// No description provided for @yesDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Yes, Delete Account'**
  String get yesDeleteAccount;

  /// No description provided for @accountDeleted.
  ///
  /// In en, this message translates to:
  /// **'Your account has been deleted.'**
  String get accountDeleted;

  /// No description provided for @choosePhoto.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get choosePhoto;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a Photo'**
  String get takePhoto;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove Photo'**
  String get removePhoto;

  /// No description provided for @avatarUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile photo updated!'**
  String get avatarUpdated;

  /// No description provided for @avatarRemoved.
  ///
  /// In en, this message translates to:
  /// **'Profile photo removed.'**
  String get avatarRemoved;

  /// No description provided for @uploadCv.
  ///
  /// In en, this message translates to:
  /// **'Upload CV'**
  String get uploadCv;

  /// No description provided for @replaceCv.
  ///
  /// In en, this message translates to:
  /// **'Replace CV'**
  String get replaceCv;

  /// No description provided for @deleteCv.
  ///
  /// In en, this message translates to:
  /// **'Delete CV'**
  String get deleteCv;

  /// No description provided for @cvUploaded.
  ///
  /// In en, this message translates to:
  /// **'CV uploaded successfully!'**
  String get cvUploaded;

  /// No description provided for @cvDeleted.
  ///
  /// In en, this message translates to:
  /// **'CV deleted.'**
  String get cvDeleted;

  /// No description provided for @noCvUploaded.
  ///
  /// In en, this message translates to:
  /// **'No CV uploaded yet'**
  String get noCvUploaded;

  /// No description provided for @cvReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review Extracted Data'**
  String get cvReviewTitle;

  /// No description provided for @cvReviewNoData.
  ///
  /// In en, this message translates to:
  /// **'No data available.'**
  String get cvReviewNoData;

  /// No description provided for @cvReviewBannerText.
  ///
  /// In en, this message translates to:
  /// **'We found the following information in your CV. Please review and edit if necessary before saving to your profile.'**
  String get cvReviewBannerText;

  /// No description provided for @cvReviewBasicInfo.
  ///
  /// In en, this message translates to:
  /// **'Basic Info'**
  String get cvReviewBasicInfo;

  /// No description provided for @cvReviewCurrentPosition.
  ///
  /// In en, this message translates to:
  /// **'CURRENT POSITION'**
  String get cvReviewCurrentPosition;

  /// No description provided for @cvReviewCurrentPositionHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. Senior Software Engineer'**
  String get cvReviewCurrentPositionHint;

  /// No description provided for @cvReviewExperienceYears.
  ///
  /// In en, this message translates to:
  /// **'EXPERIENCE (YEARS)'**
  String get cvReviewExperienceYears;

  /// No description provided for @cvReviewExperienceYearsHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. 5'**
  String get cvReviewExperienceYearsHint;

  /// No description provided for @cvReviewAboutMe.
  ///
  /// In en, this message translates to:
  /// **'ABOUT ME SUMMARY'**
  String get cvReviewAboutMe;

  /// No description provided for @cvReviewAboutMeHint.
  ///
  /// In en, this message translates to:
  /// **'A brief summary about yourself...'**
  String get cvReviewAboutMeHint;

  /// No description provided for @cvReviewSkills.
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get cvReviewSkills;

  /// No description provided for @cvReviewExperience.
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get cvReviewExperience;

  /// No description provided for @cvReviewJobTitle.
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get cvReviewJobTitle;

  /// No description provided for @cvReviewCompanyName.
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get cvReviewCompanyName;

  /// No description provided for @cvReviewStartDate.
  ///
  /// In en, this message translates to:
  /// **'Start Date'**
  String get cvReviewStartDate;

  /// No description provided for @cvReviewEndDate.
  ///
  /// In en, this message translates to:
  /// **'End Date'**
  String get cvReviewEndDate;

  /// No description provided for @cvReviewPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get cvReviewPresent;

  /// No description provided for @cvReviewEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get cvReviewEducation;

  /// No description provided for @cvReviewDegree.
  ///
  /// In en, this message translates to:
  /// **'Degree'**
  String get cvReviewDegree;

  /// No description provided for @cvReviewSchool.
  ///
  /// In en, this message translates to:
  /// **'School / University'**
  String get cvReviewSchool;

  /// No description provided for @cvReviewStartYear.
  ///
  /// In en, this message translates to:
  /// **'Start Year'**
  String get cvReviewStartYear;

  /// No description provided for @cvReviewEndYear.
  ///
  /// In en, this message translates to:
  /// **'End Year'**
  String get cvReviewEndYear;

  /// No description provided for @cvReviewCertifications.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get cvReviewCertifications;

  /// No description provided for @cvReviewCertificationTitle.
  ///
  /// In en, this message translates to:
  /// **'Certification Title'**
  String get cvReviewCertificationTitle;

  /// No description provided for @cvReviewIssuer.
  ///
  /// In en, this message translates to:
  /// **'Issuer'**
  String get cvReviewIssuer;

  /// No description provided for @cvReviewSaveBtn.
  ///
  /// In en, this message translates to:
  /// **'Save to Profile'**
  String get cvReviewSaveBtn;

  /// No description provided for @cvReviewSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving to profile...'**
  String get cvReviewSaving;

  /// No description provided for @cvReviewSaveSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully!'**
  String get cvReviewSaveSuccess;

  /// No description provided for @cvReviewSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to save profile: {error}'**
  String cvReviewSaveFailed(String error);

  /// No description provided for @acceptAction.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptAction;

  /// No description provided for @actionFailed.
  ///
  /// In en, this message translates to:
  /// **'Action failed.\nPlease try again.'**
  String get actionFailed;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @addAnOption.
  ///
  /// In en, this message translates to:
  /// **'Add an option'**
  String get addAnOption;

  /// No description provided for @aiResumeLabel.
  ///
  /// In en, this message translates to:
  /// **'AI Resume'**
  String get aiResumeLabel;

  /// No description provided for @allChats.
  ///
  /// In en, this message translates to:
  /// **'All chats'**
  String get allChats;

  /// No description provided for @andTwoOthers.
  ///
  /// In en, this message translates to:
  /// **'and 2 others'**
  String get andTwoOthers;

  /// No description provided for @areYouSureLogOut.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out?'**
  String get areYouSureLogOut;

  /// No description provided for @audioCall.
  ///
  /// In en, this message translates to:
  /// **'Audio Call'**
  String get audioCall;

  /// No description provided for @block.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// No description provided for @calling.
  ///
  /// In en, this message translates to:
  /// **'Calling...'**
  String get calling;

  /// No description provided for @cameraOff.
  ///
  /// In en, this message translates to:
  /// **'Camera Off'**
  String get cameraOff;

  /// No description provided for @cameraOn.
  ///
  /// In en, this message translates to:
  /// **'Camera On'**
  String get cameraOn;

  /// No description provided for @closeLabel.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get closeLabel;

  /// No description provided for @commentPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Add a comment...'**
  String get commentPlaceholder;

  /// No description provided for @commentsAndShares.
  ///
  /// In en, this message translates to:
  /// **'{comments} Comments .\n{shares} Shares'**
  String commentsAndShares(String comments, String shares);

  /// No description provided for @commentsTitle.
  ///
  /// In en, this message translates to:
  /// **'Comments'**
  String get commentsTitle;

  /// No description provided for @confirmOffer.
  ///
  /// In en, this message translates to:
  /// **'Confirm offer'**
  String get confirmOffer;

  /// No description provided for @connected.
  ///
  /// In en, this message translates to:
  /// **'Connected'**
  String get connected;

  /// No description provided for @conversationId.
  ///
  /// In en, this message translates to:
  /// **'Conversation ID'**
  String get conversationId;

  /// No description provided for @customerService.
  ///
  /// In en, this message translates to:
  /// **'24/7 customer service'**
  String get customerService;

  /// No description provided for @deleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteLabel;

  /// No description provided for @discussionAssistant.
  ///
  /// In en, this message translates to:
  /// **'Discussion assistant'**
  String get discussionAssistant;

  /// No description provided for @discussionAssistantTyping.
  ///
  /// In en, this message translates to:
  /// **'Discussion assistant is typing'**
  String get discussionAssistantTyping;

  /// No description provided for @documentLabel.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get documentLabel;

  /// No description provided for @earpiece.
  ///
  /// In en, this message translates to:
  /// **'Earpiece'**
  String get earpiece;

  /// No description provided for @editProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// No description provided for @effectApplied.
  ///
  /// In en, this message translates to:
  /// **'Effect {effect} applied!'**
  String effectApplied(String effect);

  /// No description provided for @effects.
  ///
  /// In en, this message translates to:
  /// **'effects'**
  String get effects;

  /// No description provided for @end.
  ///
  /// In en, this message translates to:
  /// **'end'**
  String get end;

  /// No description provided for @errorLabel.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorLabel(String error);

  /// No description provided for @errorText.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get errorText;

  /// No description provided for @exploreOffer.
  ///
  /// In en, this message translates to:
  /// **'Explore offer'**
  String get exploreOffer;

  /// No description provided for @filter1.
  ///
  /// In en, this message translates to:
  /// **'Filter 1'**
  String get filter1;

  /// No description provided for @filter2.
  ///
  /// In en, this message translates to:
  /// **'Filter 2'**
  String get filter2;

  /// No description provided for @filter3.
  ///
  /// In en, this message translates to:
  /// **'Filter 3'**
  String get filter3;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @filterJobOffers.
  ///
  /// In en, this message translates to:
  /// **'Job Offers'**
  String get filterJobOffers;

  /// No description provided for @filterProfessionals.
  ///
  /// In en, this message translates to:
  /// **'Professionals'**
  String get filterProfessionals;

  /// No description provided for @flip.
  ///
  /// In en, this message translates to:
  /// **'flip'**
  String get flip;

  /// No description provided for @friendsVisibility.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsVisibility;

  /// No description provided for @great.
  ///
  /// In en, this message translates to:
  /// **'Great'**
  String get great;

  /// No description provided for @hide.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get hide;

  /// No description provided for @hiringContact.
  ///
  /// In en, this message translates to:
  /// **'Hiring contact'**
  String get hiringContact;

  /// No description provided for @iAppreciateYourService.
  ///
  /// In en, this message translates to:
  /// **'I appreciate your service'**
  String get iAppreciateYourService;

  /// No description provided for @identityVerificationDescription.
  ///
  /// In en, this message translates to:
  /// **'The recruiter has requested an identity verification with face matching to ensure trust and security.'**
  String get identityVerificationDescription;

  /// No description provided for @identityVerificationRequired.
  ///
  /// In en, this message translates to:
  /// **'Identity verification required !'**
  String get identityVerificationRequired;

  /// No description provided for @important.
  ///
  /// In en, this message translates to:
  /// **'Important !'**
  String get important;

  /// No description provided for @importantAlertDescription.
  ///
  /// In en, this message translates to:
  /// **'The video interview will be automatically recorded for moderation purposes.\nDo not ask for a candidate\'s personal contact details.'**
  String get importantAlertDescription;

  /// No description provided for @jobOpportunity.
  ///
  /// In en, this message translates to:
  /// **'Job Opportunity'**
  String get jobOpportunity;

  /// No description provided for @justNow.
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get justNow;

  /// No description provided for @timeAgoMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{minute} other{minutes}} ago'**
  String timeAgoMinutes(int count);

  /// No description provided for @timeAgoHours.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{hour} other{hours}} ago'**
  String timeAgoHours(int count);

  /// No description provided for @timeAgoDays.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{day} other{days}} ago'**
  String timeAgoDays(int count);

  /// No description provided for @timeAgoMonths.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{month} other{months}} ago'**
  String timeAgoMonths(int count);

  /// No description provided for @timeAgoYears.
  ///
  /// In en, this message translates to:
  /// **'{count} {count, plural, =1{year} other{years}} ago'**
  String timeAgoYears(int count);

  /// No description provided for @likedByAndOthers.
  ///
  /// In en, this message translates to:
  /// **'Liked by {name} & {others} others'**
  String likedByAndOthers(String name, String others);

  /// No description provided for @likedYourPost.
  ///
  /// In en, this message translates to:
  /// **'{name} liked your post'**
  String likedYourPost(String name);

  /// No description provided for @mediaAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get mediaAdd;

  /// No description provided for @mediaAddCount.
  ///
  /// In en, this message translates to:
  /// **'Add ({count})'**
  String mediaAddCount(int count);

  /// No description provided for @mediaLabel.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get mediaLabel;

  /// No description provided for @mediaPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Photo library access is required to select media.'**
  String get mediaPermissionDenied;

  /// No description provided for @mediaRecents.
  ///
  /// In en, this message translates to:
  /// **'Recents'**
  String get mediaRecents;

  /// No description provided for @mute.
  ///
  /// In en, this message translates to:
  /// **'mute'**
  String get mute;

  /// No description provided for @myId.
  ///
  /// In en, this message translates to:
  /// **'My ID (UUID)'**
  String get myId;

  /// No description provided for @newLike.
  ///
  /// In en, this message translates to:
  /// **'New like'**
  String get newLike;

  /// No description provided for @newProject.
  ///
  /// In en, this message translates to:
  /// **'New Project'**
  String get newProject;

  /// No description provided for @noChats.
  ///
  /// In en, this message translates to:
  /// **'Aucun chat'**
  String get noChats;

  /// No description provided for @noCommentsYet.
  ///
  /// In en, this message translates to:
  /// **'No comments yet.'**
  String get noCommentsYet;

  /// No description provided for @noMatchingOffers.
  ///
  /// In en, this message translates to:
  /// **'No matching offers.'**
  String get noMatchingOffers;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications to show.'**
  String get noNotifications;

  /// No description provided for @noPortfolioItems.
  ///
  /// In en, this message translates to:
  /// **'No portfolio items yet'**
  String get noPortfolioItems;

  /// No description provided for @noPostsToShow.
  ///
  /// In en, this message translates to:
  /// **'No posts to show.'**
  String get noPostsToShow;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @oneVote.
  ///
  /// In en, this message translates to:
  /// **'1 vote'**
  String get oneVote;

  /// No description provided for @optionIndex.
  ///
  /// In en, this message translates to:
  /// **'Option {index}'**
  String optionIndex(int index);

  /// No description provided for @optionsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} options'**
  String optionsCount(int count);

  /// No description provided for @outputCard.
  ///
  /// In en, this message translates to:
  /// **'Add your card'**
  String get outputCard;

  /// No description provided for @overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get overview;

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'/Mo.'**
  String get perMonth;

  /// No description provided for @poll.
  ///
  /// In en, this message translates to:
  /// **'Poll'**
  String get poll;

  /// No description provided for @pollAttached.
  ///
  /// In en, this message translates to:
  /// **'Poll attached'**
  String get pollAttached;

  /// No description provided for @pollDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'* We do not allow requests related to political opinions, medical information, or other sensitive data.\nThis option is only intended for questions related to Progress Careers.'**
  String get pollDisclaimer;

  /// No description provided for @poor.
  ///
  /// In en, this message translates to:
  /// **'Poor'**
  String get poor;

  /// No description provided for @portfolioLabel.
  ///
  /// In en, this message translates to:
  /// **'Portfolio'**
  String get portfolioLabel;

  /// No description provided for @postAction.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postAction;

  /// No description provided for @postCreationFailed.
  ///
  /// In en, this message translates to:
  /// **'Unable to publish your post.\nPlease try again.'**
  String get postCreationFailed;

  /// No description provided for @postHidden.
  ///
  /// In en, this message translates to:
  /// **'Post hidden from your feed.'**
  String get postHidden;

  /// No description provided for @postLabel.
  ///
  /// In en, this message translates to:
  /// **'Post'**
  String get postLabel;

  /// No description provided for @prepareYourId.
  ///
  /// In en, this message translates to:
  /// **'Prepare your ID'**
  String get prepareYourId;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @publicVisibility.
  ///
  /// In en, this message translates to:
  /// **'Public'**
  String get publicVisibility;

  /// No description provided for @publishLabel.
  ///
  /// In en, this message translates to:
  /// **'Publish'**
  String get publishLabel;

  /// No description provided for @rateYourExperience.
  ///
  /// In en, this message translates to:
  /// **'Rate your experience'**
  String get rateYourExperience;

  /// No description provided for @read.
  ///
  /// In en, this message translates to:
  /// **'Read'**
  String get read;

  /// No description provided for @recipientId.
  ///
  /// In en, this message translates to:
  /// **'Recipient ID (UUID)'**
  String get recipientId;

  /// No description provided for @recruiter.
  ///
  /// In en, this message translates to:
  /// **'Recruiter'**
  String get recruiter;

  /// No description provided for @rejectAction.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectAction;

  /// No description provided for @rejectOffer.
  ///
  /// In en, this message translates to:
  /// **'Reject offer'**
  String get rejectOffer;

  /// No description provided for @remoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get remoteLabel;

  /// No description provided for @report.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// No description provided for @resumeAi.
  ///
  /// In en, this message translates to:
  /// **'Resume AI'**
  String get resumeAi;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get scoreLabel;

  /// No description provided for @send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message...'**
  String get sendMessage;

  /// No description provided for @sent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get sent;

  /// No description provided for @shareLabel.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareLabel;

  /// No description provided for @showAll.
  ///
  /// In en, this message translates to:
  /// **'Show all'**
  String get showAll;

  /// No description provided for @showLabel.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get showLabel;

  /// No description provided for @softSkillsScore.
  ///
  /// In en, this message translates to:
  /// **'SOFT SKILLS SCORE'**
  String get softSkillsScore;

  /// No description provided for @speaker.
  ///
  /// In en, this message translates to:
  /// **'Speaker'**
  String get speaker;

  /// No description provided for @stayTuned.
  ///
  /// In en, this message translates to:
  /// **'Stay tuned for new notifications.'**
  String get stayTuned;

  /// No description provided for @tellUsMore.
  ///
  /// In en, this message translates to:
  /// **'Tell us more'**
  String get tellUsMore;

  /// No description provided for @thankYouForYourOpinion.
  ///
  /// In en, this message translates to:
  /// **'Thank you for your opinion'**
  String get thankYouForYourOpinion;

  /// No description provided for @timeframe.
  ///
  /// In en, this message translates to:
  /// **'Timeframe'**
  String get timeframe;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{duration} left'**
  String timeLeft(String duration);

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @typeTheQuestion.
  ///
  /// In en, this message translates to:
  /// **'Type the question'**
  String get typeTheQuestion;

  /// No description provided for @userBlocked.
  ///
  /// In en, this message translates to:
  /// **'User blocked.\nTheir posts are hidden from your feed.'**
  String get userBlocked;

  /// No description provided for @verifyNow.
  ///
  /// In en, this message translates to:
  /// **'Verify now'**
  String get verifyNow;

  /// No description provided for @videoCall.
  ///
  /// In en, this message translates to:
  /// **'Video Call'**
  String get videoCall;

  /// No description provided for @videoOn.
  ///
  /// In en, this message translates to:
  /// **'Video On'**
  String get videoOn;

  /// No description provided for @voteCount.
  ///
  /// In en, this message translates to:
  /// **'{count} votes'**
  String voteCount(int count);

  /// No description provided for @voted.
  ///
  /// In en, this message translates to:
  /// **'Voted'**
  String get voted;

  /// No description provided for @votesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} votes'**
  String votesCount(int count);

  /// No description provided for @weAreOffering.
  ///
  /// In en, this message translates to:
  /// **'We are offering a {position} position with a salary of '**
  String weAreOffering(String position);

  /// No description provided for @whatCanWeImprove.
  ///
  /// In en, this message translates to:
  /// **'What can we improve?'**
  String get whatCanWeImprove;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @yourComments.
  ///
  /// In en, this message translates to:
  /// **'Your comments'**
  String get yourComments;

  /// No description provided for @yourQuestion.
  ///
  /// In en, this message translates to:
  /// **'Your question'**
  String get yourQuestion;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
