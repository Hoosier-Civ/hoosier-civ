import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hoosierciv/core/constants/app_constants.dart';
import 'package:hoosierciv/data/models/official_response.dart';
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
          path: AppConstants.routeHome,
          builder: (_, __) => const Scaffold(body: Text('HomeScreen')),
        ),
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

// Helpers ────────────────────────────────────────────────────────────────────

OfficialResponse _official(String chamber) => OfficialResponse(
      ciceroId: 1,
      firstName: 'Jane',
      lastName: 'Doe',
      chamber: chamber,
      addresses: const [],
      emailAddresses: const [],
      identifiers: const [],
      committees: const [],
    );

const _address = '123 E Washington St';
const _zip = '46204';

const _verifiedState = OnboardingZipVerified(
  zipCode: _zip,
  city: 'Indianapolis',
  districtId: 'ocd-division/country:us/state:in/sldu:1',
  officials: [],
);

// ────────────────────────────────────────────────────────────────────────────

void main() {
  late MockOnboardingCubit cubit;

  setUp(() {
    cubit = MockOnboardingCubit();
    when(() => cubit.state).thenReturn(const OnboardingInitial());
    when(() => cubit.submitAddress(any(), address: any(named: 'address')))
        .thenAnswer((_) async {});
  });

  group('AddressVerificationScreen — address form', () {
    testWidgets('renders ZIP input, address input, and Continue button',
        (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(ElevatedButton, 'Continue'), findsOneWidget);
    });

    testWidgets('shows ZIP validation error when submitted without a ZIP',
        (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();

      expect(find.text('Please enter a 5-digit ZIP code.'), findsOneWidget);
      verifyNever(
          () => cubit.submitAddress(any(), address: any(named: 'address')));
    });

    testWidgets('shows ZIP validation error for partial ZIP', (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'ZIP Code'), '461');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();

      expect(find.text('Please enter a 5-digit ZIP code.'), findsOneWidget);
      verifyNever(
          () => cubit.submitAddress(any(), address: any(named: 'address')));
    });

    testWidgets('calls submitAddress with only zip when address field is empty',
        (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'ZIP Code'), _zip);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();

      verify(() => cubit.submitAddress(_zip, address: null)).called(1);
    });

    testWidgets('calls submitAddress with zip and address when both provided',
        (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'ZIP Code'), _zip);
      await tester.enterText(
          find.widgetWithText(
              TextFormField, 'Street Address (optional — improves accuracy)'),
          _address);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pump();

      verify(() => cubit.submitAddress(_zip, address: _address)).called(1);
    });

    testWidgets('shows loading indicator when ZipLoading', (tester) async {
      when(() => cubit.state).thenReturn(const OnboardingZipLoading());

      await tester.pumpWidget(_wrap(cubit));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('shows error message when OnboardingError', (tester) async {
      when(() => cubit.state).thenReturn(
        const OnboardingError('Address is not in Indiana'),
      );

      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('Address is not in Indiana'), findsOneWidget);
    });
  });

  group('AddressVerificationScreen — district summary', () {
    testWidgets('shows verified ZIP and total official count', (tester) async {
      when(() => cubit.state).thenReturn(
        OnboardingZipVerified(
          zipCode: '46204',
          city: 'Indianapolis',
          districtId: 'ocd-division/country:us/state:in/sldu:1',
          officials: [
            _official('us_senate'),
            _official('us_house'),
            _official('senate'),
          ],
        ),
      );

      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('Indianapolis, IN'), findsOneWidget);
      expect(find.text('3 officials found in public records'), findsOneWidget);
    });

    testWidgets('shows federal, state, and local rows', (tester) async {
      when(() => cubit.state).thenReturn(
        OnboardingZipVerified(
          zipCode: '46204',
          city: 'Indianapolis',
          districtId: 'ocd-division/country:us/state:in/sldu:1',
          officials: [
            _official('us_senate'),
            _official('us_senate'),
            _official('us_house'),
            _official('senate'),
            _official('house'),
            _official('local'),
            _official('local_exec'),
          ],
        ),
      );

      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('Federal'), findsOneWidget);
      expect(find.text('3 officials'), findsOneWidget);
      expect(find.text('State'), findsOneWidget);
      expect(find.text('Local'), findsOneWidget);
      // State and Local both have 2 officials
      expect(find.text('2 officials'), findsNWidgets(2));
    });

    testWidgets('hides rows for missing chamber groups', (tester) async {
      when(() => cubit.state).thenReturn(_verifiedState);

      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('Federal'), findsNothing);
      expect(find.text('State'), findsNothing);
      expect(find.text('Local'), findsNothing);
    });

    testWidgets('singularises "official" when count is 1', (tester) async {
      when(() => cubit.state).thenReturn(
        OnboardingZipVerified(
          zipCode: '46204',
          city: 'Indianapolis',
          districtId: 'ocd-division/country:us/state:in/sldu:1',
          officials: [_official('us_senate')],
        ),
      );

      await tester.pumpWidget(_wrap(cubit));

      expect(find.text('1 official'), findsOneWidget);
    });

    testWidgets('Continue button navigates to home screen', (tester) async {
      when(() => cubit.state).thenReturn(_verifiedState);

      await tester.pumpWidget(_wrap(cubit));
      await tester.tap(find.widgetWithText(ElevatedButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('HomeScreen'), findsOneWidget);
    });

    testWidgets('tapping a row expands to show official name and title',
        (tester) async {
      when(() => cubit.state).thenReturn(
        const OnboardingZipVerified(
          zipCode: '46204',
          city: 'Indianapolis',
          districtId: 'ocd-division/country:us/state:in/sldu:1',
          officials: [
            OfficialResponse(
              ciceroId: 42,
              firstName: 'Jane',
              lastName: 'Doe',
              chamber: 'house',
              officeTitle: 'State Representative',
              addresses: [],
              emailAddresses: [],
              identifiers: [],
              committees: [],
            ),
          ],
        ),
      );

      await tester.pumpWidget(_wrap(cubit));

      // Name and title hidden before expanding
      expect(find.text('Jane Doe'), findsNothing);
      expect(find.text('State Representative'), findsNothing);

      await tester.tap(find.text('State'));
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('State Representative'), findsOneWidget);
    });

    testWidgets('Wrong ZIP button calls cubit.reset()', (tester) async {
      when(() => cubit.state).thenReturn(_verifiedState);
      when(() => cubit.reset()).thenReturn(null);

      await tester.pumpWidget(_wrap(cubit));
      await tester.tap(find.widgetWithText(TextButton, 'Wrong address? Change it'));
      await tester.pump();

      verify(() => cubit.reset()).called(1);
    });
  });
}
