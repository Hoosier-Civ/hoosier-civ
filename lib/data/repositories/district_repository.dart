import 'package:hoosierciv/data/models/official_response.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DistrictLookupResult {
  final String city;
  final String zipCode;
  final String districtId;
  final List<OfficialResponse> officials;

  const DistrictLookupResult({
    required this.city,
    required this.zipCode,
    required this.districtId,
    required this.officials,
  });
}

class DistrictRepository {
  final SupabaseClient _supabase;

  const DistrictRepository({required SupabaseClient supabase})
      : _supabase = supabase;

  Future<DistrictLookupResult> lookupDistrict(String zip, {String? address}) async {
    final response = await _supabase.functions.invoke(
      'lookup-district',
      body: {'zip': zip, if (address != null) 'address': address},
    );

    if (response.status != 200) {
      final message =
          (response.data as Map<String, dynamic>?)?['error'] as String? ??
              'Failed to look up district';
      throw Exception(message);
    }

    final data = response.data as Map<String, dynamic>;
    final city = data['city'] as String? ?? '';
    final zipCode = data['zip_code'] as String? ?? '';
    final districtId = data['district_id'] as String;
    final officials = (data['officials'] as List? ?? [])
        .map((o) => OfficialResponse.fromJson(o as Map<String, dynamic>))
        .toList();

    return DistrictLookupResult(
      city: city,
      zipCode: zipCode,
      districtId: districtId,
      officials: officials,
    );
  }
}
