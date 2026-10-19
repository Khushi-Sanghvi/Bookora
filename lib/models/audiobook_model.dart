import '../models/book.dart';

class AudioChapter {
  final int chapterIndex;
  final String title;
  final Duration startTimestamp;
  final Duration endTimestamp;

  AudioChapter({
    required this.chapterIndex,
    required this.title,
    required this.startTimestamp,
    required this.endTimestamp,
  });

  Duration get duration => endTimestamp - startTimestamp;

  static String formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  Map<String, dynamic> toMap() {
    return {
      'chapterIndex': chapterIndex,
      'title': title,
      'startTimestampMs': startTimestamp.inMilliseconds,
      'endTimestampMs': endTimestamp.inMilliseconds,
    };
  }

  factory AudioChapter.fromMap(Map<String, dynamic> map) {
    return AudioChapter(
      chapterIndex: map['chapterIndex'] ?? 0,
      title: map['title'] ?? 'Chapter',
      startTimestamp: Duration(milliseconds: map['startTimestampMs'] ?? 0),
      endTimestamp: Duration(milliseconds: map['endTimestampMs'] ?? 0),
    );
  }
}

class AudiobookModel {
  final String bookId;
  final String title;
  final String author;
  final String coverUrl;
  final String? audioFilePath;
  final Duration totalDuration;
  final Duration lastPosition;
  final double playbackSpeed;
  final List<AudioChapter> chapters;

  AudiobookModel({
    required this.bookId,
    required this.title,
    required this.author,
    required this.coverUrl,
    this.audioFilePath,
    required this.totalDuration,
    this.lastPosition = Duration.zero,
    this.playbackSpeed = 1.0,
    this.chapters = const [],
  });

  AudioChapter? getChapterForPosition(Duration position) {
    if (chapters.isEmpty) return null;
    for (var ch in chapters) {
      if (position >= ch.startTimestamp && position < ch.endTimestamp) {
        return ch;
      }
    }
    return chapters.last;
  }

  double get progressPercentage {
    if (totalDuration.inMilliseconds == 0) return 0.0;
    return (lastPosition.inMilliseconds / totalDuration.inMilliseconds).clamp(0.0, 1.0);
  }

  int getEquivalentPage(int totalBookPages) {
    final total = totalBookPages > 0 ? totalBookPages : 300;
    return (progressPercentage * total).round().clamp(0, total);
  }

  AudiobookModel copyWith({
    String? bookId,
    String? title,
    String? author,
    String? coverUrl,
    String? audioFilePath,
    Duration? totalDuration,
    Duration? lastPosition,
    double? playbackSpeed,
    List<AudioChapter>? chapters,
  }) {
    return AudiobookModel(
      bookId: bookId ?? this.bookId,
      title: title ?? this.title,
      author: author ?? this.author,
      coverUrl: coverUrl ?? this.coverUrl,
      audioFilePath: audioFilePath ?? this.audioFilePath,
      totalDuration: totalDuration ?? this.totalDuration,
      lastPosition: lastPosition ?? this.lastPosition,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      chapters: chapters ?? this.chapters,
    );
  }

  factory AudiobookModel.fromBook(
    Book book, {
    String? audioPath,
    Duration? overrideDuration,
  }) {
    // Generate ~10-25 chapters based on book length or defaults
    final totalHours = (book.totalPages / 35.0).clamp(2.0, 18.0);
    final duration = overrideDuration ?? Duration(seconds: (totalHours * 3600).round());
    final chapterCount = (book.totalPages / 20.0).ceil().clamp(6, 24);

    final List<AudioChapter> generatedChapters = [];
    final chunkMs = (duration.inMilliseconds / chapterCount).round();

    for (int i = 0; i < chapterCount; i++) {
      final startMs = i * chunkMs;
      final endMs = (i == chapterCount - 1) ? duration.inMilliseconds : (i + 1) * chunkMs;

      String chapterTitle = 'Chapter ${i + 1}';
      if (i == 0) chapterTitle = 'Prologue / Chapter 1';
      if (i == chapterCount - 1) chapterTitle = 'Epilogue / Final Chapter';

      generatedChapters.add(AudioChapter(
        chapterIndex: i,
        title: chapterTitle,
        startTimestamp: Duration(milliseconds: startMs),
        endTimestamp: Duration(milliseconds: endMs),
      ));
    }

    // Estimate initial position from book.currentPage
    final initialMs = book.totalPages > 0
        ? ((book.currentPage / book.totalPages) * duration.inMilliseconds).round()
        : 0;

    return AudiobookModel(
      bookId: book.id,
      title: book.title,
      author: book.author,
      coverUrl: book.coverUrl,
      audioFilePath: audioPath ?? book.localFilePath,
      totalDuration: duration,
      lastPosition: Duration(milliseconds: initialMs.clamp(0, duration.inMilliseconds)),
      playbackSpeed: 1.0,
      chapters: generatedChapters,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bookId': bookId,
      'title': title,
      'author': author,
      'coverUrl': coverUrl,
      'audioFilePath': audioFilePath,
      'totalDurationMs': totalDuration.inMilliseconds,
      'lastPositionMs': lastPosition.inMilliseconds,
      'playbackSpeed': playbackSpeed,
      'chapters': chapters.map((c) => c.toMap()).toList(),
    };
  }

  factory AudiobookModel.fromMap(Map<String, dynamic> map) {
    final List<dynamic> chList = map['chapters'] ?? [];
    return AudiobookModel(
      bookId: map['bookId'] ?? '',
      title: map['title'] ?? '',
      author: map['author'] ?? '',
      coverUrl: map['coverUrl'] ?? '',
      audioFilePath: map['audioFilePath'],
      totalDuration: Duration(milliseconds: map['totalDurationMs'] ?? 0),
      lastPosition: Duration(milliseconds: map['lastPositionMs'] ?? 0),
      playbackSpeed: (map['playbackSpeed'] ?? 1.0).toDouble(),
      chapters: chList.map((c) => AudioChapter.fromMap(Map<String, dynamic>.from(c))).toList(),
    );
  }
}
