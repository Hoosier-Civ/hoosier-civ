import 'package:go_router/go_router.dart';
import 'package:hoosierciv/core/constants/app_constants.dart';
import 'package:hoosierciv/features/bills/bill_detail_screen.dart';
import 'package:hoosierciv/features/home/home_screen.dart';
import 'package:hoosierciv/features/missions/mission_detail_screen.dart';
import 'package:hoosierciv/features/onboarding/onboarding_screen.dart';
import 'package:hoosierciv/features/profile/badges_screen.dart';
import 'package:hoosierciv/features/profile/profile_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.routeOnboarding,
    redirect: (context, state) {
      // Stub: always unauthenticated until UserCubit auth is wired in a later feature.
      final isOnboarding =
          state.matchedLocation == AppConstants.routeOnboarding;
      if (!isOnboarding) return AppConstants.routeOnboarding;
      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeOnboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppConstants.routeHome,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/missions/:id',
        builder: (context, state) =>
            MissionDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/bills/:id',
        builder: (context, state) =>
            BillDetailScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: AppConstants.routeProfile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProfileBadges,
        builder: (context, state) => const BadgesScreen(),
      ),
    ],
  );
}
