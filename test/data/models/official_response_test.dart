import 'package:flutter_test/flutter_test.dart';
import 'package:hoosierciv/data/models/official_response.dart';

void main() {
  group('OfficialAddress.fromJson', () {
    test('parses all fields', () {
      final json = {
        'address_1': '200 W Washington St',
        'address_2': 'Suite 100',
        'city': 'Indianapolis',
        'state': 'IN',
        'postal_code': '46204',
        'phone_1': '317-555-0100',
        'fax_1': '317-555-0101',
      };
      final addr = OfficialAddress.fromJson(json);
      expect(addr.address1, '200 W Washington St');
      expect(addr.address2, 'Suite 100');
      expect(addr.city, 'Indianapolis');
      expect(addr.state, 'IN');
      expect(addr.postalCode, '46204');
      expect(addr.phone1, '317-555-0100');
      expect(addr.fax1, '317-555-0101');
    });

    test('defaults missing fields to empty string', () {
      final addr = OfficialAddress.fromJson({});
      expect(addr.address1, '');
      expect(addr.address2, '');
      expect(addr.city, '');
      expect(addr.state, '');
      expect(addr.postalCode, '');
      expect(addr.phone1, '');
      expect(addr.fax1, '');
    });
  });

  group('OfficialIdentifier.fromJson', () {
    test('parses all fields', () {
      final json = {
        'identifier_type': 'bioguide',
        'identifier_value': 'A000001',
      };
      final id = OfficialIdentifier.fromJson(json);
      expect(id.identifierType, 'bioguide');
      expect(id.identifierValue, 'A000001');
    });

    test('defaults missing fields to empty string', () {
      final id = OfficialIdentifier.fromJson({});
      expect(id.identifierType, '');
      expect(id.identifierValue, '');
    });
  });

  group('OfficialCommittee.fromJson', () {
    test('parses all fields', () {
      final json = {
        'name': 'Committee on Finance',
        'urls': ['https://finance.senate.gov'],
        'position': 'Chair',
      };
      final committee = OfficialCommittee.fromJson(json);
      expect(committee.name, 'Committee on Finance');
      expect(committee.urls, ['https://finance.senate.gov']);
      expect(committee.position, 'Chair');
    });

    test('defaults missing fields to empty string and empty list', () {
      final committee = OfficialCommittee.fromJson({});
      expect(committee.name, '');
      expect(committee.urls, isEmpty);
      expect(committee.position, '');
    });
  });

  group('OfficialResponse.fromJson', () {
    final fullJson = {
      'cicero_id': 12345,
      'first_name': 'Jane',
      'last_name': 'Smith',
      'middle_initial': 'A',
      'salutation': 'Sen.',
      'nickname': 'JAS',
      'preferred_name': 'Jane A.',
      'name_suffix': 'Jr.',
      'chamber': 'senate',
      'office_title': 'Senator',
      'party': 'D',
      'district_type': 'STATE_UPPER',
      'district_ocd_id': 'ocd-division/country:us/state:in/sldu:1',
      'district_state': 'IN',
      'district_city': null,
      'district_label': 'Senate District 1',
      'chamber_name': 'Indiana Senate',
      'chamber_name_formal': 'The Indiana Senate',
      'photo_url': 'https://example.com/photo.jpg',
      'website_url': 'https://example.com',
      'web_form_url': 'https://example.com/contact',
      'addresses': [
        {
          'address_1': '200 W Washington St',
          'address_2': '',
          'city': 'Indianapolis',
          'state': 'IN',
          'postal_code': '46204',
          'phone_1': '317-555-0100',
          'fax_1': '',
        }
      ],
      'email_addresses': ['jane@example.com'],
      'identifiers': [
        {'identifier_type': 'bioguide', 'identifier_value': 'A000001'}
      ],
      'committees': [
        {
          'name': 'Finance',
          'urls': ['https://finance.senate.gov'],
          'position': 'Member',
        }
      ],
      'term_start_date': '2023-01-01',
      'term_end_date': '2027-01-01',
      'bio': 'A dedicated public servant.',
      'birth_date': '1970-05-15',
    };

    test('parses all fields correctly', () {
      final official = OfficialResponse.fromJson(fullJson);

      expect(official.ciceroId, 12345);
      expect(official.firstName, 'Jane');
      expect(official.lastName, 'Smith');
      expect(official.middleInitial, 'A');
      expect(official.salutation, 'Sen.');
      expect(official.nickname, 'JAS');
      expect(official.preferredName, 'Jane A.');
      expect(official.nameSuffix, 'Jr.');
      expect(official.chamber, 'senate');
      expect(official.officeTitle, 'Senator');
      expect(official.party, 'D');
      expect(official.districtType, 'STATE_UPPER');
      expect(
        official.districtOcdId,
        'ocd-division/country:us/state:in/sldu:1',
      );
      expect(official.districtState, 'IN');
      expect(official.districtCity, isNull);
      expect(official.districtLabel, 'Senate District 1');
      expect(official.chamberName, 'Indiana Senate');
      expect(official.chamberNameFormal, 'The Indiana Senate');
      expect(official.photoUrl, 'https://example.com/photo.jpg');
      expect(official.websiteUrl, 'https://example.com');
      expect(official.webFormUrl, 'https://example.com/contact');
      expect(official.emailAddresses, ['jane@example.com']);
      expect(official.termStartDate, '2023-01-01');
      expect(official.termEndDate, '2027-01-01');
      expect(official.bio, 'A dedicated public servant.');
      expect(official.birthDate, '1970-05-15');
    });

    test('parses nested addresses', () {
      final official = OfficialResponse.fromJson(fullJson);
      expect(official.addresses.length, 1);
      expect(official.addresses.first.city, 'Indianapolis');
    });

    test('parses nested identifiers', () {
      final official = OfficialResponse.fromJson(fullJson);
      expect(official.identifiers.length, 1);
      expect(official.identifiers.first.identifierType, 'bioguide');
    });

    test('parses nested committees', () {
      final official = OfficialResponse.fromJson(fullJson);
      expect(official.committees.length, 1);
      expect(official.committees.first.name, 'Finance');
    });

    test('handles null optional fields gracefully', () {
      final minimalJson = {
        'cicero_id': 99,
        'first_name': 'John',
        'last_name': 'Doe',
        'chamber': 'house',
      };
      final official = OfficialResponse.fromJson(minimalJson);

      expect(official.ciceroId, 99);
      expect(official.firstName, 'John');
      expect(official.lastName, 'Doe');
      expect(official.chamber, 'house');
      expect(official.middleInitial, isNull);
      expect(official.salutation, isNull);
      expect(official.nickname, isNull);
      expect(official.preferredName, isNull);
      expect(official.nameSuffix, isNull);
      expect(official.officeTitle, isNull);
      expect(official.party, isNull);
      expect(official.districtType, isNull);
      expect(official.districtOcdId, isNull);
      expect(official.districtState, isNull);
      expect(official.districtCity, isNull);
      expect(official.districtLabel, isNull);
      expect(official.chamberName, isNull);
      expect(official.chamberNameFormal, isNull);
      expect(official.photoUrl, isNull);
      expect(official.websiteUrl, isNull);
      expect(official.webFormUrl, isNull);
      expect(official.addresses, isEmpty);
      expect(official.emailAddresses, isEmpty);
      expect(official.identifiers, isEmpty);
      expect(official.committees, isEmpty);
      expect(official.termStartDate, isNull);
      expect(official.termEndDate, isNull);
      expect(official.bio, isNull);
      expect(official.birthDate, isNull);
    });

    test('defaults missing string fields to empty string', () {
      final json = {
        'cicero_id': 1,
        'chamber': 'local',
      };
      final official = OfficialResponse.fromJson(json);
      expect(official.firstName, '');
      expect(official.lastName, '');
    });
  });
}
