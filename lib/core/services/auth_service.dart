import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin abstraction over Supabase auth so the OnboardingCubit can be tested
/// without a real SupabaseClient.
abstract class AuthService {
  Stream<AuthState> get onAuthStateChange;
  User? get currentUser;
  Future<void> signInWithOAuth(
    OAuthProvider provider, {
    String? redirectTo,
  });
}

class SupabaseAuthService implements AuthService {
  final SupabaseClient _supabase;

  const SupabaseAuthService(this._supabase);

  @override
  Stream<AuthState> get onAuthStateChange => _supabase.auth.onAuthStateChange;

  @override
  User? get currentUser => _supabase.auth.currentUser;

  @override
  Future<void> signInWithOAuth(
    OAuthProvider provider, {
    String? redirectTo,
  }) =>
      _supabase.auth.signInWithOAuth(provider, redirectTo: redirectTo);
}
