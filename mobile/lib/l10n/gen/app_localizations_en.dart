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
  String get hiredCandidates => 'Hired candidates';

  @override
  String get plansAndPricing => 'Plans & Pricing';

  @override
  String get contrast => 'Contrast';

  @override
  String get textSize => 'Text Size';

  @override
  String get preview => 'Preview';

  @override
  String get accessibilityPreviewText =>
      'The application text adjusts based on your selected font size.';

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

  @override
  String get forgotPasswordTitle => 'Forgot Password';

  @override
  String get chooseResetMethod => 'How would you like to reset your password?';

  @override
  String get resetViaEmail => 'Reset via Email';

  @override
  String get resetViaEmailDesc =>
      'We\'ll send a verification code to your email address';

  @override
  String get resetViaSms => 'Reset via SMS';

  @override
  String get resetViaSmsDesc =>
      'We\'ll send a verification code to your phone number';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get enterYourEmail => 'Enter your email address';

  @override
  String get enterEmailDesc =>
      'We\'ll send a 6-digit verification code to your email address to reset your password.';

  @override
  String get sendCode => 'Send Code';

  @override
  String get otpVerificationTitle => 'Verify Code';

  @override
  String otpVerificationSubtitle(String email) {
    return 'Enter the 6-digit code sent to $email';
  }

  @override
  String get resendCode => 'Resend Code';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get resetPasswordBtn => 'Reset Password';

  @override
  String get passwordResetSuccess =>
      'Your password has been reset successfully!';

  @override
  String get backToLogin => 'Back to Login';

  @override
  String get updatePassword => 'Update Password';

  @override
  String get cancel => 'Cancel';

  @override
  String get passwordChangedSuccess => 'Password updated successfully!';

  @override
  String get currentPasswordHint => 'Current password';

  @override
  String get newPasswordHint => 'New password';

  @override
  String get confirmNewPasswordHint => 'Confirm new password';

  @override
  String get deleteAccountTitle => 'Delete Account';

  @override
  String get deleteAccountMessage =>
      'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.';

  @override
  String get yesDeleteAccount => 'Yes, Delete Account';

  @override
  String get accountDeleted => 'Your account has been deleted.';

  @override
  String get choosePhoto => 'Choose from Gallery';

  @override
  String get takePhoto => 'Take a Photo';

  @override
  String get removePhoto => 'Remove Photo';

  @override
  String get avatarUpdated => 'Profile photo updated!';

  @override
  String get avatarRemoved => 'Profile photo removed.';

  @override
  String get uploadCv => 'Upload CV';

  @override
  String get replaceCv => 'Replace CV';

  @override
  String get deleteCv => 'Delete CV';

  @override
  String get cvUploaded => 'CV uploaded successfully!';

  @override
  String get cvDeleted => 'CV deleted.';

  @override
  String get noCvUploaded => 'No CV uploaded yet';

  @override
  String get cvReviewTitle => 'Review Extracted Data';

  @override
  String get cvReviewNoData => 'No data available.';

  @override
  String get cvReviewBannerText =>
      'We found the following information in your CV. Please review and edit if necessary before saving to your profile.';

  @override
  String get cvReviewBasicInfo => 'Basic Info';

  @override
  String get cvReviewCurrentPosition => 'CURRENT POSITION';

  @override
  String get cvReviewCurrentPositionHint => 'E.g. Senior Software Engineer';

  @override
  String get cvReviewExperienceYears => 'EXPERIENCE (YEARS)';

  @override
  String get cvReviewExperienceYearsHint => 'E.g. 5';

  @override
  String get cvReviewAboutMe => 'ABOUT ME SUMMARY';

  @override
  String get cvReviewAboutMeHint => 'A brief summary about yourself...';

  @override
  String get cvReviewSkills => 'Skills';

  @override
  String get cvReviewExperience => 'Experience';

  @override
  String get cvReviewJobTitle => 'Job Title';

  @override
  String get cvReviewCompanyName => 'Company Name';

  @override
  String get cvReviewStartDate => 'Start Date';

  @override
  String get cvReviewEndDate => 'End Date';

  @override
  String get cvReviewPresent => 'Present';

  @override
  String get cvReviewEducation => 'Education';

  @override
  String get cvReviewDegree => 'Degree';

  @override
  String get cvReviewSchool => 'School / University';

  @override
  String get cvReviewStartYear => 'Start Year';

  @override
  String get cvReviewEndYear => 'End Year';

  @override
  String get cvReviewCertifications => 'Certifications';

  @override
  String get cvReviewCertificationTitle => 'Certification Title';

  @override
  String get cvReviewIssuer => 'Issuer';

  @override
  String get cvReviewSaveBtn => 'Save to Profile';

  @override
  String get cvReviewSaving => 'Saving to profile...';

  @override
  String get cvReviewSaveSuccess => 'Profile updated successfully!';

  @override
  String cvReviewSaveFailed(String error) {
    return 'Failed to save profile: $error';
  }

  @override
  String get acceptAction => 'Accept';

  @override
  String get actionFailed => 'Action failed.\nPlease try again.';

  @override
  String get add => 'Add';

  @override
  String get addAnOption => 'Add an option';

  @override
  String get aiResumeLabel => 'AI Resume';

  @override
  String get allChats => 'All chats';

  @override
  String get andTwoOthers => 'and 2 others';

  @override
  String get areYouSureLogOut => 'Are you sure you want to log out?';

  @override
  String get audioCall => 'Audio Call';

  @override
  String get block => 'Block';

  @override
  String get calling => 'Calling...';

  @override
  String get cameraOff => 'Camera Off';

  @override
  String get cameraOn => 'Camera On';

  @override
  String get closeLabel => 'Close';

  @override
  String get commentPlaceholder => 'Add a comment...';

  @override
  String commentsAndShares(String comments, String shares) {
    return '$comments Comments .\n$shares Shares';
  }

  @override
  String get commentsTitle => 'Comments';

  @override
  String get confirmOffer => 'Confirm offer';

  @override
  String get connected => 'Connected';

  @override
  String get conversationId => 'Conversation ID';

  @override
  String get customerService => '24/7 customer service';

  @override
  String get deleteLabel => 'Delete';

  @override
  String get discussionAssistant => 'Discussion assistant';

  @override
  String get discussionAssistantTyping => 'Discussion assistant is typing';

  @override
  String get documentLabel => 'Document';

  @override
  String get earpiece => 'Earpiece';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String effectApplied(String effect) {
    return 'Effect $effect applied!';
  }

  @override
  String get effects => 'effects';

  @override
  String get end => 'end';

  @override
  String errorLabel(String error) {
    return 'Error: $error';
  }

  @override
  String get errorText => 'Error';

  @override
  String get exploreOffer => 'Explore offer';

  @override
  String get filter1 => 'Filter 1';

  @override
  String get filter2 => 'Filter 2';

  @override
  String get filter3 => 'Filter 3';

  @override
  String get filterAll => 'All';

  @override
  String get filterJobOffers => 'Job Offers';

  @override
  String get filterProfessionals => 'Professionals';

  @override
  String get flip => 'flip';

  @override
  String get friendsVisibility => 'Friends';

  @override
  String get great => 'Great';

  @override
  String get hide => 'Hide';

  @override
  String get hiringContact => 'Hiring contact';

  @override
  String get iAppreciateYourService => 'I appreciate your service';

  @override
  String get identityVerificationDescription =>
      'The recruiter has requested an identity verification with face matching to ensure trust and security.';

  @override
  String get identityVerificationRequired => 'Identity verification required !';

  @override
  String get important => 'Important !';

  @override
  String get importantAlertDescription =>
      'The video interview will be automatically recorded for moderation purposes.\nDo not ask for a candidate\'s personal contact details.';

  @override
  String get jobOpportunity => 'Job Opportunity';

  @override
  String get justNow => 'Just now';

  @override
  String likedByAndOthers(String name, String others) {
    return 'Liked by $name & $others others';
  }

  @override
  String likedYourPost(String name) {
    return '$name liked your post';
  }

  @override
  String get mediaAdd => 'Add';

  @override
  String mediaAddCount(int count) {
    return 'Add ($count)';
  }

  @override
  String get mediaLabel => 'Media';

  @override
  String get mediaPermissionDenied =>
      'Photo library access is required to select media.';

  @override
  String get mediaRecents => 'Recents';

  @override
  String get mute => 'mute';

  @override
  String get myId => 'My ID (UUID)';

  @override
  String get newLike => 'New like';

  @override
  String get newProject => 'New Project';

  @override
  String get noChats => 'Aucun chat';

  @override
  String get noCommentsYet => 'No comments yet.';

  @override
  String get noMatchingOffers => 'No matching offers.';

  @override
  String get noNotifications => 'No notifications to show.';

  @override
  String get noPortfolioItems => 'No portfolio items yet';

  @override
  String get noPostsToShow => 'No posts to show.';

  @override
  String get ok => 'OK';

  @override
  String get oneVote => '1 vote';

  @override
  String optionIndex(int index) {
    return 'Option $index';
  }

  @override
  String optionsCount(int count) {
    return '$count options';
  }

  @override
  String get outputCard => 'Add your card';

  @override
  String get overview => 'Overview';

  @override
  String get perMonth => '/Mo.';

  @override
  String get poll => 'Poll';

  @override
  String get pollAttached => 'Poll attached';

  @override
  String get pollDisclaimer =>
      '* We do not allow requests related to political opinions, medical information, or other sensitive data.\nThis option is only intended for questions related to Progress Careers.';

  @override
  String get poor => 'Poor';

  @override
  String get portfolioLabel => 'Portfolio';

  @override
  String get postAction => 'Post';

  @override
  String get postCreationFailed =>
      'Unable to publish your post.\nPlease try again.';

  @override
  String get postHidden => 'Post hidden from your feed.';

  @override
  String get postLabel => 'Post';

  @override
  String get prepareYourId => 'Prepare your ID';

  @override
  String get profileLabel => 'Profile';

  @override
  String get publicVisibility => 'Public';

  @override
  String get publishLabel => 'Publish';

  @override
  String get rateYourExperience => 'Rate your experience';

  @override
  String get read => 'Read';

  @override
  String get recipientId => 'Recipient ID (UUID)';

  @override
  String get recruiter => 'Recruiter';

  @override
  String get rejectAction => 'Reject';

  @override
  String get rejectOffer => 'Reject offer';

  @override
  String get remoteLabel => 'Remote';

  @override
  String get report => 'Report';

  @override
  String get resumeAi => 'Resume AI';

  @override
  String get retry => 'Retry';

  @override
  String get scoreLabel => 'Score';

  @override
  String get send => 'Send';

  @override
  String get sendMessage => 'Send message...';

  @override
  String get sent => 'Sent';

  @override
  String get shareLabel => 'Share';

  @override
  String get showAll => 'Show all';

  @override
  String get showLabel => 'Show';

  @override
  String get softSkillsScore => 'SOFT SKILLS SCORE';

  @override
  String get speaker => 'Speaker';

  @override
  String get stayTuned => 'Stay tuned for new notifications.';

  @override
  String get tellUsMore => 'Tell us more';

  @override
  String get thankYouForYourOpinion => 'Thank you for your opinion';

  @override
  String get timeframe => 'Timeframe';

  @override
  String timeLeft(String duration) {
    return '$duration left';
  }

  @override
  String get today => 'Today';

  @override
  String get typeTheQuestion => 'Type the question';

  @override
  String get userBlocked =>
      'User blocked.\nTheir posts are hidden from your feed.';

  @override
  String get verifyNow => 'Verify now';

  @override
  String get videoCall => 'Video Call';

  @override
  String get videoOn => 'Video On';

  @override
  String voteCount(int count) {
    return '$count votes';
  }

  @override
  String get voted => 'Voted';

  @override
  String votesCount(int count) {
    return '$count votes';
  }

  @override
  String weAreOffering(String position) {
    return 'We are offering a $position position with a salary of ';
  }

  @override
  String get whatCanWeImprove => 'What can we improve?';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get yourComments => 'Your comments';

  @override
  String get yourQuestion => 'Your question';
}
