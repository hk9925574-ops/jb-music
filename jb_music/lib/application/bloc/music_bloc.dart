// lib/application/bloc/music_bloc.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:jb_music/core/audio/dsp_engine.dart';
import 'package:jb_music/core/safety/ear_safety_monitor.dart';
import 'package:jb_music/core/voice/vosk_voice_engine.dart';
import 'package:jb_music/core/services/audio_handler.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/domain/entities/voice_intent.dart';
import 'package:jb_music/domain/repositories/vault_repository.dart';
import 'package:jb_music/domain/repositories/playlist_repository.dart';
import 'package:jb_music/domain/usecases/get_tracks.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PLAYLIST MODEL
// ─────────────────────────────────────────────────────────────────────────────
class JBPlaylist {
  final String id;
  String name;
  final List<JBSong> songs;
  JBPlaylist({required this.id, required this.name, this.songs = const []});
  JBPlaylist copyWith({String? name, List<JBSong>? songs}) =>
      JBPlaylist(id: id, name: name ?? this.name, songs: songs ?? this.songs);
}

// ─────────────────────────────────────────────────────────────────────────────
// STATES
// ─────────────────────────────────────────────────────────────────────────────
abstract class MusicState extends Equatable {
  const MusicState();
  @override
  List<Object> get props => [];
}

class MusicTracksLoadingState extends MusicState {}

class MusicTracksLoadedState extends MusicState {
  final List<JBSong> visibleTracks;
  final int currentTrackIndex;
  final bool isPlaying;
  final List<JBSong> likedTracks;
  final List<JBSong> recentTracks;
  final List<JBPlaylist> playlists;
  final String voiceSearchQuery;
  final int sleepTimerMinutes;
  final Duration todayListened;
  final Map<String, int> playCount;

  const MusicTracksLoadedState({
    required this.visibleTracks,
    required this.currentTrackIndex,
    required this.isPlaying,
    this.likedTracks = const [],
    this.recentTracks = const [],
    this.playlists = const [],
    this.voiceSearchQuery = '',
    this.sleepTimerMinutes = 0,
    this.todayListened = Duration.zero,
    this.playCount = const {},
  });

  MusicTracksLoadedState copyWith({
    List<JBSong>? visibleTracks,
    int? currentTrackIndex,
    bool? isPlaying,
    List<JBSong>? likedTracks,
    List<JBSong>? recentTracks,
    List<JBPlaylist>? playlists,
    String? voiceSearchQuery,
    int? sleepTimerMinutes,
    Duration? todayListened,
    Map<String, int>? playCount,
  }) =>
      MusicTracksLoadedState(
        visibleTracks: visibleTracks ?? this.visibleTracks,
        currentTrackIndex: currentTrackIndex ?? this.currentTrackIndex,
        isPlaying: isPlaying ?? this.isPlaying,
        likedTracks: likedTracks ?? this.likedTracks,
        recentTracks: recentTracks ?? this.recentTracks,
        playlists: playlists ?? this.playlists,
        voiceSearchQuery: voiceSearchQuery ?? this.voiceSearchQuery,
        sleepTimerMinutes: sleepTimerMinutes ?? this.sleepTimerMinutes,
        todayListened: todayListened ?? this.todayListened,
        playCount: playCount ?? this.playCount,
      );

  // Fix: return List<Object> (non-nullable) — use empty string/0 instead of nullables
  @override
  List<Object> get props => [
        visibleTracks,
        currentTrackIndex,
        isPlaying,
        likedTracks,
        recentTracks,
        playlists,
        voiceSearchQuery,
        sleepTimerMinutes,
        todayListened,
        playCount,
      ];
}

class MusicErrorState extends MusicState {
  final String message;
  const MusicErrorState(this.message);
  @override
  List<Object> get props => [message];
}

// ─────────────────────────────────────────────────────────────────────────────
// EVENTS
// ─────────────────────────────────────────────────────────────────────────────
abstract class MusicEvent {}

class LoadAudioTracksEvent extends MusicEvent {}

class TogglePlaybackEvent extends MusicEvent {}

class PlayTrackEvent extends MusicEvent {
  final int index;
  final List<JBSong> tracks;
  PlayTrackEvent({required this.index, required this.tracks});
}

class PlaybackStateChangedEvent extends MusicEvent {
  final bool isPlaying;
  PlaybackStateChangedEvent(this.isPlaying);
}

class SearchTracksEvent extends MusicEvent {
  final String query;
  SearchTracksEvent(this.query);
}

class ToggleLikeTrackEvent extends MusicEvent {
  final JBSong song;
  ToggleLikeTrackEvent(this.song);
}

// ── Playlist events ───────────────────────────────────────────────────────────
class CreatePlaylistEvent extends MusicEvent {
  final String name;
  CreatePlaylistEvent(this.name);
}

class DeletePlaylistEvent extends MusicEvent {
  final String playlistId;
  DeletePlaylistEvent(this.playlistId);
}

class AddSongToPlaylistEvent extends MusicEvent {
  final String playlistId;
  final JBSong song;
  AddSongToPlaylistEvent({required this.playlistId, required this.song});
}

class RemoveSongFromPlaylistEvent extends MusicEvent {
  final String playlistId;
  final JBSong song;
  RemoveSongFromPlaylistEvent({required this.playlistId, required this.song});
}

class PlaySmartPlaylistEvent extends MusicEvent {
  final SmartPlaylistType type;
  PlaySmartPlaylistEvent(this.type);
}

enum SmartPlaylistType { workout, study, sleep, travel, shuffle }

// ── Voice events ──────────────────────────────────────────────────────────────
class StartVoiceListeningEvent extends MusicEvent {}

class StopVoiceListeningEvent extends MusicEvent {}

class VoiceCommandEvent extends MusicEvent {
  final VoiceCommandIntent intent;
  VoiceCommandEvent({required this.intent});
}

// ─────────────────────────────────────────────────────────────────────────────
// BLOC
// ─────────────────────────────────────────────────────────────────────────────
class MusicBloc extends Bloc<MusicEvent, MusicState> {
  final MyAudioHandler audioHandler;
  final GetTracks getTracksUseCase;
  final JBDspEngine dspEngine;
  final EarSafetyMonitor safetyMonitor;
  final VoskVoiceEngine _voiceEngine;
  final VaultRepository vaultRepository;
  final PlaylistRepository playlistRepository;

  late final StreamSubscription<PlayerState> _playbackSub;
  late final StreamSubscription<VoiceCommandIntent> _voiceIntentSub;

  List<JBSong> _allTracks = [];
  // ignore: prefer_final_fields — these lists are mutated in place
  List<JBSong> _likedTracks = [];
  List<JBSong> _recentTracks = [];
  final List<JBPlaylist> _playlists = [];

  String _voiceSearchQuery = '';
  int _sleepTimerMinutes = 0;
  DateTime? _listenStartTime;
  Map<String, int> _playCount = {};

  Timer? _sleepTimer;

  VoskVoiceEngine get voiceEngine => _voiceEngine;

  MusicBloc({
    required this.audioHandler,
    required this.getTracksUseCase,
    required this.dspEngine,
    required this.safetyMonitor,
    required VoskVoiceEngine voiceEngine,
    required this.vaultRepository,
    required this.playlistRepository,
  })  : _voiceEngine = voiceEngine,
        super(MusicTracksLoadingState()) {
    _playbackSub = audioHandler.playerStateStream.listen(
      (state) => add(PlaybackStateChangedEvent(state.playing)),
    );

    _voiceIntentSub = _voiceEngine.commandIntentStream.listen(
      (intent) {
        debugPrint('BLOC RECEIVED: ${intent.action}');
        add(VoiceCommandEvent(intent: intent));
      },
    );

    on<LoadAudioTracksEvent>(_onLoadTracks);
    on<TogglePlaybackEvent>(_onTogglePlayback);
    on<PlayTrackEvent>(_onPlayTrack);
    on<PlaybackStateChangedEvent>(_onPlaybackStateChanged);
    on<SearchTracksEvent>(_onSearch);
    on<ToggleLikeTrackEvent>(_onToggleLikeTrack);
    on<CreatePlaylistEvent>(_onCreatePlaylist);
    on<DeletePlaylistEvent>(_onDeletePlaylist);
    on<AddSongToPlaylistEvent>(_onAddSongToPlaylist);
    on<RemoveSongFromPlaylistEvent>(_onRemoveSongFromPlaylist);
    on<StartVoiceListeningEvent>(_onStartVoice);
    on<StopVoiceListeningEvent>(_onStopVoice);
    on<VoiceCommandEvent>(_onVoiceCommand);
    on<PlaySmartPlaylistEvent>(_onPlaySmartPlaylist);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  MusicTracksLoadedState get _currentLoaded =>
      state is MusicTracksLoadedState
          ? state as MusicTracksLoadedState
          : MusicTracksLoadedState(
              visibleTracks: _allTracks,
              currentTrackIndex: 0,
              isPlaying: false,
              likedTracks: _likedTracks,
              recentTracks: _recentTracks,
              playlists: _playlists,
            );

  MusicTracksLoadedState _buildState({
    List<JBSong>? visibleTracks,
    int? currentTrackIndex,
    bool? isPlaying,
    String? voiceSearchQuery,
    int? sleepTimerMinutes,
  }) {
    final cur = state is MusicTracksLoadedState
        ? state as MusicTracksLoadedState
        : null;
    return MusicTracksLoadedState(
      visibleTracks: visibleTracks ?? cur?.visibleTracks ?? _allTracks,
      currentTrackIndex:
          currentTrackIndex ?? cur?.currentTrackIndex ?? 0,
      isPlaying: isPlaying ?? cur?.isPlaying ?? false,
      likedTracks: _likedTracks,
      recentTracks: _recentTracks,
      playlists: _playlists,
      voiceSearchQuery: voiceSearchQuery ?? _voiceSearchQuery,
      sleepTimerMinutes: sleepTimerMinutes ?? _sleepTimerMinutes,
      todayListened: cur?.todayListened ?? Duration.zero,
      playCount: _playCount,
    );
  }

  // ── Handlers ───────────────────────────────────────────────────────────────

  Future<void> _onLoadTracks(
      LoadAudioTracksEvent event, Emitter<MusicState> emit) async {
    emit(MusicTracksLoadingState());
    try {
      final tracks = await getTracksUseCase.call();
      _allTracks = tracks.cast<JBSong>();
      emit(MusicTracksLoadedState(
        visibleTracks: _allTracks,
        currentTrackIndex: 0,
        isPlaying: false,
        likedTracks: _likedTracks,
        recentTracks: _recentTracks,
        playlists: _playlists,
      ));
    } catch (e) {
      emit(MusicErrorState('Failed to load tracks: $e'));
    }
  }

  void _onTogglePlayback(
      TogglePlaybackEvent event, Emitter<MusicState> emit) {
    audioHandler.playing ? audioHandler.pause() : audioHandler.play();
  }

  Future<void> _onPlayTrack(
      PlayTrackEvent event, Emitter<MusicState> emit) async {
    final uris = event.tracks.map((t) => 'file://${t.path}').toList();
    await audioHandler.updatePlaylist(uris);
     await audioHandler.skipToQueueItem(event.index);
    await audioHandler.updateNowPlaying(
      songId: event.tracks[event.index].id,
      title: event.tracks[event.index].title,
      artist: event.tracks[event.index].artist,
    );
    final song = event.tracks[event.index];
    _recentTracks
      ..removeWhere((s) => s.path == song.path)
      ..insert(0, song);
    if (_recentTracks.length > 20) {
      _recentTracks = _recentTracks.sublist(0, 20);
    }

    final songId = event.tracks[event.index].id;
    final updated = Map<String, int>.from(_playCount);
    updated[songId] = (updated[songId] ?? 0) + 1;
    _playCount = updated;

    _listenStartTime ??= DateTime.now();

    emit(_buildState(
      visibleTracks: event.tracks,
      currentTrackIndex: event.index,
      isPlaying: true,
    ));
  }

  // Fix: this was registered but missing — now properly defined
  void _onPlaybackStateChanged(
      PlaybackStateChangedEvent event, Emitter<MusicState> emit) {
    if (state is! MusicTracksLoadedState) return;
    emit(_buildState(isPlaying: event.isPlaying));
  }

  void _onSearch(SearchTracksEvent event, Emitter<MusicState> emit) {
    final q = event.query.toLowerCase();
    final filtered = q.isEmpty
        ? _allTracks
        : _allTracks
            .where((t) =>
                t.title.toLowerCase().contains(q) ||
                t.artist.toLowerCase().contains(q))
            .toList();
    final cur = _currentLoaded;
    emit(_buildState(
      visibleTracks: filtered,
      currentTrackIndex: cur.currentTrackIndex,
      isPlaying: cur.isPlaying,
    ));
  }

  void _onToggleLikeTrack(
      ToggleLikeTrackEvent event, Emitter<MusicState> emit) {
    if (state is! MusicTracksLoadedState) return;
    final exists = _likedTracks.any((s) => s.path == event.song.path);
    if (exists) {
      _likedTracks.removeWhere((s) => s.path == event.song.path);
    } else {
      _likedTracks.add(event.song);
    }
    emit(_buildState());
  }

  void _onCreatePlaylist(
      CreatePlaylistEvent event, Emitter<MusicState> emit) {
    final pl = JBPlaylist(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: event.name,
      songs: [],
    );
    _playlists.add(pl);
    emit(_buildState());
  }

  void _onDeletePlaylist(
      DeletePlaylistEvent event, Emitter<MusicState> emit) {
    _playlists.removeWhere((p) => p.id == event.playlistId);
    emit(_buildState());
  }

  void _onAddSongToPlaylist(
      AddSongToPlaylistEvent event, Emitter<MusicState> emit) {
    final idx = _playlists.indexWhere((p) => p.id == event.playlistId);
    if (idx < 0) return;
    final pl = _playlists[idx];
    if (pl.songs.any((s) => s.path == event.song.path)) return;
    _playlists[idx] = pl.copyWith(songs: [...pl.songs, event.song]);
    emit(_buildState());
  }

  void _onRemoveSongFromPlaylist(
      RemoveSongFromPlaylistEvent event, Emitter<MusicState> emit) {
    final idx = _playlists.indexWhere((p) => p.id == event.playlistId);
    if (idx < 0) return;
    final pl = _playlists[idx];
    _playlists[idx] = pl.copyWith(
        songs: pl.songs.where((s) => s.path != event.song.path).toList());
    emit(_buildState());
  }

  // Fix: removed duplicate — single definition only
  void _onPlaySmartPlaylist(
      PlaySmartPlaylistEvent event, Emitter<MusicState> emit) {
    if (state is! MusicTracksLoadedState) return;

    List<JBSong> selection;

    // Fix: JBSong.duration is a Duration — compare with Duration constants,
    // not raw int milliseconds.
    switch (event.type) {
      case SmartPlaylistType.shuffle:
        selection = List.of(_allTracks)..shuffle();
        break;

      case SmartPlaylistType.workout:
        // Short tracks < 4 minutes
        selection = _allTracks
            .where((s) =>
                s.duration < const Duration(minutes: 4))
            .toList();
        if (selection.isEmpty) selection = _allTracks;
        break;

      case SmartPlaylistType.study:
        // Longer tracks >= 4 minutes
        selection = _allTracks
            .where((s) =>
                s.duration >= const Duration(minutes: 4))
            .toList();
        if (selection.isEmpty) selection = _allTracks;
        break;

      case SmartPlaylistType.sleep:
        selection = List.of(_allTracks)..shuffle();
        break;

      case SmartPlaylistType.travel:
        selection = List.of(_allTracks)..shuffle();
        break;
    }

    if (selection.isEmpty) return;
    add(PlayTrackEvent(index: 0, tracks: selection));
  }

  Future<void> _onStartVoice(
      StartVoiceListeningEvent event, Emitter<MusicState> emit) async {
    try {
      if (!_voiceEngine.isReady) {
        await _voiceEngine.initializeVoicePipeline();
      }
      await _voiceEngine.startListening();
    } catch (e) {
      debugPrint('❌ Voice start error: $e');
    }
  }

  Future<void> _onStopVoice(
      StopVoiceListeningEvent event, Emitter<MusicState> emit) async {
    await _voiceEngine.stopListening();
  }

  Future<void> _onVoiceCommand(
      VoiceCommandEvent event, Emitter<MusicState> emit) async {
    final intent = event.intent;
    debugPrint('🎤 ACTION: ${intent.action}, PAYLOAD: ${intent.payload}');

    switch (intent.action) {
      // ── Playback ──────────────────────────────────────────────────────────
      case JbVoiceAction.play:
        await audioHandler.play();
        break;
      case JbVoiceAction.pause:
        await audioHandler.pause();
        break;
      case JbVoiceAction.togglePlayPause:
        audioHandler.playing
            ? await audioHandler.pause()
            : await audioHandler.play();
        break;
      case JbVoiceAction.next:
        await audioHandler.skipToNext();
        break;
      case JbVoiceAction.previous:
        await audioHandler.skipToPrevious();
        break;
      case JbVoiceAction.shuffle:
        await audioHandler.setShuffleMode(AudioServiceShuffleMode.all);
        break;
      case JbVoiceAction.repeat:
        await audioHandler.setRepeatMode(AudioServiceRepeatMode.all);
        break;

      // ── Volume ────────────────────────────────────────────────────────────
      case JbVoiceAction.volumeUp:
        debugPrint('🔊 Volume up (implement with audioHandler volume API)');
        break;
      case JbVoiceAction.volumeDown:
        debugPrint('🔉 Volume down');
        break;

      // ── Search song ───────────────────────────────────────────────────────
      case JbVoiceAction.searchSong:
        final query = intent.payload ?? '';
        if (query.isNotEmpty) {
          debugPrint('🔍 Voice search: $query');
          _voiceSearchQuery = query;
          emit(_buildState(voiceSearchQuery: query));
        }
        break;

      // ── Play song by name ─────────────────────────────────────────────────
      case JbVoiceAction.playSong:
        final query = (intent.payload ?? '').toLowerCase();
        if (query.isNotEmpty) {
          debugPrint('🎵 Voice play song: $query');
          final match = _allTracks.indexWhere((t) =>
              t.title.toLowerCase().contains(query) ||
              t.artist.toLowerCase().contains(query));
          if (match != -1) {
            add(PlayTrackEvent(index: match, tracks: _allTracks));
            debugPrint('✅ Playing: ${_allTracks[match].title}');
          } else {
            _voiceSearchQuery = query;
            emit(_buildState(voiceSearchQuery: query));
            debugPrint(
                '⚠️ No exact match — showing search results for "$query"');
          }
        }
        break;

      // ── Play playlist ─────────────────────────────────────────────────────
      case JbVoiceAction.playPlaylist:
        final name = (intent.payload ?? '').toLowerCase();
        if (name.isNotEmpty) {
          final matches = _playlists
              .where((p) => p.name.toLowerCase().contains(name));
          if (matches.isEmpty) {
            debugPrint('⚠️ No matching playlist found for "$name"');
            return;
          }
          final selected = matches.first;
          debugPrint('📋 Playing playlist: ${selected.name}');
          if (selected.songs.isNotEmpty) {
            add(PlayTrackEvent(index: 0, tracks: selected.songs));
          }
        }
        break;

      // ── Sleep timer ───────────────────────────────────────────────────────
      case JbVoiceAction.setSleepTimer:
        {
          final int mins = int.tryParse(intent.payload ?? '30') ?? 30;
          _sleepTimer?.cancel();
          _sleepTimer = Timer(Duration(minutes: mins), () async {
            debugPrint('⏰ Sleep timer fired — pausing');
            await audioHandler.pause();
          });
          _sleepTimerMinutes = mins;
          emit(_buildState(sleepTimerMinutes: mins));
          debugPrint('⏰ Sleep timer set for $mins minutes');
          break;
        }

      case JbVoiceAction.cancelSleepTimer:
        {
          _sleepTimer?.cancel();
          _sleepTimer = null;
          _sleepTimerMinutes = 0;
          emit(_buildState(sleepTimerMinutes: 0));
          debugPrint('⏰ Sleep timer cancelled');
          break;
        }

      // ── Safety ────────────────────────────────────────────────────────────
      case JbVoiceAction.checkSafety:
        debugPrint('🛡️ Safety check requested');
        break;

      case JbVoiceAction.unknown:
        debugPrint('❓ Unknown voice command: ${intent.action}');
        break;
    }
  }

  @override
  Future<void> close() {
    _playbackSub.cancel();
    _voiceIntentSub.cancel();
    _sleepTimer?.cancel();
    return super.close();
  }
}