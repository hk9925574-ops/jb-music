import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration>    get positionStream    => _player.positionStream;
  Stream<Duration?>   get durationStream    => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get playing => _player.playing;

  Future<void> play()                  => _player.play();
  Future<void> pause()                 => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> skipToNext()            => _player.seekToNext();
  Future<void> skipToPrevious()        => _player.seekToPrevious();

  Future<void> updatePlaylist(List<String> uris) async {
    final playlist = ConcatenatingAudioSource(
      children: uris
          .map((uri) => AudioSource.uri(Uri.parse(uri)))
          .toList(),
    );
    await _player.setAudioSource(playlist);
  }

  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    await play();
  }

  // ── Repeat ──────────────────────────────────────────────────────────────────
  Future<void> setRepeatMode(AudioServiceRepeatMode mode) async {
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

  // ── Shuffle ─────────────────────────────────────────────────────────────────
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    await _player.setShuffleModeEnabled(
      mode == AudioServiceShuffleMode.all,
    );
  }

  // ── Stubs (implement as needed) ─────────────────────────────────────────────
  Future<void> set8DMode(bool enabled)               async {}
  Future<void> setEqualizerBand(int index, double gain) async {}

  void dispose() => _player.dispose();
}