import 'package:uuid/uuid.dart';

class QuoteAnnotation {
  final String id;
  final String quoteText;
  final int pageNumber;
  final String? note;
  final DateTime createdAt;

  QuoteAnnotation({
    required this.id,
    required this.quoteText,
    required this.pageNumber,
    this.note,
    required this.createdAt,
  });

  factory QuoteAnnotation.create({
    required String quoteText,
    required int pageNumber,
    String? note,
  }) {
    return QuoteAnnotation(
      id: const Uuid().v4(),
      quoteText: quoteText,
      pageNumber: pageNumber,
      note: note,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'quoteText': quoteText,
      'pageNumber': pageNumber,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory QuoteAnnotation.fromMap(Map<String, dynamic> map) {
    return QuoteAnnotation(
      id: map['id']?.toString() ?? const Uuid().v4(),
      quoteText: map['quoteText']?.toString() ?? '',
      pageNumber: (map['pageNumber'] is num)
          ? (map['pageNumber'] as num).toInt()
          : int.tryParse(map['pageNumber']?.toString() ?? '') ?? 0,
      note: map['note']?.toString(),
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}
