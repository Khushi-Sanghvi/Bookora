import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audiobook_model.dart';
import '../models/book.dart';
import '../models/journal_entry.dart';
import '../repositories/audiobook_repository.dart';
import 'book_provider.dart';

export '../repositories/audiobook_repository.dart'
    show audiobookRepositoryProvider, AudiobookRepository, AudiobookRepositoryImpl;

class AudiobookPlayerState {
  final AudiobookModel? currentAudiobook;
  final bool isPlaying;
  final Duration currentPosition;
  final Duration totalDuration;
  final double playbackSpeed;
  final bool isMiniPlayerVisible;

  const AudiobookPlayerState({
    this.currentAudiobook,
    this.isPlaying = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.playbackSpeed = 1.0,
    this.isMiniPlayerVisible = false,
  });

  AudioChapter? get activeChapter => currentAudiobook?.getChapterForPosition(currentPosition);

  double get progressPercentage => currentAudiobook != null ? currentAudiobook!.progressPercentage : 0.0;

  AudiobookPlayerState copyWith({
    AudiobookModel? currentAudiobook,
    bool? isPlaying,
    Duration? currentPosition,
    Duration? totalDuration,
    double? playbackSpeed,
    bool? isMiniPlayerVisible,
  }) {
    return AudiobookPlayerState(
      currentAudiobook: currentAudiobook ?? this.currentAudiobook,
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      isMiniPlayerVisible: isMiniPlayerVisible ?? this.isMiniPlayerVisible,
    );
  }
}

class AudiobookPlayerNotifier extends StateNotifier<AudiobookPlayerState> {
  final AudiobookRepository _repository;
  final Ref _ref;

  AudiobookPlayerNotifier(this._ref, [AudiobookRepository? repository])
      : _repository = repository ?? AudiobookRepositoryImpl(),
        super(const AudiobookPlayerState()) {
    _repository.positionListenable.addListener(_onPositionChanged);
    _repository.isPlayingListenable.addListener(_onPlayingStateChanged);
  }

  void _onPositionChanged() {
    if (_repository.currentAudiobook != null) {
      final ab = _repository.currentAudiobook!;
      final newPos = _repository.currentPosition;
      final duration = ab.totalDuration;

      state = state.copyWith(
        currentAudiobook: ab,
        currentPosition: newPos,
        totalDuration: duration,
      );

      if (duration > Duration.zero && newPos >= duration - const Duration(seconds: 1)) {
        _ref.read(booksProvider.notifier).markBookCompleted(bookId: ab.bookId);
      } else {
        _syncBookProgressWithRiverpod(ab, newPos);
      }
    }
  }

  void _onPlayingStateChanged() {
    state = state.copyWith(isPlaying: _repository.isPlayingListenable.value);
  }

  void loadAndPlay(Book book, {String? audioPath, Duration? overrideDuration}) {
    final ab = AudiobookModel.fromBook(book, audioPath: audioPath, overrideDuration: overrideDuration);
    _repository.loadAudiobook(ab);

    state = AudiobookPlayerState(
      currentAudiobook: ab,
      isPlaying: false,
      currentPosition: ab.lastPosition,
      totalDuration: ab.totalDuration,
      playbackSpeed: ab.playbackSpeed,
      isMiniPlayerVisible: true,
    );

    _repository.play();
  }

  void togglePlayPause() => _repository.togglePlayPause();
  void seek(Duration pos) => _repository.seek(pos);
  void skipBackward15() => _repository.skipBackward15();
  void skipForward30() => _repository.skipForward30();
  void setSpeed(double speed) => _repository.setSpeed(speed);
  void seekToChapter(AudioChapter chapter) => _repository.seekToChapter(chapter);

  void hideMiniPlayer() {
    _repository.pause();
    state = state.copyWith(isMiniPlayerVisible: false);
  }

  void stopAndClear() {
    _repository.pause();
    state = const AudiobookPlayerState(
      currentAudiobook: null,
      isPlaying: false,
      currentPosition: Duration.zero,
      totalDuration: Duration.zero,
      isMiniPlayerVisible: false,
    );
  }

  void _syncBookProgressWithRiverpod(AudiobookModel ab, Duration currentPos) {
    final bookState = _ref.read(bookProvider);
    bookState.whenData((books) {
      final matchingBook = books.firstWhere((b) => b.id == ab.bookId, orElse: () => Book(
        id: ab.bookId,
        title: ab.title,
        author: ab.author,
        description: '',
        coverUrl: ab.coverUrl,
        totalPages: 300,
      ));

      final equivPage = ab.getEquivalentPage(matchingBook.totalPages);
      if (equivPage != matchingBook.currentPage && equivPage > 0) {
        final updated = matchingBook.copyWith(currentPage: equivPage);
        _ref.read(bookProvider.notifier).updateBook(updated);

        final delta = equivPage - matchingBook.currentPage;
        if (delta > 0) {
          _ref.read(bookProvider.notifier).addJournalEntry(
            matchingBook.id,
            JournalEntry.create(delta, reflection: 'Listened to ${ab.title}'),
          );
        }
      }
    });
  }

  @override
  void dispose() {
    _repository.positionListenable.removeListener(_onPositionChanged);
    _repository.isPlayingListenable.removeListener(_onPlayingStateChanged);
    super.dispose();
  }
}

final audiobookPlayerProvider = StateNotifierProvider<AudiobookPlayerNotifier, AudiobookPlayerState>((ref) {
  final repository = ref.watch(audiobookRepositoryProvider);
  return AudiobookPlayerNotifier(ref, repository);
});
