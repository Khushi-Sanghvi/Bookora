import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:between_world/providers/goal_provider.dart';

void main() {
  group('ReadingGoalNotifier Tests', () {
    test('initializes with default goal of 25 and updates state', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final initial = container.read(readingGoalProvider);
      expect(initial, equals(25));

      container.read(readingGoalProvider.notifier).setGoal(45);
      final updated = container.read(readingGoalProvider);
      expect(updated, equals(45));
    });

    test('ignores non-positive goals', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(readingGoalProvider.notifier).setGoal(0);
      expect(container.read(readingGoalProvider), equals(25));

      container.read(readingGoalProvider.notifier).setGoal(-5);
      expect(container.read(readingGoalProvider), equals(25));
    });

    test('resetGoal resets state back to default 25', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(readingGoalProvider.notifier).setGoal(50);
      expect(container.read(readingGoalProvider), equals(50));

      await container.read(readingGoalProvider.notifier).resetGoal();
      expect(container.read(readingGoalProvider), equals(25));
    });
  });
}
