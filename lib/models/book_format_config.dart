import 'enums.dart';

enum PaperbackTrackingMode { pages, chapters }
enum AudiobookTrackingMode { fileUpload, manualChapters }

class BookFormatConfig {
  final BookFormat format;
  final PaperbackTrackingMode paperbackMode;
  final AudiobookTrackingMode audiobookMode;
  final int totalPages;
  final int currentPage;
  final int totalChapters;
  final int currentChapter;
  final int currentAudioSeconds;
  final int totalAudioSeconds;
  final String? audioFilePath;
  final DateTime startDate;
  final DateTime? endDate;

  BookFormatConfig({
    required this.format,
    this.paperbackMode = PaperbackTrackingMode.pages,
    this.audiobookMode = AudiobookTrackingMode.manualChapters,
    this.totalPages = 300,
    this.currentPage = 0,
    this.totalChapters = 20,
    this.currentChapter = 0,
    this.currentAudioSeconds = 0,
    this.totalAudioSeconds = 0,
    this.audioFilePath,
    required this.startDate,
    this.endDate,
  });

  double get progressPercentage {
    if (format == BookFormat.audiobook) {
      if (audiobookMode == AudiobookTrackingMode.fileUpload) {
        return totalAudioSeconds > 0 ? (currentAudioSeconds / totalAudioSeconds).clamp(0.0, 1.0) : 0.0;
      } else {
        return totalChapters > 0 ? (currentChapter / totalChapters).clamp(0.0, 1.0) : 0.0;
      }
    } else {
      if (paperbackMode == PaperbackTrackingMode.chapters) {
        return totalChapters > 0 ? (currentChapter / totalChapters).clamp(0.0, 1.0) : 0.0;
      } else {
        return totalPages > 0 ? (currentPage / totalPages).clamp(0.0, 1.0) : 0.0;
      }
    }
  }

  bool get isFinished => endDate != null || progressPercentage >= 1.0;

  BookFormatConfig copyWith({
    BookFormat? format,
    PaperbackTrackingMode? paperbackMode,
    AudiobookTrackingMode? audiobookMode,
    int? totalPages,
    int? currentPage,
    int? totalChapters,
    int? currentChapter,
    int? currentAudioSeconds,
    int? totalAudioSeconds,
    String? audioFilePath,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return BookFormatConfig(
      format: format ?? this.format,
      paperbackMode: paperbackMode ?? this.paperbackMode,
      audiobookMode: audiobookMode ?? this.audiobookMode,
      totalPages: totalPages ?? this.totalPages,
      currentPage: currentPage ?? this.currentPage,
      totalChapters: totalChapters ?? this.totalChapters,
      currentChapter: currentChapter ?? this.currentChapter,
      currentAudioSeconds: currentAudioSeconds ?? this.currentAudioSeconds,
      totalAudioSeconds: totalAudioSeconds ?? this.totalAudioSeconds,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }
}
