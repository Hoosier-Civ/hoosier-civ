import 'package:hoosierciv/data/models/official_response.dart';

sealed class OnboardingState {
  const OnboardingState();
}

final class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

final class OnboardingZipLoading extends OnboardingState {
  const OnboardingZipLoading();
}

final class OnboardingZipVerified extends OnboardingState {
  final String zipCode;
  final String districtId;
  final List<OfficialResponse> officials;

  const OnboardingZipVerified({
    required this.zipCode,
    required this.districtId,
    required this.officials,
  });
}

final class OnboardingAuthPending extends OnboardingState {
  final String zipCode;
  final String districtId;
  final List<OfficialResponse> officials;

  const OnboardingAuthPending({
    required this.zipCode,
    required this.districtId,
    required this.officials,
  });
}

final class OnboardingComplete extends OnboardingState {
  const OnboardingComplete();
}

final class OnboardingError extends OnboardingState {
  final String message;

  const OnboardingError(this.message);
}
