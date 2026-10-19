import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import '../models/audiobook_model.dart';
import '../models/book.dart';
import '../providers/book_provider.dart';
import 'database_service.dart';
import 'reading_status_resolver.dart';

class AudioPlayerHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  AudiobookModel? _currentAudiobook;
  dynamic _ref;

  AudioPlayerHandler() {
    _init();
  }

  void setRef(dynamic ref) {
    _ref = ref;
  }

  void _init() {
    // Broadcast playback state changes
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Monitor position and duration
    _player.positionStream.listen((position) {
      if (_currentAudiobook != null) {
        _currentAudiobook = _currentAudiobook!.copyWith(lastPosition: position);
        final duration = _player.duration ?? _currentAudiobook!.totalDuration;
        if (duration > Duration.zero && position >= duration - const Duration(seconds: 1)) {
          _handleBookFinished();
        } else {
          _syncProgressToDatabaseAndRiverpod(position);
        }
      }
    });

    _player.durationStream.listen((duration) {
      if (duration != null && _currentAudiobook != null && duration > Duration.zero) {
        _currentAudiobook = _currentAudiobook!.copyWith(totalDuration: duration);
        mediaItem.add(mediaItem.value?.copyWith(duration: duration));
      }
    });

    // Handle playback completion (Auto-Finish)
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _handleBookFinished();
      }
    });
  }

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.rewind,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.fastForward,
        MediaControl.stop,
      ],
      systemActions: {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 2],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  Future<void> loadAudiobook(AudiobookModel audiobook) async {
    _currentAudiobook = audiobook;

    // Update notification media item
    mediaItem.add(MediaItem(
      id: audiobook.bookId,
      album: audiobook.author,
      title: audiobook.title,
      artist: audiobook.author,
      duration: audiobook.totalDuration,
      artUri: audiobook.coverUrl.isNotEmpty ? Uri.parse(audiobook.coverUrl) : null,
    ));

    final path = audiobook.audioFilePath;
    if (path != null && path.trim().isNotEmpty && File(path).existsSync()) {
      try {
        await _player.setFilePath(path);
        await _player.setSpeed(audiobook.playbackSpeed);
        if (audiobook.lastPosition > Duration.zero) {
          await _player.seek(audiobook.lastPosition);
        }
      } catch (e) {
        // Fallback simulation or error handling
      }
    }
  }

  @override
  Future<void> play() async {
    if (_currentAudiobook != null && _ref != null) {
      _handleBookStarted();
    }
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    if (_currentAudiobook != null) {
      _currentAudiobook = _currentAudiobook!.copyWith(playbackSpeed: speed);
    }
  }

  Future<void> skipBackward15() async {
    final newPos = _player.position - const Duration(seconds: 15);
    await seek(newPos < Duration.zero ? Duration.zero : newPos);
  }

  Future<void> skipForward30() async {
    final dur = _player.duration ?? (_currentAudiobook?.totalDuration ?? Duration.zero);
    final newPos = _player.position + const Duration(seconds: 30);
    await seek(newPos > dur ? dur : newPos);
  }

  void _handleBookStarted() async {
    if (_currentAudiobook == null || _ref == null) return;
    final booksState = _ref!.read(bookProvider);
    final List<Book> books = booksState.value ?? [];
    if (books.isNotEmpty) {
      final matching = books.firstWhere(
        (b) => b.id == _currentAudiobook!.bookId,
        orElse: () => Book(
          id: _currentAudiobook!.bookId,
          title: _currentAudiobook!.title,
          author: _currentAudiobook!.author,
          description: '',
          coverUrl: _currentAudiobook!.coverUrl,
          totalPages: 300,
        ),
      );

      final transition = ReadingStatusResolver.evaluateStatusTransition(
        currentStatus: matching.status,
        currentPage: matching.currentPage > 0 ? matching.currentPage : 1,
        totalPages: matching.totalPages > 0 ? matching.totalPages : 300,
        existingStartDate: matching.startDate,
        existingFinishDate: matching.finishDate,
      );

      final updated = matching.copyWith(
        status: transition.status,
        startDate: transition.startDate,
        finishDate: transition.finishDate,
      );

      DatabaseService().updateBook(updated);
      _ref!.read(bookProvider.notifier).updateBook(updated);
    }
  }

  void _handleBookFinished() async {
    if (_currentAudiobook == null || _ref == null) return;
    await _ref!.read(booksProvider.notifier).markBookCompleted(
      bookId: _currentAudiobook!.bookId,
    );
  }

  void _syncProgressToDatabaseAndRiverpod(Duration position) {
    if (_currentAudiobook == null || _ref == null) return;
    final ab = _currentAudiobook!;

    final booksState = _ref!.read(bookProvider);
    final List<Book> books = booksState.value ?? [];
    if (books.isNotEmpty) {
      final matching = books.firstWhere(
        (b) => b.id == ab.bookId,
        orElse: () => Book(
          id: ab.bookId,
          title: ab.title,
          author: ab.author,
          description: '',
          coverUrl: ab.coverUrl,
          totalPages: 300,
        ),
      );

      final page = ab.getEquivalentPage(matching.totalPages > 0 ? matching.totalPages : 300);
      if (page != matching.currentPage) {
        final transition = ReadingStatusResolver.evaluateStatusTransition(
          currentStatus: matching.status,
          currentPage: page,
          totalPages: matching.totalPages > 0 ? matching.totalPages : 300,
          existingStartDate: matching.startDate,
          existingFinishDate: matching.finishDate,
        );

        final updated = matching.currentPage == page ? matching : matching.copyWith(
          currentPage: page,
          status: transition.status,
          startDate: transition.startDate,
          finishDate: transition.finishDate,
        );

        if (updated != matching) {
          DatabaseService().updateBook(updated);
          _ref!.read(bookProvider.notifier).updateBook(updated);
        }
      }
    }
  }

  AudioPlayer get player => _player;
}

late AudioPlayerHandler audioHandler;

bool get isAudioHandlerReady {
  try {
    audioHandler;
    return true;
  } catch (_) {
    return false;
  }
}

Future<void> initAudioService() async {
  try {
    audioHandler = await AudioService.init(
      builder: () => AudioPlayerHandler(),
      config: const AudioServiceConfig(
        androidNotificationChannelId: 'com.example.between_world.audio',
        androidNotificationChannelName: 'Bookora Audiobooks',
        androidNotificationOngoing: true,
        androidStopForegroundOnPause: true,
      ),
    );
  } catch (e) {
    debugPrint('AudioService init fallback: $e');
  }
}
