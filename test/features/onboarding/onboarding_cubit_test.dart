import 'dart:async';
import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hoosierciv/core/services/auth_service.dart';
import 'package:hoosierciv/data/models/official_response.dart';
import 'package:hoosierciv/data/models/profile_model.dart';
import 'package:hoosierciv/data/repositories/district_repository.dart';
import 'package:hoosierciv/data/repositories/profile_repository.dart';
import 'package:hoosierciv/features/onboarding/onboarding_cubit.dart';
import 'package:hoosierciv/features/onboarding/onboarding_state.dart';
import 'package:hoosierciv/state/gamification_cubit.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- Mocks ---

class MockDistrictRepository extends Mock implements DistrictRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockGamificationCubit extends Mock implements GamificationCubit {}

class MockAuthService extends Mock implements AuthService {}

class MockUser extends Mock implements User {
  @override
  String get id => 'test-user-id';
}

class _FakeProfileModel extends Fake implements ProfileModel {}

// --- Fixtures ---

const _emptyOfficial = OfficialResponse(
  ciceroId: 1,
  firstName: 'Jane',
  lastName: 'Doe',
  chamber: 'senate',
  addresses: [],
  emailAddresses: [],
  identifiers: [],
  committees: [],
);

const _lookupResult = DistrictLookupResult(
  districtId: 'ocd-division/country:us/state:in/sldu:1',
  officials: [_emptyOfficial],
);

// --- Helpers ---

OnboardingCubit _makeCubit({
  MockDistrictRepository? districtRepo,
  MockProfileRepository? profileRepo,
  MockGamificationCubit? gamification,
  MockAuthService? auth,
  StreamController<AuthState>? authController,
}) {
  final controller = authController ?? StreamController<AuthState>.broadcast();
  final mockAuth = auth ?? MockAuthService();
  when(() => mockAuth.onAuthStateChange).thenAnswer((_) => controller.stream);

  return OnboardingCubit(
    districtRepository: districtRepo ?? MockDistrictRepository(),
    profileRepository: profileRepo ?? MockProfileRepository(),
    gamificationCubit: gamification ?? MockGamificationCubit(),
    authService: mockAuth,
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(OAuthProvider.google);
    registerFallbackValue(_FakeProfileModel());
  });

  group('submitZip', () {
    blocTest<OnboardingCubit, OnboardingState>(
      'emits OnboardingError for non-Indiana ZIP (starts with 45)',
      build: () => _makeCubit(),
      act: (cubit) => cubit.submitZip('45202'),
      expect: () => [
        isA<OnboardingError>().having(
          (e) => e.message,
          'message',
          contains('Indiana'),
        ),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'emits OnboardingError for ZIP shorter than 5 digits',
      build: () => _makeCubit(),
      act: (cubit) => cubit.submitZip('461'),
      expect: () => [isA<OnboardingError>()],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'emits [ZipLoading, ZipVerified] for valid Indiana ZIP starting with 46',
      build: () {
        final repo = MockDistrictRepository();
        when(() => repo.lookupDistrict('46204'))
            .thenAnswer((_) async => _lookupResult);
        return _makeCubit(districtRepo: repo);
      },
      act: (cubit) => cubit.submitZip('46204'),
      expect: () => [
        isA<OnboardingZipLoading>(),
        isA<OnboardingZipVerified>()
            .having((s) => s.zipCode, 'zipCode', '46204')
            .having(
              (s) => s.districtId,
              'districtId',
              _lookupResult.districtId,
            )
            .having((s) => s.officials, 'officials', _lookupResult.officials),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'emits [ZipLoading, ZipVerified] for valid Indiana ZIP starting with 47',
      build: () {
        final repo = MockDistrictRepository();
        when(() => repo.lookupDistrict('47401'))
            .thenAnswer((_) async => _lookupResult);
        return _makeCubit(districtRepo: repo);
      },
      act: (cubit) => cubit.submitZip('47401'),
      expect: () => [isA<OnboardingZipLoading>(), isA<OnboardingZipVerified>()],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'trims whitespace before validating',
      build: () {
        final repo = MockDistrictRepository();
        when(() => repo.lookupDistrict('46204'))
            .thenAnswer((_) async => _lookupResult);
        return _makeCubit(districtRepo: repo);
      },
      act: (cubit) => cubit.submitZip('  46204  '),
      expect: () => [isA<OnboardingZipLoading>(), isA<OnboardingZipVerified>()],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'emits OnboardingError when lookupDistrict throws',
      build: () {
        final repo = MockDistrictRepository();
        when(() => repo.lookupDistrict(any())).thenThrow(
          Exception('District not found'),
        );
        return _makeCubit(districtRepo: repo);
      },
      act: (cubit) => cubit.submitZip('46204'),
      expect: () => [
        isA<OnboardingZipLoading>(),
        isA<OnboardingError>().having(
          (e) => e.message,
          'message',
          'District not found',
        ),
      ],
    );
  });

  group('submitAuth', () {
    blocTest<OnboardingCubit, OnboardingState>(
      'does nothing when state is not OnboardingZipVerified',
      build: () => _makeCubit(),
      act: (cubit) => cubit.submitAuth(OAuthProvider.google),
      expect: () => [],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'emits OnboardingAuthPending and calls signInWithOAuth',
      build: () {
        final repo = MockDistrictRepository();
        when(() => repo.lookupDistrict('46204'))
            .thenAnswer((_) async => _lookupResult);

        final auth = MockAuthService();
        final controller = StreamController<AuthState>.broadcast();
        when(() => auth.onAuthStateChange).thenAnswer((_) => controller.stream);
        when(
          () =>
              auth.signInWithOAuth(any(), redirectTo: any(named: 'redirectTo')),
        ).thenAnswer((_) async {});

        return OnboardingCubit(
          districtRepository: repo,
          profileRepository: MockProfileRepository(),
          gamificationCubit: MockGamificationCubit(),
          authService: auth,
        );
      },
      act: (cubit) async {
        await cubit.submitZip('46204');
        await cubit.submitAuth(OAuthProvider.google);
      },
      expect: () => [
        isA<OnboardingZipLoading>(),
        isA<OnboardingZipVerified>(),
        isA<OnboardingAuthPending>()
            .having((s) => s.zipCode, 'zipCode', '46204')
            .having((s) => s.districtId, 'districtId', _lookupResult.districtId)
            .having(
              (s) => s.officials,
              'officials',
              _lookupResult.officials,
            ),
      ],
    );

    blocTest<OnboardingCubit, OnboardingState>(
      'emits OnboardingError when signInWithOAuth throws',
      build: () {
        final repo = MockDistrictRepository();
        when(() => repo.lookupDistrict('46204'))
            .thenAnswer((_) async => _lookupResult);

        final auth = MockAuthService();
        final controller = StreamController<AuthState>.broadcast();
        when(() => auth.onAuthStateChange).thenAnswer((_) => controller.stream);
        when(
          () =>
              auth.signInWithOAuth(any(), redirectTo: any(named: 'redirectTo')),
        ).thenThrow(Exception('OAuth failed'));

        return OnboardingCubit(
          districtRepository: repo,
          profileRepository: MockProfileRepository(),
          gamificationCubit: MockGamificationCubit(),
          authService: auth,
        );
      },
      act: (cubit) async {
        await cubit.submitZip('46204');
        await cubit.submitAuth(OAuthProvider.google);
      },
      expect: () => [
        isA<OnboardingZipLoading>(),
        isA<OnboardingZipVerified>(),
        isA<OnboardingAuthPending>(),
        isA<OnboardingError>()
            .having((e) => e.message, 'message', 'OAuth failed'),
      ],
    );
  });

  group('completeOnboarding (via auth state change)', () {
    late Directory hiveDir;

    setUp(() async {
      hiveDir = await Directory.systemTemp.createTemp('hive_test_');
      Hive.init(hiveDir.path);
    });

    tearDown(() async {
      await Hive.close();
      await hiveDir.delete(recursive: true);
    });

    blocTest<OnboardingCubit, OnboardingState>(
      'does nothing when state is not OnboardingAuthPending',
      build: () => _makeCubit(),
      act: (cubit) => cubit.completeOnboarding(),
      expect: () => [],
    );

    test('emits OnboardingComplete after signedIn event fires', () async {
      final authController = StreamController<AuthState>.broadcast();
      final auth = MockAuthService();
      when(() => auth.onAuthStateChange)
          .thenAnswer((_) => authController.stream);
      when(
        () => auth.signInWithOAuth(any(), redirectTo: any(named: 'redirectTo')),
      ).thenAnswer((_) async {});

      final mockUser = MockUser();
      when(() => auth.currentUser).thenReturn(mockUser);

      final profileRepo = MockProfileRepository();
      when(() => profileRepo.upsertProfile(any())).thenAnswer(
        (_) async => ProfileModel(
          id: 'test-user-id',
          xpTotal: 0,
          level: 1,
          streakCount: 0,
          interests: const [],
          onboardingCompleted: true,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      );

      final gamification = MockGamificationCubit();
      when(() => gamification.awardXp(any())).thenReturn(null);

      final districtRepo = MockDistrictRepository();
      when(() => districtRepo.lookupDistrict('46204'))
          .thenAnswer((_) async => _lookupResult);

      final cubit = OnboardingCubit(
        districtRepository: districtRepo,
        profileRepository: profileRepo,
        gamificationCubit: gamification,
        authService: auth,
      );

      final states = <OnboardingState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.submitZip('46204');
      await cubit.submitAuth(OAuthProvider.google);

      // Simulate the OAuth deep-link returning — fire the event and then
      // wait for the cubit to reach OnboardingComplete before asserting.
      final fakeSession = _FakeSession();

      final doneFuture = cubit.stream
          .firstWhere((s) => s is OnboardingComplete)
          .timeout(const Duration(seconds: 5));

      authController.add(AuthState(AuthChangeEvent.signedIn, fakeSession));

      await doneFuture;

      await sub.cancel();
      await cubit.close();
      await authController.close();

      expect(states.last, isA<OnboardingComplete>());
      verify(() => gamification.awardXp(5)).called(1);
    });

    test('emits OnboardingError when profile upsert fails', () async {
      final authController = StreamController<AuthState>.broadcast();
      final auth = MockAuthService();
      when(() => auth.onAuthStateChange)
          .thenAnswer((_) => authController.stream);
      when(
        () => auth.signInWithOAuth(any(), redirectTo: any(named: 'redirectTo')),
      ).thenAnswer((_) async {});

      final mockUser = MockUser();
      when(() => auth.currentUser).thenReturn(mockUser);

      final profileRepo = MockProfileRepository();
      when(() => profileRepo.upsertProfile(any())).thenThrow(
        Exception('DB error'),
      );

      final gamification = MockGamificationCubit();

      final districtRepo = MockDistrictRepository();
      when(() => districtRepo.lookupDistrict('46204'))
          .thenAnswer((_) async => _lookupResult);

      final cubit = OnboardingCubit(
        districtRepository: districtRepo,
        profileRepository: profileRepo,
        gamificationCubit: gamification,
        authService: auth,
      );

      final states = <OnboardingState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.submitZip('46204');
      await cubit.submitAuth(OAuthProvider.google);

      final fakeSession = _FakeSession();

      // Profile upsert throws synchronously so the error state arrives quickly;
      // still wait on the stream rather than a fixed delay.
      final doneFuture = cubit.stream
          .firstWhere((s) => s is OnboardingError)
          .timeout(const Duration(seconds: 5));

      authController.add(AuthState(AuthChangeEvent.signedIn, fakeSession));

      await doneFuture;

      await sub.cancel();
      await cubit.close();
      await authController.close();

      expect(states.last, isA<OnboardingError>());
      verifyNever(() => gamification.awardXp(any()));
    });
  });
}

// Minimal fake Session for constructing AuthState in tests.
class _FakeSession extends Fake implements Session {}
