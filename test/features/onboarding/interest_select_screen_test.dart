import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoosierciv/core/constants/app_constants.dart';
import 'package:hoosierciv/features/onboarding/interest_select_screen.dart';
import 'package:hoosierciv/features/onboarding/onboarding_cubit.dart';
import 'package:hoosierciv/features/onboarding/onboarding_state.dart';
import 'package:mocktail/mocktail.dart';

class MockOnboardingCubit extends MockCubit<OnboardingState>
    implements OnboardingCubit {}

GoRouter _routerFor(Widget home) => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (_, __) => home),
        GoRoute(
          path: AppConstants.routeOnboardingAuth,
          builder: (_, __) => const Scaffold(body: Text('AuthScreen')),
        ),
      ],
    );

Widget _wrap(MockOnboardingCubit cubit) => BlocProvider<OnboardingCubit>.value(
      value: cubit,
      child: MaterialApp.router(
        routerConfig: _routerFor(const InterestSelectScreen()),
      ),
    );

void main() {
  late MockOnboardingCubit cubit;

  setUp(() {
    cubit = MockOnboardingCubit();
    when(() => cubit.state).thenReturn(const OnboardingInitial());
    when(() => cubit.selectInterests(any())).thenReturn(null);
  });

  group('InterestSelectScreen', () {
    testWidgets('renders four interest cards', (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('Voting'), findsOneWidget);
      expect(find.text('Legislation'), findsOneWidget);
      expect(find.text('Community'), findsOneWidget);
      expect(find.text('Education'), findsOneWidget);
    });

    testWidgets('Continue button is disabled when no card is selected',
        (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('Continue button is enabled after selecting one card',
        (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      await tester.tap(find.text('Voting'));
      await tester.pump();

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping a card toggles its selected state', (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      // Select Voting
      await tester.tap(find.text('Voting'));
      await tester.pump();

      ElevatedButton button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);

      // Deselect Voting — button should be disabled again
      await tester.tap(find.text('Voting'));
      await tester.pump();

      button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('multiple cards can be selected simultaneously', (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      await tester.tap(find.text('Voting'));
      await tester.pump();
      await tester.tap(find.text('Community'));
      await tester.pump();

      final button =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('tapping Continue calls selectInterests and navigates to auth',
        (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      await tester.tap(find.text('Voting'));
      await tester.pump();
      await tester.tap(find.text('Education'));
      await tester.pump();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      verify(
        () => cubit.selectInterests(
          any(
            that: containsAll(['voting', 'education']),
          ),
        ),
      ).called(1);
      expect(find.text('AuthScreen'), findsOneWidget);
    });
  });
}
