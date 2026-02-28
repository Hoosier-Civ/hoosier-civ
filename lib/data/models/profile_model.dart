class _Sentinel {
  const _Sentinel();
}

const _sentinel = _Sentinel();

class ProfileModel {
  final String id;
  final String? displayName;
  final int xpTotal;
  final int level;
  final int streakCount;
  final DateTime? lastMissionAt;
  final String? zipCode;
  final String? districtId;
  final List<String> interests;
  final bool onboardingCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ProfileModel({
    required this.id,
    this.displayName,
    required this.xpTotal,
    required this.level,
    required this.streakCount,
    this.lastMissionAt,
    this.zipCode,
    this.districtId,
    required this.interests,
    required this.onboardingCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      displayName: json['display_name'] as String?,
      xpTotal: json['xp_total'] as int,
      level: json['level'] as int,
      streakCount: json['streak_count'] as int,
      lastMissionAt: json['last_mission_at'] == null
          ? null
          : DateTime.parse(json['last_mission_at'] as String),
      zipCode: json['zip_code'] as String?,
      districtId: json['district_id'] as String?,
      interests: List<String>.from(json['interests'] as List),
      onboardingCompleted: json['onboarding_completed'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'xp_total': xpTotal,
      'level': level,
      'streak_count': streakCount,
      'last_mission_at': lastMissionAt?.toIso8601String(),
      'zip_code': zipCode,
      'district_id': districtId,
      'interests': interests,
      'onboarding_completed': onboardingCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProfileModel copyWith({
    Object? displayName = _sentinel,
    int? xpTotal,
    int? level,
    int? streakCount,
    Object? lastMissionAt = _sentinel,
    Object? zipCode = _sentinel,
    Object? districtId = _sentinel,
    List<String>? interests,
    bool? onboardingCompleted,
  }) {
    return ProfileModel(
      id: id,
      displayName: identical(displayName, _sentinel)
          ? this.displayName
          : displayName as String?,
      xpTotal: xpTotal ?? this.xpTotal,
      level: level ?? this.level,
      streakCount: streakCount ?? this.streakCount,
      lastMissionAt: identical(lastMissionAt, _sentinel)
          ? this.lastMissionAt
          : lastMissionAt as DateTime?,
      zipCode:
          identical(zipCode, _sentinel) ? this.zipCode : zipCode as String?,
      districtId: identical(districtId, _sentinel)
          ? this.districtId
          : districtId as String?,
      interests: interests ?? this.interests,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
