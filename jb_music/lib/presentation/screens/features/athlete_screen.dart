// lib/presentation/screens/features/athlete_screen.dart
// JB Music — Athlete Mode Screen
// Sport selection, HR zone display, session timer, EQ auto-switch.

import 'dart:async';
import 'package:flutter/material.dart';

// FIX: removed unused flutter_bloc and music_bloc imports
import 'package:jb_music/core/athlete/athlete_engine.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';

class AthleteScreen extends StatefulWidget {
  const AthleteScreen({super.key});

  @override
  State<AthleteScreen> createState() => _AthleteScreenState();
}

class _AthleteScreenState extends State<AthleteScreen> {
  final JBAthleteEngine _engine = JBAthleteEngine();
  JBSport _selectedSport = JBSport.running;
  int _manualHR = 0;
  Timer? _sessionTimer;
  int _sessionSeconds = 0;
  bool _sessionActive = false;
  String _currentZone = 'Aerobic';
  String _currentPhase = 'Ready';

  @override
  void initState() {
    super.initState();
    _engine.init();
    _engine.zoneStream.listen((zone) {
      if (mounted) setState(() => _currentZone = zone.label);
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _engine.dispose();
    super.dispose();
  }

  void _startSession() {
    _engine.startSession(_selectedSport);
    setState(() {
      _sessionActive  = true;
      _sessionSeconds = 0;
    });
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _sessionSeconds++;
          _currentPhase = _engine.session?.phaseLabel ?? 'Training';
        });
      }
    });
  }

  void _endSession() {
    _engine.endSession();
    _sessionTimer?.cancel();
    setState(() {
      _sessionActive = false;
      _sessionSeconds = 0;
    });
  }

  String get _formattedTime {
    final m = _sessionSeconds ~/ 60;
    final s = _sessionSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RGTokens.background,
      appBar: AppBar(
        backgroundColor: RGTokens.background,
        title: const Text('Athlete Mode', style: TextStyle(color: RGTokens.gold)),
        iconTheme: const IconThemeData(color: RGTokens.gold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sport selector ──────────────────────────────────────────────
            const Text('Select Sport', style: TextStyle(color: RGTokens.gold, fontSize: 13, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: JBSport.values.map((sport) {
                final selected = sport == _selectedSport;
                return GestureDetector(
                  onTap: _sessionActive ? null : () => setState(() => _selectedSport = sport),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected ? RGTokens.gold : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? RGTokens.gold : RGTokens.gold.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '${_sportEmoji(sport)} ${sport.label}',
                      style: TextStyle(
                        color: selected ? Colors.black : RGTokens.gold.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 32),

            // ── Session card ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: RGTokens.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: RGTokens.gold.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Text(
                    _formattedTime,
                    style: TextStyle(
                      color: _sessionActive ? RGTokens.gold : Colors.white38,
                      fontSize: 52,
                      fontWeight: FontWeight.w200,
                      letterSpacing: 4,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _sessionActive ? _currentPhase : 'Ready to train',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                  const SizedBox(height: 20),

                  if (_sessionActive) ...[
                    _buildZonePill(_currentZone),
                    const SizedBox(height: 20),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _sessionActive ? _endSession : _startSession,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _sessionActive ? Colors.red.shade800 : RGTokens.gold,
                        foregroundColor: _sessionActive ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        _sessionActive ? 'End Session' : 'Start ${_selectedSport.label}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Manual HR input ─────────────────────────────────────────────
            if (_sessionActive) ...[
              const Text('Heart Rate (manual)', style: TextStyle(color: RGTokens.gold, fontSize: 13, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    '$_manualHR bpm',
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Slider(
                      value: _manualHR.toDouble(),
                      min: 40,
                      max: 220,
                      divisions: 180,
                      // FIX: Slider uses activeColor (not activeThumbColor — that's Switch only)
                      activeColor: RGTokens.gold,
                      inactiveColor: RGTokens.gold.withValues(alpha: 0.2),
                      onChanged: (v) {
                        final hr = v.round();
                        setState(() => _manualHR = hr);
                        _engine.updateHeartRate(hr);
                      },
                    ),
                  ),
                ],
              ),
            ],

            // ── Zone guide ──────────────────────────────────────────────────
            const SizedBox(height: 32),
            const Text('Heart Rate Zones', style: TextStyle(color: RGTokens.gold, fontSize: 13, letterSpacing: 1.2)),
            const SizedBox(height: 12),
            ...HRZone.values.map((zone) => _buildZoneRow(zone)),
          ],
        ),
      ),
    );
  }

  Widget _buildZonePill(String zone) {
    final color = _zoneColor(zone);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        '● Zone: $zone',
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildZoneRow(HRZone zone) {
    final active = _sessionActive && zone.label == _currentZone;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: active ? RGTokens.gold.withValues(alpha: 0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? RGTokens.gold.withValues(alpha: 0.5) : Colors.white12,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: _zoneColor(zone.label),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(zone.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
          Text(
            '${zone.musicBpmRange.$1}–${zone.musicBpmRange.$2} BPM music',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _zoneColor(String zone) {
    switch (zone) {
      case 'Recovery':   return Colors.blue;
      case 'Aerobic':    return Colors.green;
      case 'Tempo':      return Colors.yellow.shade700;
      case 'Threshold':  return Colors.orange;
      case 'Anaerobic':  return Colors.red;
      default:           return Colors.white38;
    }
  }

  String _sportEmoji(JBSport sport) => switch (sport) {
    JBSport.running  => '🏃',
    JBSport.gym      => '💪',
    JBSport.cycling  => '🚴',
    JBSport.cricket  => '🏏',
    JBSport.football => '⚽',
    JBSport.yoga     => '🧘',
    JBSport.hiit     => '🔥',
  };
}