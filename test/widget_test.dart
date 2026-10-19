import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:between_world/main.dart';

void main() {
  testWidgets('BookoraApp loads inside ProviderScope', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BookoraApp(hasCompletedOnboarding: true),
      ),
    );

    await tester.pump();
    expect(find.byType(BookoraApp), findsOneWidget);
  });
}
