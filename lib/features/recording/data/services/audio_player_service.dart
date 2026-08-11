import 'dart:async';
import 'package:audioplayers/audioplayers.dart';

class AudioPlayerService {
  AudioPlayer? _audioPlayer;

  AudioPlayer _ensurePlayer() {
    _audioPlayer ??= AudioPlayer();
    return _audioPlayer!;
  }

  Stream<Duration> get positionStream => _ensurePlayer().onPositionChanged;
  Stream<Duration> get durationStream => _ensurePlayer().onDurationChanged;
  Stream<PlayerState> get stateStream => _ensurePlayer().onPlayerStateChanged;

  Future<void> play(String path) async {
    final player = _ensurePlayer();
    await player.stop();
    await player.play(DeviceFileSource(path));
  }

  Future<void> pause() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.pause();
    }
  }

  Future<void> resume() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.resume();
    }
  }

  Future<void> stop() async {
    if (_audioPlayer != null) {
      await _audioPlayer!.stop();
    }
  }

  Future<void> seek(Duration duration) async {
    if (_audioPlayer != null) {
      await _audioPlayer!.seek(duration);
    }
  }

  Future<void> dispose() async {
    if (_audioPlayer != null) {
      try {
        await _audioPlayer!.dispose();
      } catch (_) {}
      _audioPlayer = null;
    }
  }
}
