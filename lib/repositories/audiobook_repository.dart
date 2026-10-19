import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/audiobook_model.dart';
import '../services/audiobook_service.dart';

/// Single source of truth repository for Audiobook playback and audio handler coordination.
abstract class AudiobookRepository {
  ValueListenable<bool> get isPlayingListenable;
  ValueListenable<Duration> get positionListenable;
  AudiobookModel? get currentAudiobook;
  bool get isPlaying;
  Duration get currentPosition;
  double get speed;

  Future<void> loadAudiobook(AudiobookModel audiobook);
  Future<void> play();
  Future<void> pause();
  Future<void> togglePlayPause();
  Future<void> seek(Duration position);
  void skipBackward15();
  void skipForward30();
  void setSpeed(double speed);
  void seekToChapter(AudioChapter chapter);
}

/// Concrete implementation wrapping AudiobookService and background audio service.
class AudiobookRepositoryImpl implements AudiobookRepository {
  final AudiobookService _service;

  AudiobookRepositoryImpl({AudiobookService? service})
      : _service = service ?? AudiobookService();

  @override
  ValueListenable<bool> get isPlayingListenable => _service.isPlayingListenable;

  @override
  ValueListenable<Duration> get positionListenable => _service.positionListenable;

  @override
  AudiobookModel? get currentAudiobook => _service.currentAudiobook;

  @override
  bool get isPlaying => _service.isPlaying;

  @override
  Duration get currentPosition => _service.currentPosition;

  @override
  double get speed => _service.speed;

  @override
  Future<void> loadAudiobook(AudiobookModel audiobook) =>
      _service.loadAudiobook(audiobook);

  @override
  Future<void> play() => _service.play();

  @override
  Future<void> pause() => _service.pause();

  @override
  Future<void> togglePlayPause() => _service.togglePlayPause();

  @override
  Future<void> seek(Duration position) => _service.seek(position);

  @override
  void skipBackward15() => _service.skipBackward15();

  @override
  void skipForward30() => _service.skipForward30();

  @override
  void setSpeed(double speed) => _service.setSpeed(speed);

  @override
  void seekToChapter(AudioChapter chapter) => _service.seekToChapter(chapter);
}

/// Riverpod provider for AudiobookRepository
final audiobookRepositoryProvider = Provider<AudiobookRepository>((ref) {
  return AudiobookRepositoryImpl();
});
