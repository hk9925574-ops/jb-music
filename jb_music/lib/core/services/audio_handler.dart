// lib/core/services/audio_handler.dart
import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class MyAudioHandler extends BaseAudioHandler
    with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  // ── Streams ──────────────────────────────────────────────────────────────────
  Stream<Duration>    get positionStream    => _player.positionStream;
  Stream<Duration?>   get durationStream    => _player.durationStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  bool get playing => _player.playing;

  MyAudioHandler() {
    _listenToPlayerState();
    _listenToPosition();
    _listenToDuration();
  }

  // ── Internal listeners that keep notification in sync ─────────────────────
  void _listenToPlayerState() {
    _player.playerStateStream.listen((state) {
      final isPlaying = state.playing;
      final processingState = switch (state.processingState) {
        ProcessingState.idle      => AudioProcessingState.idle,
        ProcessingState.loading   => AudioProcessingState.loading,
        ProcessingState.buffering => AudioProcessingState.buffering,
        ProcessingState.ready     => AudioProcessingState.ready,
        ProcessingState.completed => AudioProcessingState.completed,
      };

      playbackState.add(playbackState.value.copyWith(
        playing: isPlaying,
        processingState: processingState,
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
      ));
    });
  }

  void _listenToPosition() {
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(
        updatePosition: position,
      ));
    });
  }

  void _listenToDuration() {
    _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null && duration != null) {
        mediaItem.add(current.copyWith(duration: duration));
      }
    });
  }

  // ── Playback controls ─────────────────────────────────────────────────────
  @override
  Future<void> play() async {
    await _player.play();
  }

  @override
  Future<void> pause() async {
    await _player.pause();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
    await _player.play();
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    await _player.play();
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    await play();
  }

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }
// ADD this one line anywhere after the _player declaration
AudioPlayer get player => _player;

Future<int?> getAudioSessionId() async {
  return player.androidAudioSessionId;
}
  // ── Playlist ──────────────────────────────────────────────────────────────
  Future<void> updatePlaylist(List<String> uris) async {
    final playlist = ConcatenatingAudioSource(
      children: uris.map((uri) => AudioSource.uri(Uri.parse(uri))).toList(),
    );
    await _player.setAudioSource(playlist);
  }

  // ── Now playing (updates notification title/artist/art) ───────────────────
  Future<void> updateNowPlaying({
    required String songId,
    required String title,
    required String artist,
    Uri? artUri,           // pass album art URI if you have it
  }) async {
    mediaItem.add(MediaItem(
      id:       songId,
      title:    title,
      artist:   artist,
      duration: _player.duration,
      artUri:   artUri,
    ));
  }

  // ── Repeat / Shuffle ──────────────────────────────────────────────────────
  @override
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
    await super.setRepeatMode(mode);
  }

  @override
  Future<void> setShuffleMode(AudioServiceShuffleMode mode) async {
    await _player.setShuffleModeEnabled(
      mode == AudioServiceShuffleMode.all,
    );
    await super.setShuffleMode(mode);
  }

  // ── Stubs ─────────────────────────────────────────────────────────────────
  Future<void> set8DMode(bool enabled)                  async {}
  Future<void> setEqualizerBand(int index, double gain) async {}

  void dispose() => _player.dispose();
}