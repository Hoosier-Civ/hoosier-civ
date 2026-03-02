import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoosierciv/core/constants/app_constants.dart';
import 'package:hoosierciv/features/onboarding/onboarding_cubit.dart';
import 'package:hoosierciv/features/onboarding/onboarding_screen.dart';
import 'package:hoosierciv/features/onboarding/onboarding_state.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingCubit extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

/// Minimal router that captures navigations without needing a real app.
GoRouter _routerFor(Widget home) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        GoRoute(
          path: AppConstants.routeOnboardingAddress,
          builder: (_, __) => const Scaffold(body: Text('AddressScreen')),
        ),
      ],
    );

Widget _wrap(Widget screen, MockOnboardingCubit cubit) =>
    BlocProvider<OnboardingCubit>.value(
      value: cubit,
      child: MaterialApp.router(routerConfig: _routerFor(screen)),
    );

void main() {
  late MockOnboardingCubit cubit;

  setUp(() {
    cubit = MockOnboardingCubit();
    when(() => cubit.state).thenReturn(const OnboardingInitial());
  });

  group('OnboardingScreen', () {
    testWidgets('renders app name and value prop', (tester) async {
      await tester.pumpWidget(_wrap(const OnboardingScreen(), cubit));

      expect(find.text('HoosierCiv'), findsOneWidget);
      expect(
        find.text('Indiana civic engagement in your pocket.'),
        findsOneWidget,
      );
    });

    testWidgets("renders Let's Go button", (tester) async {
      await tester.pumpWidget(_wrap(const OnboardingScreen(), cubit));

      expect(find.widgetWithText(ElevatedButton, "Let's Go"), findsOneWidget);
    });

    testWidgets("Let's Go navigates to address screen", (tester) async {
      await tester.pumpWidget(_wrap(const OnboardingScreen(), cubit));

      await tester.tap(find.widgetWithText(ElevatedButton, "Let's Go"));
      await tester.pumpAndSettle();

      expect(find.text('AddressScreen'), findsOneWidget);
    });
  });
}
