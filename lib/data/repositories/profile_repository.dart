import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hoosierciv/data/models/profile_model.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  const ProfileRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  Future<ProfileModel?> fetchProfile() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _supabase
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return ProfileModel.fromJson(data);
  }

  Future<ProfileModel> upsertProfile(ProfileModel profile) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('Cannot update profile without an authenticated user.');
    }

    // Send only mutable, non-gamification fields so that an upsert never
    // clobbers immutable columns (created_at) or fields managed by other
    // flows (xp_total, level, streak_count, last_mission_at).
    final payload = <String, dynamic>{
      'id': userId,
      'display_name': profile.displayName,
      'zip_code': profile.zipCode,
      'district_id': profile.districtId,
      'interests': profile.interests,
      'onboarding_completed': profile.onboardingCompleted,
    };

    final data = await _supabase
        .from('profiles')
        .upsert(payload)
        .select()
        .single();

    return ProfileModel.fromJson(data);
  }
}
