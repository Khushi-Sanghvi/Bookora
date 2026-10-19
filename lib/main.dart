import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'providers/theme_provider.dart';
import 'screens/main_screen.dart';
import 'screens/onboarding_screen.dart';
import 'repositories/user_settings_repository.dart';
import 'services/audiobook_audio_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;

  try {
    await initAudioService();
  } catch (e) {
    debugPrint('AudioService init note: $e');
  }

  // Pre-warm SharedPreferences cache to ensure instant theme & goal loading without frame flicker
  try {
    await SharedPreferences.getInstance();
  } catch (e) {
    debugPrint('SharedPreferences init note: $e');
  }

  // Pre-fetch onboarding status via repository
  bool hasCompletedOnboarding = false;
  try {
    final profile = await UserSettingsRepositoryImpl().getUserProfile();
    hasCompletedOnboarding = profile?.hasCompletedOnboarding ?? false;
  } catch (_) {}

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runApp(
    ProviderScope(
      child: BookoraApp(hasCompletedOnboarding: hasCompletedOnboarding),
    ),
  );
}

class BookoraApp extends ConsumerWidget {
  final bool hasCompletedOnboarding;
  
  const BookoraApp({super.key, required this.hasCompletedOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isAudioHandlerReady) {
      try {
        audioHandler.setRef(ref);
      } catch (_) {}
    }

    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Bookora',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.parchmentIvory(),
      darkTheme: AppTheme.midnightLibrary(),
      themeMode: themeMode,
      home: hasCompletedOnboarding ? const MainScreen() : const OnboardingScreen(),
    );
  }
}
