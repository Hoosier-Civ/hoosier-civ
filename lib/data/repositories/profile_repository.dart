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

    final data = await _supabase
        .from('profiles')
        .update(profile.toJson())
        .eq('id', userId)
        .select()
        .single();

    return ProfileModel.fromJson(data);
  }
}
