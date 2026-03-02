import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hoosierciv/core/constants/app_constants.dart';
import 'package:hoosierciv/core/services/auth_service.dart';
import 'package:hoosierciv/data/models/profile_model.dart';
import 'package:hoosierciv/data/repositories/district_repository.dart';
import 'package:hoosierciv/data/repositories/profile_repository.dart';
import 'package:hoosierciv/features/onboarding/onboarding_state.dart';
import 'package:hoosierciv/state/gamification_cubit.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  final DistrictRepository _districtRepository;
  final ProfileRepository _profileRepository;
  final GamificationCubit _gamificationCubit;
  final AuthService _authService;

  late final StreamSubscription<AuthState> _authSubscription;

  OnboardingCubit({
    required DistrictRepository districtRepository,
    required ProfileRepository profileRepository,
    required GamificationCubit gamificationCubit,
    required AuthService authService,
  })  : _districtRepository = districtRepository,
        _profileRepository = profileRepository,
        _gamificationCubit = gamificationCubit,
        _authService = authService,
        super(const OnboardingInitial()) {
    _authSubscription =
        _authService.onAuthStateChange.listen(_onAuthStateChange);
  }

  void _onAuthStateChange(AuthState authState) {
    if (authState.event == AuthChangeEvent.signedIn &&
        state is OnboardingAuthPending) {
      completeOnboarding();
    }
  }

  /// Calls the lookup-district Edge Function with the user's ZIP code.
  ///
  /// Optionally accepts a street address for additional geocoding accuracy.
  /// Indiana validation is handled server-side via Cicero's match_region check.
  Future<void> submitAddress(String zip, {String? address}) async {
    final trimmedZip = zip.trim();

    if (trimmedZip.isEmpty) {
      emit(const OnboardingError('Please enter your ZIP code.'));
      return;
    }

    emit(const OnboardingZipLoading());

    try {
      final result = await _districtRepository.lookupDistrict(trimmedZip, address: address?.trim().isEmpty == true ? null : address?.trim());
      emit(OnboardingZipVerified(
        zipCode: result.zipCode,
        city: result.city,
        districtId: result.districtId,
        officials: result.officials,
      ));
    } on Exception catch (e) {
      emit(OnboardingError(_stripExceptionPrefix(e)));
    }
  }

  /// Triggers Google or Apple Sign-In via Supabase OAuth.
  ///
  /// Emits [OnboardingAuthPending] immediately. [_onAuthStateChange] handles
  /// completion once the OAuth deep-link returns to the app.
  Future<void> submitAuth(OAuthProvider provider) async {
    final current = state;
    if (current is! OnboardingZipVerified) return;

    emit(OnboardingAuthPending(
      zipCode: current.zipCode,
      city: current.city,
      districtId: current.districtId,
      officials: current.officials,
    ));

    try {
      await _authService.signInWithOAuth(
        provider,
        redirectTo: AppConstants.oauthRedirectUrl,
      );
    } on Exception catch (e) {
      emit(OnboardingError(_stripExceptionPrefix(e)));
    }
  }

  /// Saves the profile, sets the Hive onboarding flag, and awards XP.
  ///
  /// Called automatically by [_onAuthStateChange] when OAuth completes.
  Future<void> completeOnboarding() async {
    final current = state;
    if (current is! OnboardingAuthPending) return;

    try {
      final user = _authService.currentUser;
      if (user == null) {
        emit(const OnboardingError('Sign-in failed. Please try again.'));
        return;
      }

      await _profileRepository.upsertProfile(
        ProfileModel(
          id: user.id,
          xpTotal: 0,
          level: 1,
          streakCount: 0,
          zipCode: current.zipCode,
          districtId: current.districtId,
          interests: const [],
          onboardingCompleted: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final box = await Hive.openBox<dynamic>(AppConstants.hiveBoxUser);
      await box.put(AppConstants.hiveKeyOnboardingComplete, true);

      _gamificationCubit.awardXp(AppConstants.xpOnboardingComplete);

      emit(const OnboardingComplete());
    } on Exception catch (e) {
      emit(OnboardingError(_stripExceptionPrefix(e)));
    }
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }

  /// Resets the flow back to the initial state. Intended for dev/testing only.
  void reset() => emit(const OnboardingInitial());

  static String _stripExceptionPrefix(Exception e) =>
      e.toString().replaceFirst('Exception: ', '');
}
