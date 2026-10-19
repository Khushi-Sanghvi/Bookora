import 'package:flutter/material.dart';
import '../models/quote_annotation.dart';
import '../theme/reading_app_colors.dart';

class AddQuoteDialog extends StatefulWidget {
  final int initialPage;
  final Function(QuoteAnnotation quote) onSave;

  const AddQuoteDialog({
    super.key,
    required this.initialPage,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required int initialPage,
    required Function(QuoteAnnotation quote) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AddQuoteDialog(
        initialPage: initialPage,
        onSave: onSave,
      ),
    );
  }

  @override
  State<AddQuoteDialog> createState() => _AddQuoteDialogState();
}

class _AddQuoteDialogState extends State<AddQuoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _quoteController = TextEditingController();
  final _noteController = TextEditingController();
  late TextEditingController _pageController;
  String? _selectedTag;

  final List<Map<String, String>> _tags = [
    {'label': 'Favorite', 'emoji': '❤️'},
    {'label': 'Insightful', 'emoji': '💡'},
    {'label': 'Inspiring', 'emoji': '✨'},
    {'label': 'Emotional', 'emoji': '😭'},
    {'label': 'Funny', 'emoji': '😂'},
    {'label': 'Important', 'emoji': '📌'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = TextEditingController(
      text: widget.initialPage > 0 ? widget.initialPage.toString() : '',
    );
  }

  @override
  void dispose() {
    _quoteController.dispose();
    _noteController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      final pageNum = int.tryParse(_pageController.text) ?? widget.initialPage;
      String finalNote = _noteController.text.trim();
      if (_selectedTag != null && _selectedTag!.isNotEmpty) {
        finalNote = finalNote.isNotEmpty ? '[$_selectedTag] $finalNote' : '[$_selectedTag]';
      }

      final quote = QuoteAnnotation.create(
        quoteText: _quoteController.text.trim(),
        pageNumber: pageNum,
        note: finalNote.isNotEmpty ? finalNote : null,
      );

      widget.onSave(quote);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AlertDialog(
      backgroundColor: colors.cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.format_quote, color: colors.streakAmber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Add Quote & Annotation',
              style: TextStyle(color: colors.quoteGold, fontSize: 18, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _quoteController,
                maxLines: 3,
                style: TextStyle(color: colors.textPrimary, fontStyle: FontStyle.italic),
                decoration: InputDecoration(
                  hintText: 'Enter passage or quote text...',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  filled: true,
                  fillColor: colors.cardBgSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: colors.streakAmber)),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a quote or passage text';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pageController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Page Number',
                  labelStyle: TextStyle(color: colors.streakAmber),
                  prefixIcon: Icon(Icons.bookmark_border, color: colors.streakAmber),
                  filled: true,
                  fillColor: colors.cardBgSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter page number';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Please enter a valid integer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                maxLines: 2,
                style: TextStyle(color: colors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Personal note / reflection (optional)...',
                  hintStyle: TextStyle(color: colors.textSecondary),
                  prefixIcon: Icon(Icons.edit_note, color: colors.textSecondary),
                  filled: true,
                  fillColor: colors.cardBgSecondary,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              Text('Tag / Emotion:', style: TextStyle(color: colors.textSecondary, fontSize: 12)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _tags.map((tag) {
                  final label = '${tag['emoji']} ${tag['label']}';
                  final isSelected = _selectedTag == label;
                  return ChoiceChip(
                    label: Text(label, style: const TextStyle(fontSize: 11)),
                    selected: isSelected,
                    selectedColor: colors.streakAmber,
                    backgroundColor: colors.cardBgSecondary,
                    labelStyle: TextStyle(color: isSelected ? Colors.black : colors.textPrimary, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                    side: BorderSide(color: isSelected ? colors.streakAmber : colors.borderSubtle),
                    onSelected: (selected) {
                      setState(() {
                        _selectedTag = selected ? label : null;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.streakAmber,
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Save Quote', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
