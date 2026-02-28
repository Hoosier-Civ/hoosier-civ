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

  /// Validates the ZIP locally then calls the lookup-district Edge Function.
  ///
  /// Rejects any ZIP not starting with 46 or 47 before making an API call.
  Future<void> submitZip(String zip) async {
    final trimmed = zip.trim();

    if (!_isIndianaZip(trimmed)) {
      emit(const OnboardingError(
        'Please enter a valid Indiana ZIP code (starts with 46 or 47).',
      ));
      return;
    }

    emit(const OnboardingZipLoading());

    try {
      final result = await _districtRepository.lookupDistrict(trimmed);
      emit(OnboardingZipVerified(
        zipCode: trimmed,
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

  static bool _isIndianaZip(String zip) {
    if (zip.length != 5) return false;
    final prefix = int.tryParse(zip.substring(0, 2));
    return prefix == 46 || prefix == 47;
  }

  static String _stripExceptionPrefix(Exception e) =>
      e.toString().replaceFirst('Exception: ', '');
}
