import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditableDateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onDateChanged;
  final bool isOptional;
  final IconData icon;
  final DateTime? minDate;
  final DateTime? maxDate;

  const EditableDateTile({
    super.key,
    required this.label,
    required this.date,
    required this.onDateChanged,
    this.isOptional = false,
    this.icon = Icons.calendar_today,
    this.minDate,
    this.maxDate,
  });

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = date ?? now;
    final first = minDate ?? DateTime(2000);
    final last = maxDate ?? DateTime(2100);

    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(first) ? first : (initial.isAfter(last) ? last : initial),
      firstDate: first,
      lastDate: last,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE07A38),
              onPrimary: Colors.black,
              surface: Color(0xFF1E1F24),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onDateChanged(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedText = date != null
        ? DateFormat('d MMM, yyyy').format(date!)
        : (isOptional ? 'Not finished yet' : 'Set date');

    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1F24),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: date != null ? const Color(0xFFE07A38).withValues(alpha: 0.5) : Colors.white10,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: date != null ? const Color(0xFFE07A38) : Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedText,
                    style: TextStyle(
                      color: date != null ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (isOptional && date != null)
              IconButton(
                icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                tooltip: 'Reset to Not Finished',
                onPressed: () => onDateChanged(null),
              )
            else
              const Icon(Icons.edit_calendar, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
