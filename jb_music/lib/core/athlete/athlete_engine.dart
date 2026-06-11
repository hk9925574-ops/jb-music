// lib/core/athlete/athlete_engine.dart
// JB Music — Athlete Mode Engine
// Adapts music playback to sport type, training intensity, and heart rate zone.
// Supports: Running, Gym, Cycling, Cricket warmup, Football drills.
// No wearable required — manual intensity input or future HR sensor integration.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:jb_music/domain/entities/jb_song.dart';
import 'package:jb_music/core/audio/dsp_engine.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPORT TYPES
// ─────────────────────────────────────────────────────────────────────────────

enum JBSport {
  running,
  gym,
  cycling,
  cricket,
  football,
  yoga,
  hiit,
}

extension JBSportLabel on JBSport {
  String get label => switch (this) {
        JBSport.running  => 'Running',
        JBSport.gym      => 'Gym',
        JBSport.cycling  => 'Cycling',
        JBSport.cricket  => 'Cricket',
        JBSport.football => 'Football',
        JBSport.yoga     => 'Yoga',
        JBSport.hiit     => 'HIIT',
      };

  // Best EQ per sport
  EqPreset get eqPreset => switch (this) {
        JBSport.running  => EqPreset.electronic,
        JBSport.gym      => EqPreset.rock,
        JBSport.cycling  => EqPreset.electronic,
        JBSport.cricket  => EqPreset.pop,
        JBSport.football => EqPreset.hip_hop,
        JBSport.yoga     => EqPreset.classical,
        JBSport.hiit     => EqPreset.rock,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// HEART RATE ZONES (standard 5-zone model)
// ─────────────────────────────────────────────────────────────────────────────

enum HRZone {
  recovery,    // Zone 1: <57% max HR
  aerobic,     // Zone 2: 57–63%
  tempo,       // Zone 3: 64–75%
  threshold,   // Zone 4: 76–85%
  anaerobic,   // Zone 5: >85%
}

extension HRZoneLabel on HRZone {
  String get label => switch (this) {
        HRZone.recovery   => 'Recovery',
        HRZone.aerobic    => 'Aerobic',
        HRZone.tempo      => 'Tempo',
        HRZone.threshold  => 'Threshold',
        HRZone.anaerobic  => 'Anaerobic',
      };

  // Target BPM range for music (approx)
  (int min, int max) get musicBpmRange => switch (this) {
        HRZone.recovery   => (60, 90),
        HRZone.aerobic    => (90, 120),
        HRZone.tempo      => (120, 140),
        HRZone.threshold  => (140, 165),
        HRZone.anaerobic  => (165, 200),
      };

  EqPreset get eqPreset => switch (this) {
        HRZone.recovery   => EqPreset.classical,
        HRZone.aerobic    => EqPreset.pop,
        HRZone.tempo      => EqPreset.rock,
        HRZone.threshold  => EqPreset.electronic,
        HRZone.anaerobic  => EqPreset.hip_hop,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// TRAINING SESSION
// ─────────────────────────────────────────────────────────────────────────────

class TrainingSession {
  final JBSport sport;
  final DateTime startTime;
  Duration get elapsed => DateTime.now().difference(startTime);

  int _currentHR = 0;
  HRZone _currentZone = HRZone.aerobic;
  int _maxHR = 190; // default — user can set their own

  int get currentHR   => _currentHR;
  HRZone get zone     => _currentZone;

  TrainingSession({required this.sport, int? maxHR})
      : startTime = DateTime.now(),
        _maxHR = maxHR ?? 190;

  void updateHR(int bpm) {
    _currentHR = bpm;
    _currentZone = _zoneFromHR(bpm, _maxHR);
  }

  static HRZone _zoneFromHR(int hr, int maxHR) {
    if (maxHR == 0) return HRZone.aerobic;
    final pct = hr / maxHR;
    if (pct < 0.57) return HRZone.recovery;
    if (pct < 0.64) return HRZone.aerobic;
    if (pct < 0.76) return HRZone.tempo;
    if (pct < 0.86) return HRZone.threshold;
    return HRZone.anaerobic;
  }

  // Phase of session (warm-up, peak, cooldown)
  String get phaseLabel {
    final mins = elapsed.inMinutes;
    if (mins < 5) return 'Warm-up';
    if (sport == JBSport.hiit || sport == JBSport.gym) {
      if (mins < 30) return 'Training';
      return 'Cooldown';
    }
    if (mins < 10) return 'Building';
    if (mins > 45) return 'Cooldown';
    return 'Peak';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ATHLETE ENGINE
// ─────────────────────────────────────────────────────────────────────────────

class JBAthleteEngine {
  static const _prefsKey  = 'jb_athlete_max_hr';
  static const _sportKey  = 'jb_athlete_sport';

  TrainingSession? _session;
  TrainingSession? get session => _session;
  bool get isActive => _session != null;

  // Stream of zone changes — BLoC listens to this
  final _zoneCtrl = StreamController<HRZone>.broadcast();
  Stream<HRZone> get zoneStream => _zoneCtrl.stream;

  // Stream of EQ recommendations
  final _eqCtrl = StreamController<EqPreset>.broadcast();
  Stream<EqPreset> get eqStream => _eqCtrl.stream;

  HRZone _lastZone = HRZone.aerobic;
  int _userMaxHR = 190;
  JBSport _lastSport = JBSport.gym;

  // ── Init ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _userMaxHR  = prefs.getInt(_prefsKey) ?? 190;
    final si    = prefs.getInt(_sportKey) ?? 1;
    _lastSport  = JBSport.values[si.clamp(0, JBSport.values.length - 1)];
  }

  Future<void> savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, _userMaxHR);
    await prefs.setInt(_sportKey, _lastSport.index);
  }

  // ── Session control ────────────────────────────────────────────────────────

  void startSession(JBSport sport, {int? maxHR}) {
    _session = TrainingSession(sport: sport, maxHR: maxHR ?? _userMaxHR);
    _lastSport = sport;
    debugPrint('🏃 Athlete session started: ${sport.label}');
    // Emit initial EQ recommendation
    _eqCtrl.add(sport.eqPreset);
    savePreferences();
  }

  void endSession() {
    if (_session == null) return;
    debugPrint('✅ Session ended: ${_session!.elapsed.inMinutes} min');
    _session = null;
  }

  // ── HR update (call from wearable BLE or manual slider) ───────────────────

  void updateHeartRate(int bpm) {
    if (_session == null) return;
    _session!.updateHR(bpm);
    final zone = _session!.zone;

    if (zone != _lastZone) {
      _lastZone = zone;
      debugPrint('💓 Zone changed → ${zone.label} ($bpm bpm)');
      _zoneCtrl.add(zone);
      _eqCtrl.add(_resolveEq(zone, _session!.sport));
    }
  }

  EqPreset _resolveEq(HRZone zone, JBSport sport) {
    // Sport-specific overrides for certain zones
    if (sport == JBSport.yoga) return EqPreset.classical;
    if (zone == HRZone.recovery || zone == HRZone.aerobic) return sport.eqPreset;
    return zone.eqPreset; // threshold/anaerobic → intensity-driven EQ
  }

  // ── Playlist filter for athlete ───────────────────────────────────────────
  // Filters library to songs matching current zone's BPM target.
  // Uses duration as a rough BPM proxy (shorter songs often faster tempo).

  List<JBSong> filterForZone(List<JBSong> library) {
    final zone = _session?.zone ?? HRZone.aerobic;
    final (minBpm, maxBpm) = zone.musicBpmRange;

    // Without actual BPM metadata, we sort by duration as a proxy:
    // shorter avg duration = generally faster tempo for electronic/hip-hop
    // In production, integrate bpm_detector or store BPM in JBSong.
    final sorted = List<JBSong>.from(library);
    if (minBpm > 130) {
      // High intensity — prefer shorter tracks (higher energy)
      sorted.sort((a, b) => a.durationMs.compareTo(b.durationMs));
    } else {
      sorted.sort((a, b) => b.durationMs.compareTo(a.durationMs));
    }
    return sorted;
  }

  // ── Stats ─────────────────────────────────────────────────────────────────

  Map<String, dynamic> sessionStats() {
    if (_session == null) return {};
    return {
      'sport':    _session!.sport.label,
      'duration': _session!.elapsed.inMinutes,
      'phase':    _session!.phaseLabel,
      'zone':     _session!.zone.label,
      'hr':       _session!.currentHR,
    };
  }

  // ── Dispose ────────────────────────────────────────────────────────────────

  void dispose() {
    _zoneCtrl.close();
    _eqCtrl.close();
  }
}
