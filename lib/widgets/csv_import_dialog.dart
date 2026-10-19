import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../providers/book_provider.dart';
import '../repositories/user_settings_repository.dart';
import 'bookora_floral_dialog.dart';
import 'bookora_snack_bar.dart';

class CsvImportDialog extends ConsumerStatefulWidget {
  const CsvImportDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const CsvImportDialog(),
    );
  }

  @override
  ConsumerState<CsvImportDialog> createState() => _CsvImportDialogState();
}

class _CsvImportDialogState extends ConsumerState<CsvImportDialog> {
  bool _isLoading = false;
  File? _selectedCsvFile;
  List<String> _headers = ['Title', 'Author', 'Genres', 'Number of Pages', 'Default / Auto'];
  String _titleColumn = 'Default / Auto';
  String _authorColumn = 'Default / Auto';
  String _genreColumn = 'Default / Auto';
  String _pagesColumn = 'Default / Auto';

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'txt'],
    );
    if (result != null && result.files.isNotEmpty && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      try {
        final text = await file.readAsString();
        final lines = text.split('\n');
        if (lines.isNotEmpty) {
          final firstLine = lines.first;
          final cols = firstLine.split(',').map((c) => c.replaceAll('"', '').trim()).where((c) => c.isNotEmpty).toList();
          if (cols.isNotEmpty) {
            setState(() {
              _selectedCsvFile = file;
              _headers = ['Default / Auto', ...cols];
            });
            return;
          }
        }
      } catch (_) {}
      setState(() {
        _selectedCsvFile = file;
      });
    }
  }

  Future<void> _processImport() async {
    if (_selectedCsvFile == null) {
      await _pickFile();
      if (_selectedCsvFile == null) return;
    }

    setState(() => _isLoading = true);
    try {
      final text = await _selectedCsvFile!.readAsString();
      final books = ref.read(userSettingsRepositoryProvider).parseCsv(
        text,
        titleCol: _titleColumn == 'Default / Auto' ? null : _titleColumn,
        authorCol: _authorColumn == 'Default / Auto' ? null : _authorColumn,
        genreCol: _genreColumn == 'Default / Auto' ? null : _genreColumn,
        pagesCol: _pagesColumn == 'Default / Auto' ? null : _pagesColumn,
      );

      if (books.isNotEmpty) {
        await ref.read(bookProvider.notifier).addBooks(books);

        if (mounted) {
          Navigator.pop(context);
          BookoraSnackBar.show(
            context,
            type: BookoraSnackBarType.success,
            title: 'Success! ${books.length} books restored',
            subtitle: 'into your library.',
          );
        }
      } else {
        setState(() => _isLoading = false);
        if (mounted) {
          BookoraSnackBar.show(
            context,
            type: BookoraSnackBarType.error,
            title: 'Error restoring database:',
            subtitle: 'No valid book records discovered in selected CSV file.',
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        BookoraSnackBar.show(
          context,
          type: BookoraSnackBarType.error,
          title: 'Error importing CSV:',
          subtitle: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BookoraFloralDialog(
      headerIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100)).withValues(alpha: 0.15),
          border: Border.all(
            color: (isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100)).withValues(alpha: 0.4),
            width: 1.2,
          ),
        ),
        child: Icon(
          Icons.table_chart_rounded,
          color: isDark ? const Color(0xFFFFB300) : const Color(0xFFE65100),
          size: 24,
        ),
      ),
      title: 'Import from CSV',
      subtitle: 'Map your columns to import books\n(from Goodreads, StoryGraph, etc.)',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selected file status pill
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF181C24) : const Color(0xFFF7F2E8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF2A3442) : const Color(0xFFE6DFC8),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.attach_file_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFFFFB300) : const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _selectedCsvFile != null
                          ? _selectedCsvFile!.path.split(Platform.pathSeparator).last
                          : 'Choose CSV file to inspect columns...',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    _selectedCsvFile != null ? 'Change' : 'Browse',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFFB300) : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Column Mapping Dropdowns
          _buildColumnDropdownRow('Title', _titleColumn, (val) => setState(() => _titleColumn = val)),
          const SizedBox(height: 8),
          _buildColumnDropdownRow('Author', _authorColumn, (val) => setState(() => _authorColumn = val)),
          const SizedBox(height: 8),
          _buildColumnDropdownRow('Genres', _genreColumn, (val) => setState(() => _genreColumn = val)),
          const SizedBox(height: 8),
          _buildColumnDropdownRow('Pages', _pagesColumn, (val) => setState(() => _pagesColumn = val)),
        ],
      ),
      actions: [
        BookoraPillButton.outlined(
          text: 'Cancel',
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 8),
        BookoraPillButton.primary(
          text: 'Import',
          isLoading: _isLoading,
          onPressed: _processImport,
        ),
      ],
    );
  }

  Widget _buildColumnDropdownRow(String label, String value, ValueChanged<String> onChanged) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? const Color(0xFFEFE8DC) : const Color(0xFF2E1E12);
    final labelColor = isDark ? const Color(0xFFFFA726) : const Color(0xFF8D6E63);
    final fieldBg = isDark ? const Color(0xFF181C24) : const Color(0xFFF7F2E8);
    final borderColor = isDark ? const Color(0xFF2A3442) : const Color(0xFFE6DFC8);

    final dropdownItems = _headers.toSet().toList();
    final effectiveValue = dropdownItems.contains(value) ? value : dropdownItems.first;

    return Row(
      children: [
        SizedBox(
          width: 58,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: fieldBg,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: borderColor, width: 1.1),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: effectiveValue,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF181C24) : const Color(0xFFFFFDF8),
                icon: Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: labelColor,
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: textColor,
                ),
                items: dropdownItems.map((col) {
                  return DropdownMenuItem<String>(
                    value: col,
                    child: Text(col, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                onChanged: (newVal) {
                  if (newVal != null) onChanged(newVal);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
