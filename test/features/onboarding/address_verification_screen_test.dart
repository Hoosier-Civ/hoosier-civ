import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoosierciv/core/constants/app_constants.dart';
import 'package:hoosierciv/features/onboarding/address_verification_screen.dart';
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
        routerConfig: _routerFor(const AddressVerificationScreen()),
      ),
    );

void main() {
  late MockOnboardingCubit cubit;

  setUp(() {
    cubit = MockOnboardingCubit();
    when(() => cubit.state).thenReturn(const OnboardingInitial());
    when(() => cubit.submitZip(any())).thenAnswer((_) async {});
  });

  group('AddressVerificationScreen', () {
    testWidgets('renders ZIP input and Continue button', (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      expect(find.byType(TextFormField), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
    });

    testWidgets('shows inline validation for empty submission', (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();

      expect(find.text('Please enter a 5-digit ZIP code.'), findsOneWidget);
      verifyNever(() => cubit.submitZip(any()));
    });

    testWidgets('shows inline validation for short ZIP', (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      await tester.enterText(find.byType(TextFormField), '461');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();

      expect(find.text('Please enter a 5-digit ZIP code.'), findsOneWidget);
      verifyNever(() => cubit.submitZip(any()));
    });

    testWidgets('calls submitZip when 5-digit ZIP entered', (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      await tester.enterText(find.byType(TextFormField), '46204');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();

      verify(() => cubit.submitZip('46204')).called(1);
    });

    testWidgets('shows loading indicator when ZipLoading', (tester) async {
      when(() => cubit.state).thenReturn(const OnboardingZipLoading());

      await tester.pumpWidget(_wrap(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Continue button should be disabled
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('shows error message when OnboardingError', (tester) async {
      when(() => cubit.state).thenReturn(
        const OnboardingError('ZIP code is not in Indiana'),
      );

      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('ZIP code is not in Indiana'), findsOneWidget);
    });

    testWidgets('navigates to auth screen on OnboardingZipVerified',
        (tester) async {
      whenListen(
        cubit,
        Stream.fromIterable([
          const OnboardingZipLoading(),
          const OnboardingZipVerified(
            zipCode: '46204',
            districtId: 'ocd-division/country:us/state:in/sldu:1',
            officials: [],
          ),
        ]),
        initialState: const OnboardingInitial(),
      );

      await tester.pumpWidget(_wrap(cubit));
      await tester.pumpAndSettle();

      expect(find.text('AuthScreen'), findsOneWidget);
    });
  });
}
