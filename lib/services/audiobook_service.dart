import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/audiobook_model.dart';
import 'audiobook_audio_handler.dart';

class AudiobookService {
  static final AudiobookService _instance = AudiobookService._internal();
  factory AudiobookService() => _instance;

  AudiobookService._internal() {
    _initListeners();
  }

  StreamSubscription? _playbackSub;
  StreamSubscription? _positionSub;

  AudiobookModel? _currentAudiobook;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  double _speed = 1.0;

  final ValueNotifier<bool> isPlayingListenable = ValueNotifier<bool>(false);
  final ValueNotifier<Duration> positionListenable = ValueNotifier<Duration>(Duration.zero);

  AudiobookModel? get currentAudiobook => _currentAudiobook;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  double get speed => _speed;

  void _initListeners() {
    if (!isAudioHandlerReady) return;

    // Listen to audioHandler playback state
    audioHandler.playbackState.listen((state) {
      _isPlaying = state.playing;
      isPlayingListenable.value = _isPlaying;
      _currentPosition = state.position;
      positionListenable.value = _currentPosition;
    });

    audioHandler.player.positionStream.listen((pos) {
      _currentPosition = pos;
      positionListenable.value = pos;
      if (_currentAudiobook != null) {
        _currentAudiobook = _currentAudiobook!.copyWith(lastPosition: pos);
      }
    });

    audioHandler.player.speedStream.listen((spd) {
      _speed = spd;
    });
  }

  Future<void> loadAudiobook(AudiobookModel audiobook) async {
    _currentAudiobook = audiobook;
    _currentPosition = audiobook.lastPosition;
    _speed = audiobook.playbackSpeed;

    isPlayingListenable.value = false;
    positionListenable.value = _currentPosition;

    if (isAudioHandlerReady) {
      await audioHandler.loadAudiobook(audiobook);
    }
  }

  Future<void> play() async {
    if (_currentAudiobook == null) return;
    if (isAudioHandlerReady) await audioHandler.play();
  }

  Future<void> pause() async {
    if (isAudioHandlerReady) await audioHandler.pause();
  }

  Future<void> togglePlayPause() async {
    if (_isPlaying) {
      await pause();
    } else {
      await play();
    }
  }

  Future<void> seek(Duration position) async {
    if (_currentAudiobook == null) return;
    final clampedMs = position.inMilliseconds.clamp(0, _currentAudiobook!.totalDuration.inMilliseconds);
    _currentPosition = Duration(milliseconds: clampedMs);
    _currentAudiobook = _currentAudiobook!.copyWith(lastPosition: _currentPosition);
    positionListenable.value = _currentPosition;
    if (isAudioHandlerReady) await audioHandler.seek(_currentPosition);
  }

  void skipBackward15() {
    if (isAudioHandlerReady) audioHandler.skipBackward15();
  }

  void skipForward30() {
    if (isAudioHandlerReady) audioHandler.skipForward30();
  }

  Future<void> setSpeed(double speed) async {
    _speed = speed;
    if (_currentAudiobook != null) {
      _currentAudiobook = _currentAudiobook!.copyWith(playbackSpeed: speed);
    }
    if (isAudioHandlerReady) await audioHandler.setSpeed(speed);
  }

  void seekToChapter(AudioChapter chapter) {
    seek(chapter.startTimestamp);
  }

  void dispose() {
    _playbackSub?.cancel();
    _positionSub?.cancel();
    isPlayingListenable.dispose();
    positionListenable.dispose();
  }
}
