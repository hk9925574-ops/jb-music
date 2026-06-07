// This file previously contained a duplicate MusicBloc class definition
// which conflicted with music_bloc.dart and caused cascading type errors.
//
// FIX: All BLoC logic (events, states, MusicBloc) lives in music_bloc.dart.
// This file is intentionally left as a documentation stub.
//
// If you need architecture notes or diagrams, keep them here as comments only.
//
// EVENT FLOW:
//   LoadAudioTracksEvent  → MusicTracksLoadingState → MusicTracksLoadedState
//   PlayTrackEvent        → MusicTracksLoadedState (isPlaying: true)
//   TogglePlaybackEvent   → MusicTracksLoadedState (isPlaying toggled)
//   SeekPlaybackEvent     → MusicTracksLoadedState (position updated)
//   FilterTracksSearch    → MusicTracksLoadedState (visibleTracks filtered)
//   LoadPlaylistsEvent    → MusicTracksLoadedState (userPlaylists refreshed)
//   CreatePlaylistEvent   → MusicTracksLoadedState (playlist added)
//   AddTrackToPlaylist    → MusicTracksLoadedState (playlist track added)
