import 'package:flutter_test/flutter_test.dart';
import 'package:hoosierciv/data/models/profile_model.dart';

void main() {
  final fullJson = {
    'id': 'user-123',
    'display_name': 'Jane Doe',
    'xp_total': 150,
    'level': 3,
    'streak_count': 7,
    'last_mission_at': '2026-02-01T12:00:00.000Z',
    'zip_code': '46202',
    'district_id': 'IN-07',
    'interests': ['voting', 'environment'],
    'onboarding_completed': true,
    'created_at': '2026-01-01T00:00:00.000Z',
    'updated_at': '2026-02-01T12:00:00.000Z',
  };

  final sparseJson = {
    'id': 'user-456',
    'display_name': null,
    'xp_total': 0,
    'level': 1,
    'streak_count': 0,
    'last_mission_at': null,
    'zip_code': null,
    'district_id': null,
    'interests': <String>[],
    'onboarding_completed': false,
    'created_at': '2026-01-15T00:00:00.000Z',
    'updated_at': '2026-01-15T00:00:00.000Z',
  };

  group('ProfileModel.fromJson', () {
    test('parses all fields correctly', () {
      final model = ProfileModel.fromJson(fullJson);

      expect(model.id, 'user-123');
      expect(model.displayName, 'Jane Doe');
      expect(model.xpTotal, 150);
      expect(model.level, 3);
      expect(model.streakCount, 7);
      expect(model.lastMissionAt, DateTime.parse('2026-02-01T12:00:00.000Z'));
      expect(model.zipCode, '46202');
      expect(model.districtId, 'IN-07');
      expect(model.interests, ['voting', 'environment']);
      expect(model.onboardingCompleted, true);
      expect(model.createdAt, DateTime.parse('2026-01-01T00:00:00.000Z'));
      expect(model.updatedAt, DateTime.parse('2026-02-01T12:00:00.000Z'));
    });

    test('handles null optional fields', () {
      final model = ProfileModel.fromJson(sparseJson);

      expect(model.displayName, isNull);
      expect(model.lastMissionAt, isNull);
      expect(model.zipCode, isNull);
      expect(model.districtId, isNull);
      expect(model.interests, isEmpty);
      expect(model.onboardingCompleted, false);
    });
  });

  group('ProfileModel.toJson', () {
    test('serializes all fields correctly', () {
      final model = ProfileModel.fromJson(fullJson);
      final json = model.toJson();

      expect(json['id'], 'user-123');
      expect(json['display_name'], 'Jane Doe');
      expect(json['xp_total'], 150);
      expect(json['level'], 3);
      expect(json['streak_count'], 7);
      expect(json['last_mission_at'], '2026-02-01T12:00:00.000Z');
      expect(json['zip_code'], '46202');
      expect(json['district_id'], 'IN-07');
      expect(json['interests'], ['voting', 'environment']);
      expect(json['onboarding_completed'], true);
    });

    test('serializes null optional fields as null', () {
      final model = ProfileModel.fromJson(sparseJson);
      final json = model.toJson();

      expect(json['display_name'], isNull);
      expect(json['last_mission_at'], isNull);
      expect(json['zip_code'], isNull);
      expect(json['district_id'], isNull);
    });
  });

  group('ProfileModel round-trip', () {
    test('fromJson(toJson()) preserves all fields', () {
      final original = ProfileModel.fromJson(fullJson);
      final roundTripped = ProfileModel.fromJson(original.toJson());

      expect(roundTripped.id, original.id);
      expect(roundTripped.displayName, original.displayName);
      expect(roundTripped.xpTotal, original.xpTotal);
      expect(roundTripped.level, original.level);
      expect(roundTripped.streakCount, original.streakCount);
      expect(roundTripped.lastMissionAt, original.lastMissionAt);
      expect(roundTripped.zipCode, original.zipCode);
      expect(roundTripped.districtId, original.districtId);
      expect(roundTripped.interests, original.interests);
      expect(roundTripped.onboardingCompleted, original.onboardingCompleted);
      expect(roundTripped.createdAt, original.createdAt);
      expect(roundTripped.updatedAt, original.updatedAt);
    });
  });

  group('ProfileModel.copyWith', () {
    late ProfileModel base;

    setUp(() {
      base = ProfileModel.fromJson(fullJson);
    });

    test('updates specified fields', () {
      final updated = base.copyWith(
        displayName: 'John Smith',
        xpTotal: 200,
        zipCode: '46201',
      );

      expect(updated.displayName, 'John Smith');
      expect(updated.xpTotal, 200);
      expect(updated.zipCode, '46201');
    });

    test('keeps unspecified fields unchanged', () {
      final updated = base.copyWith(displayName: 'Updated');

      expect(updated.id, base.id);
      expect(updated.level, base.level);
      expect(updated.streakCount, base.streakCount);
      expect(updated.lastMissionAt, base.lastMissionAt);
      expect(updated.districtId, base.districtId);
      expect(updated.interests, base.interests);
      expect(updated.onboardingCompleted, base.onboardingCompleted);
      expect(updated.createdAt, base.createdAt);
      expect(updated.updatedAt, base.updatedAt);
    });

    test('does not modify the original', () {
      base.copyWith(xpTotal: 999);
      expect(base.xpTotal, 150);
    });
  });
}
