/// User-facing copy used across the maquette.
///
/// Kept centralized to make future localization (intl / arb) trivial.
class AppStrings {
  AppStrings._();

  static const String appName = 'ZENNYT';
  static const String appTagline = 'Careers';

  // --- Onboarding ---
  static const String onbWelcomeTitle = 'Welcome to Zennyt Careers !';
  static const String onbWelcomeBody =
      'Reveal your true professional potential.';
  static const String onbGamesBody =
      'Play cognitive games grounded in research and discover your strengths.';
  static const String onbSkillsBody =
      'Turn your performance into measurable insights that recruiters understand.';
  static const String onbOpportunitiesBody =
      'Get matched based on skills — not just a resume.';

  /// Highlighted brand phrase inside [onbWelcomeTitle] (rendered bold).
  static const String brandHighlight = 'Zennyt Careers';
  static const String next = 'Next';
  static const String getStarted = 'Get started';

  // --- Auth ---
  static const String loginTitle = 'Log in to your account';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String forgotPassword = 'Forgot Password?';
  static const String signIn = 'Sign In';
  static const String orContinueWith = 'Or continue with';
  static const String noAccount = "Don't have an account? ";
  static const String signUp = 'Sign up';
  static const String haveAccount = 'Already have an account? ';

  static const String createAccountTitle = 'Create your account';
  static const String firstName = 'First name';
  static const String lastName = 'Last name';
  static const String phone = 'Phone number';
  static const String phoneNumber = 'Phone Number';
  static const String emailHyphen = 'E-mail';
  static const String cityCountry = 'City / Country';
  static const String confirmPassword = 'Confirm password';
  static const String continueLabel = 'Continue';
  static const String confirm = 'Confirm';
  static const String acceptPrefix = 'I accept the ';
  static const String termsAndConditions = 'terms and conditions';

  static const String confirmationSmsTitle = 'Confirmation SMS';
  static const String confirmationSmsBody =
      'A confirmation code has been sent to your mobile number. Enter it to continue.';
  static const String invalidCode = 'Invalid code';
  static const String didntReceiveCode = "Didn't receive the code?";
  static const String resend = 'Resend';
  static const String changePhoneQuestion =
      'Would you like to receive the code on a different phone number?';
  static const String changePhoneNumber = 'Change phone number';
  static const String changePhoneTitle = 'Change phone number';

  // --- Profile setup ---
  static const String addInfoTitle = 'Add your informations';
  static const String roleRecruiter = 'Recruiter';
  static const String roleCandidate = 'Candidate';
  static const String roleStudent = 'Student';
  static const String uploadCv = 'Upload your CV';
  static const String fieldOfWork = 'Field of work';
  static const String lastPosition = 'Last position held';

  // Student fields
  static const String schoolName = 'School / University Name';
  static const String education = 'Education';
  static const String educationLevel = 'Education Level';

  // Candidate fields
  static const String universityName = 'University / Education';
  static const String degree = 'Degree';
  static const String masterDegree = 'Master degree';

  // Recruiter fields
  static const String jobTitle = 'Job Title';
  static const String companyName = 'Company Name';
  static const String companySize = 'Company Size';
  static const String companyLocation = 'Company Location';
  static const String companyRegistrationNumber =
      'Company Registration Number (EIN)';
  static const String uploadCompanyLogo = 'Upload your company logo';
  static const String fillRequiredFields =
      'Please fill in all required fields.';
  static const String takePhoto = 'Take a photo';
  static const String chooseFromGallery = 'Choose from gallery';
  static const String shuffleAvatar = 'Shuffle avatar';

  // --- Home ---
  static const String home = 'Home';
  static const String jobs = 'Jobs';
  static const String messages = 'Messages';
  static const String profile = 'Profile';

  // --- Home feed / bottom navigation ---
  static const String tabHome = 'Home';
  static const String tabFits = 'Fits';
  static const String tabProgress = 'Careers';
  static const String tabSearch = 'Search';
  static const String tabNotifications = 'Notifications';
  static const String newProject = 'New Project';
  static const String report = 'Report';
  static const String hide = 'Hide';
  static const String comments = 'Comments';
  static const String shares = 'Shares';
}
