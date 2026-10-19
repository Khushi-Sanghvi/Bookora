import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_profile.dart';
import '../repositories/user_settings_repository.dart';

export '../repositories/user_settings_repository.dart'
    show userSettingsRepositoryProvider, UserSettingsRepository, UserSettingsRepositoryImpl;

class UserProfileNotifier extends StateNotifier<UserProfile> {
  final UserSettingsRepository _repository;

  UserProfileNotifier([UserSettingsRepository? repository])
      : _repository = repository ?? UserSettingsRepositoryImpl(),
        super(UserProfile(
          name: 'Avid Reader',
          username: '@booklover',
          bio: 'Exploring forgotten worlds and cozy stories.',
          hasCompletedOnboarding: false,
          createdAt: DateTime.now(),
        )) {
    _initLoad();
  }

  Future<void> _initLoad() async {
    try {
      final profile = await _repository.getUserProfile();
      if (profile != null) {
        state = profile;
      }
    } catch (_) {}
  }

  Future<void> updateProfile({
    required String name,
    required String username,
    String? bio,
    String? avatarPath,
  }) async {
    String cleanHandle = username.trim();
    if (!cleanHandle.startsWith('@') && cleanHandle.isNotEmpty) {
      cleanHandle = '@$cleanHandle';
    }

    final updated = state.copyWith(
      name: name.trim(),
      username: cleanHandle,
      bio: bio?.trim(),
      avatarPath: avatarPath,
    );

    state = updated;
    try {
      await _repository.saveUserProfile(updated);
    } catch (_) {}
  }

  Future<void> completeOnboarding(UserProfile profile) async {
    final updated = profile.copyWith(hasCompletedOnboarding: true);
    state = updated;
    try {
      await _repository.saveUserProfile(updated);
    } catch (_) {}
  }
}

final profileProvider = StateNotifierProvider<UserProfileNotifier, UserProfile>((ref) {
  final repository = ref.watch(userSettingsRepositoryProvider);
  return UserProfileNotifier(repository);
});
