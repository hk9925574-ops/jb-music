// lib/core/audio/service_locator.dart
import 'package:get_it/get_it.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jb_music/core/audio/dsp_engine.dart';
import 'package:jb_music/core/safety/ear_safety_monitor.dart';
import 'package:jb_music/core/voice/vosk_voice_engine.dart';
import 'package:jb_music/core/ai/mood_engine.dart';
import 'package:jb_music/core/ai/jb_dj.dart';
import 'package:jb_music/core/ai/smart_queue.dart';
import 'package:jb_music/core/ai/feature_registry.dart';
import 'package:jb_music/core/services/audio_handler.dart';
import 'package:jb_music/data/datasources/audio_local_source.dart';
import 'package:jb_music/data/repositories/audio_repository_impl.dart';
import 'package:jb_music/data/repositories/vault_repository_impl.dart';
import 'package:jb_music/data/repositories/local_playlist_repository.dart';
import 'package:jb_music/domain/repositories/audio_repository.dart';
import 'package:jb_music/domain/repositories/vault_repository.dart';
import 'package:jb_music/domain/repositories/playlist_repository.dart';
import 'package:jb_music/domain/usecases/get_tracks.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';

final sl = GetIt.instance;

Future<void> initServiceLocator() async {
  // 0. Feature registry must be ready first — moodEngine/djEngine/smartQueue
  //    are `late final` on JBFeatureRegistry and will throw if read before init().
  if (!JBFeatureRegistry.instance.isInitialized) {
    await JBFeatureRegistry.instance.init();
  }

  // 1. External plugins
  sl.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    ),
  );
  sl.registerLazySingleton<MyAudioHandler>(() => MyAudioHandler());
  sl.registerLazySingleton<JBDspEngine>(() => JBDspEngine());
  sl.registerLazySingleton<EarSafetyMonitor>(() => EarSafetyMonitor());
  sl.registerLazySingleton<VoskVoiceEngine>(() => VoskVoiceEngine());

  // 2. Data Sources
  sl.registerLazySingleton<AudioLocalSource>(() => AudioLocalSource());

  // 3. Repositories
  sl.registerLazySingleton<AudioRepository>(
    () => AudioRepositoryImpl(localSource: sl<AudioLocalSource>()),
  );
  sl.registerLazySingleton<VaultRepository>(
    () => VaultRepositoryImpl(secureStorage: sl<FlutterSecureStorage>()),
  );
  sl.registerLazySingleton<PlaylistRepository>(
    () => LocalPlaylistRepository(),
  );

  // 4. Use Cases
  sl.registerLazySingleton<GetTracks>(
    () => GetTracks(repository: sl<AudioRepository>()),
  );

  // 5. AI / smart engines — sourced from JBFeatureRegistry so there's exactly
  //    one moodEngine/djEngine/smartQueue shared with main.dart, AthleteScreen, etc.
  sl.registerLazySingleton<JBMoodEngine>(
    () => JBFeatureRegistry.instance.moodEngine,
  );
  sl.registerLazySingleton<JBDjEngine>(
    () => JBFeatureRegistry.instance.djEngine,
  );
  sl.registerLazySingleton<JBSmartQueue>(
    () => JBFeatureRegistry.instance.smartQueue,
  );

  // 6. BLoC
  sl.registerFactory<MusicBloc>(
    () => MusicBloc(
      audioHandler: sl<MyAudioHandler>(),
      getTracksUseCase: sl<GetTracks>(),
      dspEngine: sl<JBDspEngine>(),
      safetyMonitor: sl<EarSafetyMonitor>(),
      voiceEngine: sl<VoskVoiceEngine>(),
      vaultRepository: sl<VaultRepository>(),
      playlistRepository: sl<PlaylistRepository>(),
      moodEngine: sl<JBMoodEngine>(),
      djEngine: sl<JBDjEngine>(),
      smartQueue: sl<JBSmartQueue>(),
    ),
  );
}