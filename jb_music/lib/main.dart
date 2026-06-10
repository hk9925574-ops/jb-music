// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

final audioHandler       = MyAudioHandler();
final _dspEngine         = JBDspEngine();
final _safetyMonitor     = EarSafetyMonitor();
final _voiceEngine       = VoskVoiceEngine();
final _vaultRepository   = SecureVaultRepository();
final _playlistRepository= LocalPlaylistRepository();
final _trackSource       = LocalTrackQuerySource();
final _getTracksUseCase  = GetTracks(repository: _trackSource);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    debugPrint('❌ FLUTTER ERROR: ${details.exception}');
    debugPrint(details.stack.toString());
  };

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF101010),
    ),
  );

  runZonedGuarded(() {
    runApp(const JBMusicApp());
  }, (error, stackTrace) {
    debugPrint('❌ UNCAUGHT ERROR: $error');
    debugPrint(stackTrace.toString());
  });
}

class JBMusicApp extends StatelessWidget {
  const JBMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<JBDspEngine>.value(value: _dspEngine),
        RepositoryProvider<LocalPlaylistRepository>.value(value: _playlistRepository),
      ],
      child: BlocProvider<MusicBloc>(
        create: (_) => MusicBloc(
          audioHandler:      audioHandler,
          getTracksUseCase:  _getTracksUseCase,
          dspEngine:         _dspEngine,
          safetyMonitor:     _safetyMonitor,
          voiceEngine:       _voiceEngine,
          vaultRepository:   _vaultRepository,
          playlistRepository: _playlistRepository,
        )..add(LoadAudioTracksEvent()),
        child: MaterialApp(
          title: 'JB Music',
          debugShowCheckedModeBanner: false,
          theme: RG.darkTheme,
          builder: (context, child) {
            ErrorWidget.builder = (details) => Scaffold(
              backgroundColor: RG.black,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: RG.error, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        details.exceptionAsString(),
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.0)),
              child: child ?? const SizedBox(),
            );
          },
          home: const JBSplashScreen(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SPLASH SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class JBSplashScreen extends StatefulWidget {
  const JBSplashScreen({super.key});
  @override
  State<JBSplashScreen> createState() => _JBSplashScreenState();
}

class _JBSplashScreenState extends State<JBSplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const PlatformPermissionGate(),
            transitionsBuilder: (_, anim, __, child) => FadeTransition(
              opacity: anim,
              child: child,
            ),
            transitionDuration: const Duration(milliseconds: 600),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RG.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo mark
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [RG.gold, RG.goldDim],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: RG.goldGlowShadow,
              ),
              child: const Icon(
                Icons.music_note_rounded,
                color: Colors.black,
                size: 52,
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.6, 0.6),
                  end: const Offset(1, 1),
                  duration: 700.ms,
                  curve: Curves.elasticOut,
                ),
            const SizedBox(height: 28),
            Text('JB Music', style: RG.displayStyle)
                .animate(delay: 200.ms)
                .fadeIn(duration: 500.ms)
                .slideY(begin: 0.3, end: 0),
            const SizedBox(height: 8),
            Text('Your personal music platform', style: RG.bodyStyle)
                .animate(delay: 350.ms)
                .fadeIn(duration: 500.ms),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PERMISSION GATE (unchanged logic, new styling)
// ─────────────────────────────────────────────────────────────────────────────
class PlatformPermissionGate extends StatefulWidget {
  const PlatformPermissionGate({super.key});
  @override
  State<PlatformPermissionGate> createState() => _PlatformPermissionGateState();
}

class _PlatformPermissionGateState extends State<PlatformPermissionGate> {
  bool   _granted          = false;
  bool   _permanentlyDenied= false;
  String _status           = 'Requesting permissions…';

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    try {
      final info   = await DeviceInfoPlugin().androidInfo;
      final sdk    = info.version.sdkInt;
      final perm   = sdk >= 33 ? Permission.audio : Permission.storage;
      final result = await [perm, Permission.microphone].request();
      final status = result[perm]!;

      if (!mounted) return;
      if (status.isGranted) {
        setState(() => _granted = true);
      } else if (status.isPermanentlyDenied) {
        setState(() {
          _permanentlyDenied = true;
          _status = 'Storage permission permanently denied. Please enable in Settings.';
        });
      } else {
        setState(() => _status = 'Please grant storage access to load your music.');
      }
    } catch (e) {
      debugPrint('❌ Permission error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_granted) return const MainNavigationScreen();

    return Scaffold(
      backgroundColor: RG.black,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 36),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: RG.surfacePop,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.folder_open_outlined, color: RG.gold, size: 40),
              ),
              const SizedBox(height: 24),
              Text('Access Required', style: RG.titleStyle),
              const SizedBox(height: 12),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: RG.bodyStyle,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RG.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(RG.radiusLG),
                    ),
                  ),
                  onPressed: _permanentlyDenied
                      ? openAppSettings
                      : _requestPermissions,
                  child: Text(
                    _permanentlyDenied ? 'Open Settings' : 'Grant Access',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}