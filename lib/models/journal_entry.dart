import 'package:uuid/uuid.dart';

class JournalEntry {
  final String id;
  final DateTime date;
  final int pagesRead;
  final String? reflection;

  JournalEntry({
    required this.id,
    required this.date,
    required this.pagesRead,
    this.reflection,
  });

  factory JournalEntry.create(int pagesRead, {String? reflection}) {
    return JournalEntry(
      id: const Uuid().v4(),
      date: DateTime.now(),
      pagesRead: pagesRead,
      reflection: reflection,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'pagesRead': pagesRead,
      'reflection': reflection,
    };
  }

  factory JournalEntry.fromMap(Map<String, dynamic> map) {
    return JournalEntry(
      id: map['id']?.toString() ?? const Uuid().v4(),
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      pagesRead: (map['pagesRead'] is num)
          ? (map['pagesRead'] as num).toInt()
          : int.tryParse(map['pagesRead']?.toString() ?? '') ?? 0,
      reflection: map['reflection']?.toString(),
    );
  }
}
