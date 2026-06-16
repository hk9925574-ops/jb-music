// lib/main.dart
//
// JB MUSIC — NOVA — Entry Point
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
// ADD THIS IMPORT AT THE TOP OF lib\main.dart
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jb_music/presentation/screens/main_navigation_screen.dart';
import 'package:jb_music/core/theme/jb_design_system.dart';
import 'package:jb_music/core/audio/dsp_engine.dart';
import 'package:jb_music/core/safety/ear_safety_monitor.dart';
import 'package:jb_music/core/voice/vosk_voice_engine.dart';
import 'package:jb_music/core/services/audio_handler.dart';
import 'package:jb_music/data/repositories/secure_vault_repository.dart';
import 'package:jb_music/data/repositories/local_playlist_repository.dart';
import 'package:jb_music/data/datasources/local_track_query_source.dart';
import 'package:jb_music/domain/usecases/get_tracks.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/ai/feature_registry.dart';

const bool isTestMode = bool.fromEnvironment('TEST_MODE', defaultValue: false);

late final AudioHandler audioHandler;
final _dspEngine          = JBDspEngine();
final _safetyMonitor      = EarSafetyMonitor();
final _voiceEngine        = VoskVoiceEngine();
final _vaultRepository    = SecureVaultRepository();
final _playlistRepository = LocalPlaylistRepository();
final _trackSource        = LocalTrackQuerySource();
final _getTracksUseCase   = GetTracks(repository: _trackSource);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  audioHandler = await AudioService.init(
  builder: () => MyAudioHandler(),
  config: const AudioServiceConfig(
    androidNotificationChannelId: 'com.jbmusic.audio',
    androidNotificationChannelName: 'JB Music Playback',
    androidNotificationOngoing: true,
    androidStopForegroundOnPause: false,
  ),
);
  if (!isTestMode) {
    await JBFeatureRegistry.instance.init();
  }

  FlutterError.onError = (details) {
    debugPrint('❌ FLUTTER ERROR: ${details.exception}');
    debugPrint(details.stack.toString());
  };

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // NOVA: full-immersive system chrome
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.light,
      systemNavigationBarContrastEnforced: false,
    ),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runZonedGuarded(() {
    runApp(const JBMusicApp());
  }, (error, stackTrace) {
    debugPrint('❌ UNHANDLED ERROR: $error');
    debugPrint(stackTrace.toString());
  });
}

// ─────────────────────────────────────────────────────────────────────────────
class JBMusicApp extends StatelessWidget {
  const JBMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => MusicBloc(
        audioHandler:      audioHandler,
        dspEngine:         _dspEngine,
        safetyMonitor:     _safetyMonitor,
        voiceEngine:       _voiceEngine,
        vaultRepository:   _vaultRepository,
        playlistRepository: _playlistRepository,
        getTracksUseCase:  _getTracksUseCase,
      )..add(LoadAudioTracksEvent()),
      child: MaterialApp(
        title: 'JB Music',
        debugShowCheckedModeBanner: false,
        theme: JBTheme.dark,          // ← NOVA theme
        darkTheme: JBTheme.dark,
        themeMode: ThemeMode.dark,
        home: const _SplashGate(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SPLASH → Permission → Main
// ─────────────────────────────────────────────────────────────────────────────
class _SplashGate extends StatefulWidget {
  const _SplashGate();
  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
        ..forward();
    _init();
  }

  Future<void> _init() async {
    await _requestPermissions();
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _ready = true);
  }

  Future<void> _requestPermissions() async {
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      if (info.version.sdkInt >= 33) {
        await [
          Permission.audio,
          Permission.microphone,
        ].request();
      } else {
        await [
          Permission.storage,
          Permission.microphone,
        ].request();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return const MainNavigationScreen();
    }
    return _SplashScreen(ctrl: _ctrl);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SPLASH SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class _SplashScreen extends StatelessWidget {
  final AnimationController ctrl;
  const _SplashScreen({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JBColors.void0,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo orb
            AnimatedBuilder(
              animation: ctrl,
              builder: (_, __) {
                final scale = Curves.elasticOut.transform(ctrl.value.clamp(0.0, 1.0));
                return Transform.scale(
                  scale: 0.5 + scale * 0.5,
                  child: Opacity(
                    opacity: ctrl.value.clamp(0.0, 1.0),
                    child: Container(
                      width: 96, height: 96,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: JBGradients.nova,
                        boxShadow: JBShadow.novaIntense,
                      ),
                      child: const Icon(
                        Icons.music_note_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 24),

            // App name
            ShaderMask(
              shaderCallback: (r) => JBGradients.sectionTitle.createShader(r),
              child: Text(
                'JB Music',
                style: JBType.h1.copyWith(color: Colors.white, fontSize: 36),
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.2, end: 0, curve: JBAnim.easeOut),

            const SizedBox(height: 8),

            Text(
              'Nova Edition',
              style: JBType.caption.copyWith(color: JBColors.nova, letterSpacing: 2),
            )
                .animate(delay: 600.ms)
                .fadeIn(duration: 500.ms),

            const SizedBox(height: 48),

            // Loading indicator
            SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                backgroundColor: JBColors.glass10,
                valueColor: const AlwaysStoppedAnimation<Color>(JBColors.nova),
                borderRadius: JBRadius.pill,
                minHeight: 2,
              ),
            )
                .animate(delay: 700.ms)
                .fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
