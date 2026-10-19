class UserProfile {
  final String name;
  final String username;
  final String bio;
  final String? avatarPath;
  final bool hasCompletedOnboarding;
  final DateTime createdAt;

  const UserProfile({
    required this.name,
    required this.username,
    required this.bio,
    this.avatarPath,
    this.hasCompletedOnboarding = false,
    required this.createdAt,
  });

  String get initials {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'username': username,
      'bio': bio,
      'avatarPath': avatarPath,
      'hasCompletedOnboarding': hasCompletedOnboarding ? 1 : 0,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      name: map['name']?.toString() ?? 'Avid Reader',
      username: map['username']?.toString() ?? '@booklover',
      bio: map['bio']?.toString() ?? 'Exploring forgotten worlds and cozy stories.',
      avatarPath: map['avatarPath']?.toString(),
      hasCompletedOnboarding: map['hasCompletedOnboarding'] == 1 || map['hasCompletedOnboarding'] == true,
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  UserProfile copyWith({
    String? name,
    String? username,
    String? bio,
    String? avatarPath,
    bool? hasCompletedOnboarding,
    DateTime? createdAt,
  }) {
    return UserProfile(
      name: name ?? this.name,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      avatarPath: avatarPath ?? this.avatarPath,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
