import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/user_settings_repository.dart';

export '../repositories/user_settings_repository.dart'
    show userSettingsRepositoryProvider, UserSettingsRepository, UserSettingsRepositoryImpl;

class ReadingGoalNotifier extends StateNotifier<int> {
  final UserSettingsRepository _repository;

  ReadingGoalNotifier([UserSettingsRepository? repository])
      : _repository = repository ?? UserSettingsRepositoryImpl(),
        super(25) {
    _loadPersistedGoal();
  }

  Future<void> _loadPersistedGoal() async {
    final saved = await _repository.getReadingGoal();
    if (saved > 0) {
      state = saved;
    }
  }

  Future<void> setGoal(int newGoal) async {
    if (newGoal > 0) {
      state = newGoal;
      await _repository.setReadingGoal(newGoal);
    }
  }

  Future<void> resetGoal() async {
    state = 25;
    await _repository.resetReadingGoal();
  }
}

final readingGoalProvider = StateNotifierProvider<ReadingGoalNotifier, int>((ref) {
  final repository = ref.watch(userSettingsRepositoryProvider);
  return ReadingGoalNotifier(repository);
});
