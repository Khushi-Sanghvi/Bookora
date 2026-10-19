import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../theme/reading_app_colors.dart';

class BookMetadataSummaryBar extends StatelessWidget {
  final Book book;
  final VoidCallback? onTapStartDate;
  final VoidCallback? onTapEndDate;

  const BookMetadataSummaryBar({
    super.key,
    required this.book,
    this.onTapStartDate,
    this.onTapEndDate,
  });

  String _getFormatName(BookFormat format) {
    switch (format) {
      case BookFormat.paperback:
        return 'Paperback';
      case BookFormat.hardcover:
        return 'Hardcover';
      case BookFormat.ebook:
        return 'eBook';
      case BookFormat.audiobook:
        return 'Audiobook';
      case BookFormat.pdf:
        return 'PDF';
      case BookFormat.epub:
        return 'EPUB';
    }
  }

  IconData _getFormatIcon(BookFormat format) {
    switch (format) {
      case BookFormat.paperback:
      case BookFormat.hardcover:
        return Icons.menu_book_outlined;
      case BookFormat.ebook:
      case BookFormat.epub:
        return Icons.phone_android_outlined;
      case BookFormat.audiobook:
        return Icons.headphones_outlined;
      case BookFormat.pdf:
        return Icons.picture_as_pdf_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final totalPages = book.totalPages > 0 ? book.totalPages : 300;

    // Start date is only shown if explicitly set or if book is Currently Reading / Finished
    final showStartDate = book.startDate != null ||
        book.status == ReadingStatus.currentlyReading ||
        book.status == ReadingStatus.finished;

    final startDateStr = showStartDate
        ? DateFormat('MMM d, yyyy').format(book.startDate ?? DateTime.now())
        : '-';

    final finishDateValue = book.endDate ?? book.finishDate;
    final endDateStr = finishDateValue != null
        ? DateFormat('MMM d, yyyy').format(finishDateValue)
        : '-';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: colors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.borderSubtle),
      ),
      child: Row(
        children: [
          // 1. Format
          Expanded(
            child: _buildItem(
              context: context,
              icon: _getFormatIcon(book.format),
              label: 'Format',
              value: _getFormatName(book.format),
              colors: colors,
            ),
          ),
          _buildDivider(colors),

          // 2. Total Pages
          Expanded(
            child: _buildItem(
              context: context,
              icon: Icons.article_outlined,
              label: 'Total Pages',
              value: '$totalPages Pages',
              colors: colors,
            ),
          ),
          _buildDivider(colors),

          // 3. Start Date
          Expanded(
            child: _buildItem(
              context: context,
              icon: Icons.calendar_today_outlined,
              label: 'Start Date',
              value: startDateStr,
              colors: colors,
              onTap: onTapStartDate,
            ),
          ),
          _buildDivider(colors),

          // 4. End Date
          Expanded(
            child: _buildItem(
              context: context,
              icon: Icons.event_available_outlined,
              label: 'End Date',
              value: endDateStr,
              colors: colors,
              onTap: onTapEndDate,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(ReadingAppColors colors) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      color: colors.borderSubtle,
    );
  }

  Widget _buildItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
    required ReadingAppColors colors,
    VoidCallback? onTap,
  }) {
    final Widget content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: colors.streakAmber),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 11,
            color: colors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: content,
        ),
      );
    }
    return content;
  }
}
