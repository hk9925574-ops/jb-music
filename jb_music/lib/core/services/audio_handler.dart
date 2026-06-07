import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler {
  final AudioPlayer _player = AudioPlayer();

  // Streams
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  // State
  bool get playing => _player.playing;

  // Playback Controls
  Future<void> play() => _player.play();

  Future<void> pause() => _player.pause();

  Future<void> seek(Duration position) => _player.seek(position);

  Future<void> skipToNext() => _player.seekToNext();

  Future<void> skipToPrevious() => _player.seekToPrevious();

  // Playlist
  Future<void> updatePlaylist(List<String> uris) async {
    final playlist = ConcatenatingAudioSource(
      children: uris
          .map((uri) => AudioSource.uri(Uri.parse(uri)))
          .toList(),
    );

    await _player.setAudioSource(playlist);
  }

  Future<void> skipToQueueItem(int index) async {
    await _player.seek(
      Duration.zero,
      index: index,
    );

    await play();
  }

  // Repeat Mode
  Future<void> setRepeatMode(
    AudioServiceRepeatMode mode,
  ) async {
    switch (mode) {
      case AudioServiceRepeatMode.none:
        await _player.setLoopMode(LoopMode.off);
        break;

      case AudioServiceRepeatMode.one:
        await _player.setLoopMode(LoopMode.one);
        break;

      case AudioServiceRepeatMode.all:
      case AudioServiceRepeatMode.group:
        await _player.setLoopMode(LoopMode.all);
        break;
    }
  }

  // Shuffle Mode
  Future<void> setShuffleMode(
    AudioServiceShuffleMode mode,
  ) async {
    final enabled = mode == AudioServiceShuffleMode.all;

    await _player.setShuffleModeEnabled(enabled);

    if (enabled) {
      await _player.shuffle();
    }
  }

  // 8D Audio (placeholder)
  Future<void> set8DMode(bool enabled) async {
    // Connect your DSP engine here
  }

  // Equalizer (placeholder)
  Future<void> setEqualizerBand(
    int index,
    double gain,
  ) async {
    // Connect your EQ engine here
  }

  // Cleanup
  Future<void> dispose() async {
    await _player.dispose();
  }
}