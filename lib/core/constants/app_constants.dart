class AppConstants {
  // Routes
  static const String routeHome = '/home';
  static const String routeOnboarding = '/onboarding';
  static const String routeProfile = '/profile';
  static const String routeProfileBadges = '/profile/badges';

  // OAuth
  static const String oauthRedirectUrl = 'io.hoosierciv://login-callback';

  // XP values (mirrors HoosierCiv_XP_Badge_System.txt)
  static const int xpOnboardingComplete = 5;
  static const int xpCallLegislator = 20;
  static const int xpVoterRegistration = 10;
  static const int xpVoterStickerPhoto = 25;
  static const int xpBillTap = 5;
  static const int xpBillSummaryRead = 10;
  static const int xpBillQuiz = 15;

  // Level formula
  static const int xpPerLevel = 100;
  static const int maxLevel = 20;

  // Hive box names
  static const String hiveBoxMissions = 'missions';
  static const String hiveBoxBills = 'bills';
  static const String hiveBoxUser = 'user';

  // Hive keys
  static const String hiveKeyOnboardingComplete = 'onboarding_complete';

  // Cache TTLs
  static const Duration missionsCacheTtl = Duration(minutes: 15);
  static const Duration newsCacheTtl = Duration(minutes: 5);
}
