import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/book.dart';
import '../models/enums.dart';
import '../models/journal_entry.dart';
import '../providers/book_provider.dart';
import '../theme/reading_app_colors.dart';

class LogProgressDialog extends ConsumerStatefulWidget {
  final Book book;

  const LogProgressDialog({super.key, required this.book});

  static Future<void> show(BuildContext context, {required Book book}) {
    return showDialog(
      context: context,
      builder: (context) => LogProgressDialog(book: book),
    );
  }

  @override
  ConsumerState<LogProgressDialog> createState() => _LogProgressDialogState();
}

class _LogProgressDialogState extends ConsumerState<LogProgressDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _pageController;
  final _reflectionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _pageController = TextEditingController(
      text: widget.book.currentPage > 0 ? widget.book.currentPage.toString() : '',
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _reflectionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;

    setState(() => _isSaving = true);
    final book = widget.book;
    final int updatedPage = int.tryParse(_pageController.text.trim()) ?? book.currentPage;
    final delta = max(0, updatedPage - book.currentPage);

    try {
      if (updatedPage >= book.totalPages && book.totalPages > 0) {
        await ref.read(booksProvider.notifier).markBookCompleted(bookId: book.id);
      } else {
        final updatedBook = book.copyWith(
          currentPage: updatedPage,
          status: updatedPage > 0 ? ReadingStatus.currentlyReading : book.status,
          startDate: book.startDate ?? (updatedPage > 0 ? DateTime.now() : null),
        );
        ref.read(bookProvider.notifier).updateBook(updatedBook);
      }

      if (delta > 0) {
        final note = _reflectionController.text.trim();
        ref.read(bookProvider.notifier).addJournalEntry(
              book.id,
              JournalEntry.create(delta, reflection: note.isNotEmpty ? note : null),
            );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Dialog(
      backgroundColor: colors.cardBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: colors.borderSubtle),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.streakAmber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.menu_book_rounded, color: colors.streakAmber, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Log Reading Progress',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Current Page (out of ${widget.book.totalPages})',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _pageController,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: TextStyle(color: colors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. 145',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: colors.cardBgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.streakAmber),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a page number';
                  }
                  final p = int.tryParse(val.trim());
                  if (p == null || p < 0) {
                    return 'Please enter a valid page number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              Text(
                'Reflection or Notes (Optional)',
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reflectionController,
                maxLines: 2,
                style: TextStyle(color: colors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'What did you think of today\'s pages?',
                  hintStyle: TextStyle(color: colors.textSecondary.withValues(alpha: 0.5)),
                  filled: true,
                  fillColor: colors.cardBgSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.borderSubtle),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.borderSubtle),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: colors.streakAmber),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: Text('Cancel', style: TextStyle(color: colors.textSecondary)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.streakAmber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('Save Progress', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
