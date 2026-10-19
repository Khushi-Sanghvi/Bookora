import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

import '../models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../theme/reading_app_colors.dart';
import 'main_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final int _totalPages = 6;

  // Profile data
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  String? _avatarPath;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _bioController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skip() {
    _completeOnboarding(skipped: true);
  }

  Future<void> _completeOnboarding({bool skipped = false}) async {
    String name = _nameController.text.trim();
    String username = _usernameController.text.trim();
    String bio = _bioController.text.trim();

    if (skipped || (name.isEmpty && username.isEmpty && bio.isEmpty)) {
      name = "Avid Reader";
      username = "@booklover";
      bio = "Exploring forgotten worlds and cozy stories.";
    } else {
      if (name.isEmpty) name = "Avid Reader";
      if (username.isEmpty) username = "@booklover";
      if (bio.isEmpty) bio = "Exploring forgotten worlds and cozy stories.";
    }

    final profile = UserProfile(
      name: name,
      username: username.startsWith('@') ? username : '@$username',
      bio: bio,
      avatarPath: _avatarPath,
      hasCompletedOnboarding: true,
      createdAt: DateTime.now(),
    );

    await ref.read(profileProvider.notifier).completeOnboarding(profile);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = p.basename(image.path);
        final savedImage = await File(image.path).copy('${directory.path}/$fileName');
        setState(() {
          _avatarPath = savedImage.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() => _currentPage = index);
        },
        children: [
          // Screen 1: Welcome Splash
          _buildWelcomeScreen(isDark),

          // Screen 2: Create Your Reader Profile (Image 2)
          _buildProfileScreen(colors, isDark),

          // Screen 3: Read in Your Way
          _buildFeatureScreen(
            isDark: isDark,
            imageAsset: isDark
                ? 'assets/images/onboarding_formats_dark.png'
                : 'assets/images/onboarding_formats_light.png',
            buttonText: 'Next →',
            buttonWidth: 148,
            onPressed: _nextPage,
          ),

          // Screen 4: Track & Grow
          _buildFeatureScreen(
            isDark: isDark,
            imageAsset: isDark
                ? 'assets/images/onboarding_track_dark.png'
                : 'assets/images/onboarding_track_light.png',
            buttonText: 'Next →',
            buttonWidth: 148,
            onPressed: _nextPage,
          ),

          // Screen 5: Organize Your Library
          _buildFeatureScreen(
            isDark: isDark,
            imageAsset: isDark
                ? 'assets/images/onboarding_organize_dark.png'
                : 'assets/images/onboarding_organize_light.png',
            buttonText: 'Next →',
            buttonWidth: 148,
            onPressed: _nextPage,
          ),

          // Screen 6: Make It Yours (Final Feature)
          _buildFeatureScreen(
            isDark: isDark,
            imageAsset: isDark
                ? 'assets/images/onboarding_theme_dark.png'
                : 'assets/images/onboarding_theme_light.png',
            buttonText: 'Get Started →',
            buttonWidth: 176,
            onPressed: _completeOnboarding,
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // BUTTON & CONTROL BUILDERS
  // =========================================================================

  Widget _buildSkipButton(bool isDark) {
    return TextButton(
      onPressed: _skip,
      style: TextButton.styleFrom(
        foregroundColor: isDark ? const Color(0xFFF59E0B) : const Color(0xFF8C3A14),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      ),
      child: Text(
        'Skip',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.w700,
          fontSize: 15,
          color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF8C3A14),
        ),
      ),
    );
  }

  Widget _buildCompactPillButton(
    String text,
    VoidCallback onPressed,
    bool isDark, {
    double width = 148,
  }) {
    return Container(
      width: width,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Color(0xFFB45309), Color(0xFF9A3412)],
              ),
        color: isDark ? const Color(0xFF140D09).withValues(alpha: 0.88) : null,
        border: isDark ? Border.all(color: const Color(0xFFF59E0B), width: 1.5) : null,
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF9A3412).withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF59E0B) : Colors.white,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWideProfileButton(String text, VoidCallback onPressed, bool isDark) {
    return Container(
      width: double.infinity,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: isDark
            ? null
            : const LinearGradient(
                colors: [Color(0xFFB45309), Color(0xFF9A3412)],
              ),
        color: isDark ? const Color(0xFF1A120B).withValues(alpha: 0.95) : null,
        border: isDark ? Border.all(color: const Color(0xFFF59E0B), width: 1.5) : null,
        boxShadow: isDark
            ? [
                BoxShadow(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: const Color(0xFF9A3412).withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(26),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFF59E0B) : Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // SCREEN 1: WELCOME SCREEN (IMAGE 1, COLUMN 1)
  // =========================================================================
  Widget _buildWelcomeScreen(bool isDark) {
    final assetPath = isDark
        ? 'assets/images/onboarding_welcome_dark.png'
        : 'assets/images/onboarding_welcome_light.png';

    return GestureDetector(
      onTap: _nextPage,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            assetPath,
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          Positioned(
            top: 12,
            right: 16,
            child: SafeArea(
              child: _buildSkipButton(isDark),
            ),
          ),
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: _buildCompactPillButton('Begin Journey →', _nextPage, isDark, width: 180),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // SCREEN 2: CREATE YOUR READER PROFILE (IMAGE 2)
  // =========================================================================
  Widget _buildProfileScreen(ReadingAppColors colors, bool isDark) {
    final borderColor = isDark
        ? const Color(0xFF5A4328)
        : const Color(0xFFE5D8C5);
    final inputFill = isDark
        ? const Color(0xFF1A1410).withValues(alpha: 0.90)
        : const Color(0xFFFDFBF7);
    final labelColor = isDark ? const Color(0xFFE0A96D) : const Color(0xFF3E2718);
    final iconColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309);

    final bgAsset = isDark
        ? 'assets/images/onboarding_welcome_dark.png'
        : 'assets/images/onboarding_welcome_light.png';

    return Stack(
      fit: StackFit.expand,
      children: [
        // Ambient background image
        Image.asset(
          bgAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),

        // Translucent overlay for crystal-clear readability
        Container(
          color: isDark
              ? const Color(0xFF0F0A07).withValues(alpha: 0.90)
              : const Color(0xFFFAF6EE).withValues(alpha: 0.90),
        ),

        // Profile Form Content
        SafeArea(
          child: Column(
            children: [
              // Top Header with Back button and "YOUR SPACE • 2 OF 6"
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF231A12) : const Color(0xFFF1E7D8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF6B4A27) : const Color(0xFFDECFC0),
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark ? const Color(0xFFF59E0B) : const Color(0xFF8C3A14),
                          size: 20,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          'YOUR SPACE • 2 OF $_totalPages',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                            color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF5A4330) : const Color(0xFFD6C8B4),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 22,
                              height: 6,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(3),
                                color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309),
                              ),
                            ),
                            const SizedBox(width: 6),
                            for (int i = 2; i < _totalPages; i++) ...[
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF5A4330) : const Color(0xFFD6C8B4),
                                ),
                              ),
                              if (i < _totalPages - 1) const SizedBox(width: 6),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 40), // Balance back button
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),
                      Text(
                        'Create Your\nReader Profile',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                          color: isDark ? const Color(0xFFF8F4EC) : const Color(0xFF321A0C),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'A little about the reader behind the stories.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFFC7B7A3) : const Color(0xFF705948),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Avatar Picker
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
                                  width: 2.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706))
                                        .withValues(alpha: 0.25),
                                    blurRadius: 16,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: _avatarPath != null
                                    ? Image.file(File(_avatarPath!), fit: BoxFit.cover)
                                    : Image.asset(
                                        isDark
                                            ? 'assets/images/profile_avatar_dark.png'
                                            : 'assets/images/profile_avatar_light.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: isDark ? const Color(0xFF2A1C12) : const Color(0xFFEAE2D3),
                                          child: Icon(
                                            Icons.pets,
                                            size: 48,
                                            color: iconColor.withValues(alpha: 0.6),
                                          ),
                                        ),
                                      ),
                              ),
                            ),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E1712) : const Color(0xFFB45309),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFFF59E0B) : Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFFF59E0B) : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Add photo (optional)',
                        style: GoogleFonts.plusJakartaSans(
                          color: isDark ? const Color(0xFFF59E0B) : const Color(0xFFB45309),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Name Field
                      _buildProfileField(
                        controller: _nameController,
                        icon: Icons.person_rounded,
                        label: 'Name',
                        hint: 'What should we call you?',
                        borderColor: borderColor,
                        fillColor: inputFill,
                        labelColor: labelColor,
                        iconColor: iconColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),

                      // Username Field
                      _buildProfileField(
                        controller: _usernameController,
                        icon: Icons.alternate_email_rounded,
                        label: 'Username',
                        hint: '@yourreadingname',
                        borderColor: borderColor,
                        fillColor: inputFill,
                        labelColor: labelColor,
                        iconColor: iconColor,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 18),

                      // Bio Field
                      _buildProfileField(
                        controller: _bioController,
                        icon: Icons.eco_rounded,
                        label: 'Bio',
                        hint: 'Tell us a little about your reading life...',
                        borderColor: borderColor,
                        fillColor: inputFill,
                        labelColor: labelColor,
                        iconColor: iconColor,
                        isDark: isDark,
                        maxLines: 3,
                        maxLength: 160,
                      ),
                      const SizedBox(height: 14),

                      // Helper note
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 14,
                            color: isDark ? const Color(0xFFA09080) : const Color(0xFF8C7A6B),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'You can change this anytime.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFA09080) : const Color(0xFF8C7A6B),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Continue Button
                      _buildWideProfileButton('Continue →', _nextPage, isDark),
                      const SizedBox(height: 12),

                      // Skip for now Button
                      TextButton(
                        onPressed: _nextPage,
                        child: Text(
                          'Skip for now',
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark ? const Color(0xFFD4A373) : const Color(0xFF8C5835),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    required String hint,
    required Color borderColor,
    required Color fillColor,
    required Color labelColor,
    required Color iconColor,
    required bool isDark,
    int maxLines = 1,
    int? maxLength,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: iconColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: labelColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          maxLength: maxLength,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : const Color(0xFF2A2017),
            fontSize: 14.5,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.plusJakartaSans(
              color: isDark
                  ? const Color(0xFF8A7968).withValues(alpha: 0.8)
                  : const Color(0xFFA69382),
              fontSize: 14,
            ),
            filled: true,
            fillColor: fillColor,
            counterStyle: GoogleFonts.plusJakartaSans(
              color: isDark ? const Color(0xFF8A7968) : const Color(0xFFA69382),
              fontSize: 11,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: iconColor, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================================
  // SCREENS 3-6: FEATURE SHOWCASES (IMAGE 1, COLUMNS 2-5)
  // =========================================================================
  Widget _buildFeatureScreen({
    required bool isDark,
    required String imageAsset,
    required String buttonText,
    required double buttonWidth,
    required VoidCallback onPressed,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imageAsset,
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
        Positioned(
          top: 12,
          right: 16,
          child: SafeArea(
            child: _buildSkipButton(isDark),
          ),
        ),
        Positioned(
          bottom: 36,
          left: 0,
          right: 0,
          child: SafeArea(
            child: Center(
              child: _buildCompactPillButton(buttonText, onPressed, isDark, width: buttonWidth),
            ),
          ),
        ),
      ],
    );
  }
}
