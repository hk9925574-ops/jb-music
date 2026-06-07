// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:jb_music/presentation/screens/main_navigation_screen.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';
import 'package:jb_music/core/audio/dsp_engine.dart';
import 'package:jb_music/core/safety/ear_safety_monitor.dart';
import 'package:jb_music/core/voice/vosk_voice_engine.dart';
import 'package:jb_music/core/services/audio_handler.dart';

import 'package:jb_music/data/repositories/secure_vault_repository.dart';
import 'package:jb_music/data/repositories/local_playlist_repository.dart';
import 'package:jb_music/data/datasources/local_track_query_source.dart';

import 'package:jb_music/domain/usecases/get_tracks.dart';

import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/presentation/screens/dashboard_screen.dart';

final audioHandler = MyAudioHandler();

// ── Instantiate all services once at top level ────────────────────────────────
final _dspEngine = JBDspEngine();
final _safetyMonitor = EarSafetyMonitor();
final _voiceEngine = VoskVoiceEngine();
final _vaultRepository = SecureVaultRepository();
final _playlistRepository = LocalPlaylistRepository();
final _trackSource = LocalTrackQuerySource();
final _getTracksUseCase = GetTracks(repository: _trackSource);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('❌ FLUTTER ERROR: ${details.exception}');
    debugPrint(details.stack.toString());
  };

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  runZonedGuarded(() {
    runApp(const JBMusiqExecutableCanvas());
  }, (error, stackTrace) {
    debugPrint('❌ UNCAUGHT ERROR: $error');
    debugPrint(stackTrace.toString());
  });
}

class JBMusiqExecutableCanvas extends StatelessWidget {
  const JBMusiqExecutableCanvas({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<JBDspEngine>.value(value: _dspEngine),
        RepositoryProvider<LocalPlaylistRepository>.value(
            value: _playlistRepository),
      ],
      child: BlocProvider<MusicBloc>(
        create: (context) => MusicBloc(
          audioHandler: audioHandler,
          getTracksUseCase: _getTracksUseCase,
          dspEngine: _dspEngine,
          safetyMonitor: _safetyMonitor,
          voiceEngine: _voiceEngine,
          vaultRepository: _vaultRepository,
          playlistRepository: _playlistRepository,
        )..add(LoadAudioTracksEvent()),
        child: MaterialApp(
          title: 'JB Musiq',
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            ErrorWidget.builder = (FlutterErrorDetails details) {
              return Scaffold(
                backgroundColor: Colors.red,
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      details.exceptionAsString(),
                      style: const TextStyle(
                          color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              );
            };
            return child ?? const SizedBox();
          },
          theme: RG.darkTheme,
          home: const PlatformPermissionGate(),
        ),
      ),
    );
  }
}

class PlatformPermissionGate extends StatefulWidget {
  const PlatformPermissionGate({super.key});

  @override
  State<PlatformPermissionGate> createState() =>
      _PlatformPermissionGateState();
}

class _PlatformPermissionGateState extends State<PlatformPermissionGate> {
  bool _permissionsGranted = false;
  bool _isPermanentlyDenied = false;
  String _statusMessage = 'Requesting permissions...';

  @override
  void initState() {
    super.initState();
    _executePermissionVerificationPipeline();
  }

  Future<void> _executePermissionVerificationPipeline() async {
    try {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      final sdkInt = androidInfo.version.sdkInt;

      final permission = sdkInt >= 33 ? Permission.audio : Permission.storage;
      final status = await permission.request();

      if (!mounted) return;

      if (status.isGranted) {
        setState(() => _permissionsGranted = true);
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _isPermanentlyDenied = true;
          _statusMessage =
              'Storage permission permanently denied. Please enable in Settings.';
        });
      } else {
        setState(() {
          _statusMessage =
              'Please grant storage access to load your music.';
        });
      }
    } catch (e, st) {
      debugPrint('❌ PERMISSION ERROR: $e');
      debugPrint(st.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_permissionsGranted) {
      return Scaffold(
        backgroundColor: RG.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 24),
                if (_isPermanentlyDenied)
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    child: const Text('Open Settings'),
                  )
                else
                  ElevatedButton(
                    onPressed: _executePermissionVerificationPipeline,
                    child: const Text('Retry'),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return const MainNavigationScreen();
  }
}