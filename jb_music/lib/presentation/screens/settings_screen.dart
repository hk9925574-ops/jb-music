// lib/presentation/screens/settings_screen.dart
// FIX: EQ preset + audio mode changes wired to real DSP engine
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/audio/dsp_engine.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // ── Audio settings ──────────────────────────────────────────────────────
  EqPreset _eqPreset    = EqPreset.flat;
  bool _safeListening   = true;
  bool _crossfade       = true;
  bool _notifications   = true;
  bool _bassBoostOn     = false;
  bool _vocalClearOn    = false;
  bool _is8DOn          = false;

  // ── Voice settings ──────────────────────────────────────────────────────
  bool _voiceEnabled    = true;
  bool _voiceListening  = false;
  String _voiceStatus   = '';
  StreamSubscription? _voiceSub;

  @override
  void initState() {
    super.initState();
    // Sync toggles from DSP engine
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dsp = context.read<MusicBloc>().dspEngine;
      setState(() {
        _eqPreset      = dsp.activePreset;
        _bassBoostOn   = dsp.isBassBoostEnabled;
        _vocalClearOn  = dsp.isVocalClearEnabled;
        _is8DOn        = dsp.is8DEnabled;
      });
    });
  }

  // ── Real voice test ────────────────────────────────────────────────────
  Future<void> _startVoiceTest() async {
    if (_voiceListening) return;
    final bloc = context.read<MusicBloc>();
    setState(() { _voiceListening = true; _voiceStatus = 'Listening…'; });
    try {
      bloc.add(StartVoiceListeningEvent());
      _voiceSub = bloc.voiceEngine.resultStream.listen(
        (result) {
          if (!mounted) return;
          final text = result.trim().toLowerCase();
          if (text.isEmpty) return;
          setState(() => _voiceStatus = 'Heard: "$text"');
          _stopVoiceTest();
        },
        onError: (e) {
          if (!mounted) return;
          setState(() { _voiceStatus = 'Error: $e'; _voiceListening = false; });
          bloc.add(StopVoiceListeningEvent());
        },
      );
      Future.delayed(const Duration(seconds: 8), () {
        if (_voiceListening && mounted) {
          setState(() => _voiceStatus = 'No command heard. Try again.');
          _stopVoiceTest();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _voiceStatus = 'Voice engine error: $e'; _voiceListening = false; });
    }
  }

  void _stopVoiceTest() {
    _voiceSub?.cancel();
    _voiceSub = null;
    context.read<MusicBloc>().add(StopVoiceListeningEvent());
    if (mounted) setState(() => _voiceListening = false);
  }

  @override
  void dispose() {
    _voiceSub?.cancel();
    super.dispose();
  }

  // ── DSP helpers ────────────────────────────────────────────────────────
  Future<void> _applyEqPreset(EqPreset preset) async {
    setState(() => _eqPreset = preset);
    await context.read<MusicBloc>().dspEngine.applyPreset(preset);
  }

  Future<void> _toggleBassBoost(bool v) async {
    setState(() => _bassBoostOn = v);
    await context.read<MusicBloc>().dspEngine.setBassBoost(v);
  }

  Future<void> _toggleVocalClear(bool v) async {
    setState(() => _vocalClearOn = v);
    await context.read<MusicBloc>().dspEngine.setVocalClear(v);
  }

  Future<void> _toggle8D(bool v) async {
    setState(() => _is8DOn = v);
    await context.read<MusicBloc>().dspEngine.set8DMode(v);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RG.black,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [

          // ── VOICE COMMANDS ─────────────────────────────────────────────
          _sectionLabel('Voice Commands'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Voice Commands',
                            style: TextStyle(color: Colors.white,
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 2),
                        Text('Say a command to control playback',
                            style: TextStyle(color: RG.textSecondary, fontSize: 12)),
                      ],
                    ),
                    Switch(
                      value: _voiceEnabled,
                      onChanged: (v) {
                        setState(() => _voiceEnabled = v);
                        if (!v) _stopVoiceTest();
                      },
                      activeThumbColor: RG.gold,
                    ),
                  ],
                ),
                if (_voiceEnabled) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: [
                      for (final cmd in [
                        'next song', 'previous song', 'play', 'pause',
                        'volume up', 'volume down', 'shuffle', 'sleep timer',
                      ])
                        _CommandChip(label: cmd),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_voiceStatus.isNotEmpty)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: _voiceListening
                            ? RG.gold.withValues(alpha: 0.08)
                            : RG.surfaceHigh,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _voiceListening
                              ? RG.gold.withValues(alpha: 0.4)
                              : RG.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (_voiceListening)
                            _PulsingDot()
                          else
                            Icon(Icons.info_outline_rounded,
                                color: RG.textSecondary, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _voiceStatus,
                              style: TextStyle(
                                color: _voiceListening ? RG.gold : RG.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _voiceListening ? RG.error : RG.gold,
                        foregroundColor: Colors.black,
                      ),
                      onPressed: _voiceListening ? _stopVoiceTest : _startVoiceTest,
                      icon: Icon(
                        _voiceListening ? Icons.stop_rounded : Icons.mic_rounded,
                        size: 18,
                      ),
                      label: Text(
                        _voiceListening ? 'Stop Listening' : 'Test Voice Command',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── AUDIO EFFECTS ──────────────────────────────────────────────
          _sectionLabel('Audio Effects'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bass / Vocal / 8D toggles
                Row(
                  children: [
                    Expanded(child: _EffectSwitch(
                      label: 'Bass Boost', icon: Icons.speaker,
                      value: _bassBoostOn, onChanged: _toggleBassBoost,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _EffectSwitch(
                      label: 'Vocal Clear', icon: Icons.mic,
                      value: _vocalClearOn, onChanged: _toggleVocalClear,
                    )),
                    const SizedBox(width: 8),
                    Expanded(child: _EffectSwitch(
                      label: '8D Audio', icon: Icons.headphones,
                      value: _is8DOn, onChanged: _toggle8D,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: RG.border, height: 1),
                const SizedBox(height: 14),
                // EQ Preset chips – FIX: wired to real DSP engine
                const Text('EQ Preset',
                    style: TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: EqPreset.values.map((p) {
                      final active = _eqPreset == p;
                      return GestureDetector(
                        onTap: () => _applyEqPreset(p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? RG.gold : Colors.transparent,
                            border: Border.all(
                                color: active ? RG.gold : RG.border),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(p.label,
                              style: TextStyle(
                                  color: active ? Colors.black : RG.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: RG.border, height: 1),
                _settingsRow(
                  'Crossfade',
                  'Smooth transitions between tracks',
                  Switch(
                      value: _crossfade,
                      onChanged: (v) => setState(() => _crossfade = v),
                      activeThumbColor: RG.gold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── SAFETY ────────────────────────────────────────────────────
          _sectionLabel('Safety & Wellness'),
          _card(
            child: Column(
              children: [
                _settingsRow(
                  'Safe Listening',
                  'WHO 80 dB limit enforced',
                  Switch(
                      value: _safeListening,
                      onChanged: (v) => setState(() => _safeListening = v),
                      activeThumbColor: RG.gold),
                ),
                Divider(color: RG.border, height: 1),
                _settingsRow(
                  'Ear Safety Alerts',
                  'Notifications when limit is reached',
                  Switch(
                      value: _notifications,
                      onChanged: (v) => setState(() => _notifications = v),
                      activeThumbColor: RG.gold),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── ABOUT ─────────────────────────────────────────────────────
          _sectionLabel('About'),
          _card(
            child: Column(
              children: [
                _settingsRow(
                    'Version', 'JB Music v3.1.0',
                    Text('Up to date',
                        style: TextStyle(color: RG.success, fontSize: 12))),
                Divider(color: RG.border, height: 1),
                _settingsRow(
                    'Privacy Policy', '',
                    Icon(Icons.chevron_right_rounded, color: RG.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
              color: RG.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4),
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RG.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RG.border, width: 0.8),
        ),
        child: child,
      );

  Widget _settingsRow(String label, String sub, Widget trailing) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  if (sub.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(sub,
                        style: TextStyle(
                            color: RG.textSecondary, fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      );
}

// ── Effect toggle (compact card) ─────────────────────────────────────────────
class _EffectSwitch extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _EffectSwitch({
    required this.label, required this.icon,
    required this.value, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: value ? RG.gold.withValues(alpha: 0.12) : RG.surfaceHigh,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: value ? RG.gold.withValues(alpha: 0.5) : RG.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: value ? RG.gold : RG.textMuted, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: value ? RG.gold : RG.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Command chip ──────────────────────────────────────────────────────────────
class _CommandChip extends StatelessWidget {
  final String label;
  const _CommandChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: RG.gold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RG.gold.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
            color: RG.gold, fontSize: 11, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// ── Pulsing dot ───────────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: RG.gold.withValues(alpha: 0.4 + 0.6 * _ctrl.value),
        ),
      ),
    );
  }
}
