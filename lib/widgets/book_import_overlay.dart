import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/file_import_service.dart';
import '../theme/reading_app_colors.dart';
import 'bookora_toast.dart';

/// Interactive Luxury Glassmorphic Import Overlay HUD for Bookora
class BookImportOverlay {
  static Future<FileImportResult?> show(
    BuildContext context, {
    required Future<FileImportResult> Function(
      void Function(String stage, double progress) updateProgress,
    )
    importTask,
  }) async {
    final result = await showGeneralDialog<FileImportResult>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Importing Book',
      barrierColor: Colors.black.withValues(alpha: 0.65),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (ctx, anim1, anim2) =>
          _BookImportOverlayContent(importTask: importTask),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutBack,
        );
        return BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 16 * anim1.value,
            sigmaY: 16 * anim1.value,
          ),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.88, end: 1.0).animate(curved),
            child: FadeTransition(opacity: anim1, child: child),
          ),
        );
      },
    );

    if (context.mounted && result != null) {
      if (result.success) {
        BookoraToast.show(
          context,
          message: result.book != null
              ? 'Added "${result.book!.title}"'
              : 'Book successfully imported',
          icon: Icons.bookmark_added_rounded,
        );
      } else if (result.message != 'Import cancelled.' && result.errorMessage != 'Import cancelled by user') {
        BookoraToast.show(
          context,
          message: result.message,
          icon: Icons.info_outline_rounded,
          isError: true,
        );
      }
    }

    return result;
  }
}

class _BookImportOverlayContent extends StatefulWidget {
  final Future<FileImportResult> Function(
    void Function(String stage, double progress) updateProgress,
  )
  importTask;

  const _BookImportOverlayContent({required this.importTask});

  @override
  State<_BookImportOverlayContent> createState() =>
      _BookImportOverlayContentState();
}

class _BookImportOverlayContentState extends State<_BookImportOverlayContent>
    with TickerProviderStateMixin {
  String _currentStage = 'Selecting document...';
  double _progress = 0.05;
  bool _isSuccess = false;
  String? _finalTitle;

  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startImport();
  }

  void _startImport() async {
    final result = await widget.importTask((stage, progress) {
      if (mounted) {
        setState(() {
          _currentStage = stage;
          _progress = progress.clamp(0.0, 1.0);
        });
      }
    });

    if (mounted) {
      if (result.success) {
        setState(() {
          _isSuccess = true;
          _progress = 1.0;
          _currentStage = 'Successfully Added to Shelf!';
          _finalTitle = result.book?.title;
        });

        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(result);
        }
      } else {
        Navigator.of(context, rootNavigator: true).pop(result);
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 320,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: const LinearGradient(
              colors: [Color(0xF01A1C24), Color(0xF012141A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: _isSuccess
                  ? AppColors.plantGreen.withValues(alpha: 0.6)
                  : AppColors.candleAmber.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.7),
                blurRadius: 36,
                offset: const Offset(0, 16),
              ),
              BoxShadow(
                color:
                    (_isSuccess ? AppColors.plantGreen : AppColors.candleAmber)
                        .withValues(alpha: 0.25),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Center Hologram / Orbit Glow
              SizedBox(
                width: 96,
                height: 96,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Spinning Gradient Ring
                    RotationTransition(
                      turns: _rotationController,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: SweepGradient(
                            colors: _isSuccess
                                ? [
                                    AppColors.plantGreenLight,
                                    AppColors.plantGreen.withValues(alpha: 0.1),
                                    AppColors.plantGreen,
                                  ]
                                : [
                                    AppColors.candleAmber,
                                    AppColors.goldGlow.withValues(alpha: 0.1),
                                    AppColors.goldAccent,
                                    AppColors.candleAmber,
                                  ],
                          ),
                        ),
                      ),
                    ),
                    // Inner Mask Ring
                    Container(
                      width: 86,
                      height: 86,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFF14161F),
                      ),
                    ),
                    // Pulsing Center Icon
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              (_isSuccess
                                      ? AppColors.plantGreen
                                      : AppColors.candleAmber)
                                  .withValues(alpha: 0.35),
                              (_isSuccess
                                      ? AppColors.plantGreen
                                      : AppColors.candleAmber)
                                  .withValues(alpha: 0.05),
                            ],
                          ),
                        ),
                        child: Icon(
                          _isSuccess
                              ? Icons.check_circle_rounded
                              : Icons.auto_stories_rounded,
                          color: _isSuccess
                              ? AppColors.plantGreenLight
                              : AppColors.candleAmber,
                          size: 34,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // 2. Title & Stage Text
              Text(
                _isSuccess ? 'Import Complete!' : 'Importing Book',
                style: GoogleFonts.cinzel(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.sepiaLight,
                  letterSpacing: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  _finalTitle != null ? 'Added "$_finalTitle"' : _currentStage,
                  key: ValueKey<String>(_finalTitle ?? _currentStage),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: _isSuccess
                        ? AppColors.plantGreenLight
                        : AppColors.candleGlow,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 20),

              // 3. Glowing Gradient Progress Bar
              Stack(
                children: [
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.0, end: _progress),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, val, child) {
                      return FractionallySizedBox(
                        widthFactor: val.clamp(0.01, 1.0),
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            gradient: LinearGradient(
                              colors: _isSuccess
                                  ? [
                                      AppColors.plantGreen,
                                      AppColors.plantGreenLight,
                                    ]
                                : [
                                      AppColors.warmOrange,
                                      AppColors.candleAmber,
                                      AppColors.goldGlow,
                                    ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isSuccess
                                        ? AppColors.plantGreen
                                        : AppColors.candleAmber)
                                    .withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 4. Percentage Text
              Text(
                '${(_progress * 100).toInt()}%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.sepiaMuted,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
