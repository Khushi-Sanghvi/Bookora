import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum NotificationTone {
  emeraldSuccess,
  amberProgress,
  coralBookmark,
  calendarDate,
  ambianceSwitch,
  outlineJump,
  quoteSaved,
  destructiveRemove,
}

class BookoraNotificationBanner extends StatelessWidget {
  final NotificationTone tone;
  final Widget leadingIcon;
  final String message;
  final bool isToast; // true: trailing checkmark badge | false: trailing dismiss X
  final VoidCallback? onDismiss;

  const BookoraNotificationBanner({
    super.key,
    required this.tone,
    required this.leadingIcon,
    required this.message,
    this.isToast = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    List<Color> gradientColors;
    Color borderColor;
    Color textColor;
    Color? checkPillColor;

    switch (tone) {
      case NotificationTone.emeraldSuccess:
        gradientColors = isDark ? [const Color(0xFF0C2B1C), const Color(0xFF133E29)] : [const Color(0xFFE2F3E7), const Color(0xFFD5ECDC)];
        borderColor = isDark ? const Color(0xFF10B981).withValues(alpha: 0.45) : const Color(0xFF86B392);
        textColor = isDark ? const Color(0xFF6EE7B7) : const Color(0xFF1B4328);
        checkPillColor = isDark ? const Color(0xFF10B981) : const Color(0xFF22C55E);
        break;
      case NotificationTone.amberProgress:
        gradientColors = isDark ? [const Color(0xFF2B1B0E), const Color(0xFF3E2613)] : [const Color(0xFFFDEFE3), const Color(0xFFFCE5D3)];
        borderColor = isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.45) : const Color(0xFFF97316).withValues(alpha: 0.35);
        textColor = isDark ? const Color(0xFFFCD34D) : const Color(0xFF7C2D12);
        checkPillColor = isDark ? const Color(0xFFF59E0B) : const Color(0xFFF97316);
        break;
      case NotificationTone.coralBookmark:
        gradientColors = isDark ? [const Color(0xFF2E1018), const Color(0xFF421622)] : [const Color(0xFFFDECEE), const Color(0xFFFCDFE2)];
        borderColor = isDark ? const Color(0xFFFB7185).withValues(alpha: 0.45) : const Color(0xFFF43F5E).withValues(alpha: 0.35);
        textColor = isDark ? const Color(0xFFFDA4AF) : const Color(0xFF881337);
        checkPillColor = isDark ? const Color(0xFFFB7185) : const Color(0xFFF43F5E);
        break;
      case NotificationTone.calendarDate:
        gradientColors = isDark ? [const Color(0xFF0E2138), const Color(0xFF143154)] : [const Color(0xFFFBF4E6), const Color(0xFFF6E9D0)];
        borderColor = isDark ? const Color(0xFF38BDF8).withValues(alpha: 0.45) : const Color(0xFFD97706).withValues(alpha: 0.35);
        textColor = isDark ? const Color(0xFFBAE6FD) : const Color(0xFF451A03);
        break;
      case NotificationTone.ambianceSwitch:
        gradientColors = isDark ? [const Color(0xFF231238), const Color(0xFF341952)] : [const Color(0xFF3D2619), const Color(0xFF2C1A10)];
        borderColor = isDark ? const Color(0xFFA855F7).withValues(alpha: 0.45) : const Color(0xFFB45309);
        textColor = isDark ? const Color(0xFFE9D5FF) : const Color(0xFFFAF6EF);
        break;
      case NotificationTone.outlineJump:
        gradientColors = isDark ? [const Color(0xFF1D1236), const Color(0xFF2A184D)] : [const Color(0xFFF3EEFF), const Color(0xFFE9E0FF)];
        borderColor = isDark ? const Color(0xFFA855F7).withValues(alpha: 0.45) : const Color(0xFF8B5CF6).withValues(alpha: 0.30);
        textColor = isDark ? const Color(0xFFDDD6FE) : const Color(0xFF4C1D95);
        break;
      case NotificationTone.quoteSaved:
        gradientColors = isDark ? [const Color(0xFF0D291E), const Color(0xFF143D2D)] : [const Color(0xFFEAF5EE), const Color(0xFFDFEFE4)];
        borderColor = isDark ? const Color(0xFF34D399).withValues(alpha: 0.45) : const Color(0xFF22C55E).withValues(alpha: 0.30);
        textColor = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF14532D);
        break;
      case NotificationTone.destructiveRemove:
        gradientColors = isDark ? [const Color(0xFF321111), const Color(0xFF481616)] : [const Color(0xFFFDECE9), const Color(0xFFFADBD6)];
        borderColor = isDark ? const Color(0xFFF87171).withValues(alpha: 0.45) : const Color(0xFFEF4444).withValues(alpha: 0.30);
        textColor = isDark ? const Color(0xFFFECACA) : const Color(0xFF7F1D1D);
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: borderColor.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Leading Icon Avatar
              IconTheme(
                data: IconThemeData(color: textColor, size: 24),
                child: leadingIcon,
              ),
              const SizedBox(width: 12),
              
              // Text Content
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                    height: 1.3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Trailing Action
              if (isToast && checkPillColor != null)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: checkPillColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                )
              else if (!isToast)
                InkWell(
                  onTap: onDismiss,
                  customBorder: const CircleBorder(),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.close_rounded, color: textColor.withValues(alpha: 0.6), size: 18),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
