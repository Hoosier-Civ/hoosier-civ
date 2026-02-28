// Mirrors the TypeScript OfficialResponse returned by the lookup-district
// Edge Function.

class OfficialAddress {
  final String address1;
  final String address2;
  final String city;
  final String state;
  final String postalCode;
  final String phone1;
  final String fax1;

  const OfficialAddress({
    required this.address1,
    required this.address2,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.phone1,
    required this.fax1,
  });

  factory OfficialAddress.fromJson(Map<String, dynamic> json) {
    return OfficialAddress(
      address1: json['address_1'] as String? ?? '',
      address2: json['address_2'] as String? ?? '',
      city: json['city'] as String? ?? '',
      state: json['state'] as String? ?? '',
      postalCode: json['postal_code'] as String? ?? '',
      phone1: json['phone_1'] as String? ?? '',
      fax1: json['fax_1'] as String? ?? '',
    );
  }
}

class OfficialIdentifier {
  final String identifierType;
  final String identifierValue;

  const OfficialIdentifier({
    required this.identifierType,
    required this.identifierValue,
  });

  factory OfficialIdentifier.fromJson(Map<String, dynamic> json) {
    return OfficialIdentifier(
      identifierType: json['identifier_type'] as String? ?? '',
      identifierValue: json['identifier_value'] as String? ?? '',
    );
  }
}

class OfficialCommittee {
  final String name;
  final List<String> urls;
  final String position;

  const OfficialCommittee({
    required this.name,
    required this.urls,
    required this.position,
  });

  factory OfficialCommittee.fromJson(Map<String, dynamic> json) {
    return OfficialCommittee(
      name: json['name'] as String? ?? '',
      urls: List<String>.from(json['urls'] as List? ?? []),
      position: json['position'] as String? ?? '',
    );
  }
}

class OfficialResponse {
  final int ciceroId;
  final String firstName;
  final String lastName;
  final String? middleInitial;
  final String? salutation;
  final String? nickname;
  final String? preferredName;
  final String? nameSuffix;

  /// Computed from district_type: us_senate, us_house, national_exec,
  /// senate, house, state_exec, local, local_exec.
  final String chamber;
  final String? officeTitle;
  final String? party;
  final String? districtType;
  final String? districtOcdId;
  final String? districtState;
  final String? districtCity;
  final String? districtLabel;
  final String? chamberName;
  final String? chamberNameFormal;
  final String? photoUrl;
  final String? websiteUrl;
  final String? webFormUrl;
  final List<OfficialAddress> addresses;
  final List<String> emailAddresses;
  final List<OfficialIdentifier> identifiers;
  final List<OfficialCommittee> committees;
  final String? termStartDate;
  final String? termEndDate;
  final String? bio;
  final String? birthDate;

  const OfficialResponse({
    required this.ciceroId,
    required this.firstName,
    required this.lastName,
    this.middleInitial,
    this.salutation,
    this.nickname,
    this.preferredName,
    this.nameSuffix,
    required this.chamber,
    this.officeTitle,
    this.party,
    this.districtType,
    this.districtOcdId,
    this.districtState,
    this.districtCity,
    this.districtLabel,
    this.chamberName,
    this.chamberNameFormal,
    this.photoUrl,
    this.websiteUrl,
    this.webFormUrl,
    required this.addresses,
    required this.emailAddresses,
    required this.identifiers,
    required this.committees,
    this.termStartDate,
    this.termEndDate,
    this.bio,
    this.birthDate,
  });

  factory OfficialResponse.fromJson(Map<String, dynamic> json) {
    return OfficialResponse(
      ciceroId: json['cicero_id'] as int,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      middleInitial: json['middle_initial'] as String?,
      salutation: json['salutation'] as String?,
      nickname: json['nickname'] as String?,
      preferredName: json['preferred_name'] as String?,
      nameSuffix: json['name_suffix'] as String?,
      chamber: json['chamber'] as String? ?? '',
      officeTitle: json['office_title'] as String?,
      party: json['party'] as String?,
      districtType: json['district_type'] as String?,
      districtOcdId: json['district_ocd_id'] as String?,
      districtState: json['district_state'] as String?,
      districtCity: json['district_city'] as String?,
      districtLabel: json['district_label'] as String?,
      chamberName: json['chamber_name'] as String?,
      chamberNameFormal: json['chamber_name_formal'] as String?,
      photoUrl: json['photo_url'] as String?,
      websiteUrl: json['website_url'] as String?,
      webFormUrl: json['web_form_url'] as String?,
      addresses: (json['addresses'] as List? ?? [])
          .map((a) => OfficialAddress.fromJson(a as Map<String, dynamic>))
          .toList(),
      emailAddresses: List<String>.from(json['email_addresses'] as List? ?? []),
      identifiers: (json['identifiers'] as List? ?? [])
          .map((i) => OfficialIdentifier.fromJson(i as Map<String, dynamic>))
          .toList(),
      committees: (json['committees'] as List? ?? [])
          .map((c) => OfficialCommittee.fromJson(c as Map<String, dynamic>))
          .toList(),
      termStartDate: json['term_start_date'] as String?,
      termEndDate: json['term_end_date'] as String?,
      bio: json['bio'] as String?,
      birthDate: json['birth_date'] as String?,
    );
  }
}
