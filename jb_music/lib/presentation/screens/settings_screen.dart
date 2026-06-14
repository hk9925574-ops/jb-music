// lib/presentation/screens/settings_screen.dart
//
// JB MUSIC — NOVA SETTINGS SCREEN  (fixed: correct DSP API calls)
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/audio/dsp_engine.dart';
import 'package:jb_music/core/theme/jb_design_system.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  EqPreset _eqPreset   = EqPreset.flat;
  bool _safeListening  = true;
  bool _crossfade      = true;
  bool _bassBoost      = false;
  bool _vocalClear     = false;
  bool _is8D           = false;
  bool _voiceEnabled   = true;
  bool _voiceListening = false;
  String _voiceStatus  = '';
  StreamSubscription<String>? _voiceSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final dsp = context.read<MusicBloc>().dspEngine;
      setState(() {
        _eqPreset   = dsp.activePreset;
        _bassBoost  = dsp.isBassBoostEnabled;
        _vocalClear = dsp.isVocalClearEnabled;
        _is8D       = dsp.is8DEnabled;
      });
    });
  }

  @override
  void dispose() {
    _voiceSub?.cancel();
    super.dispose();
  }

  Future<void> _startVoiceTest() async {
    if (_voiceListening) return;
    final bloc = context.read<MusicBloc>();
    setState(() { _voiceListening = true; _voiceStatus = 'Listening…'; });
    try {
      bloc.add(StartVoiceListeningEvent());
      // voiceEngine.resultStream emits raw recognised text
      _voiceSub = bloc.voiceEngine.resultStream.listen(
        (result) {
          if (!mounted) return;
          if (result.trim().isEmpty) return;
          setState(() => _voiceStatus = 'Heard: "$result"');
          _stopVoiceTest();
        },
        onError: (Object e) {
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
      setState(() { _voiceStatus = 'Voice engine error: $e'; _voiceListening = false; });
    }
  }

  void _stopVoiceTest() {
    _voiceSub?.cancel();
    setState(() => _voiceListening = false);
    context.read<MusicBloc>().add(StopVoiceListeningEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: JBColors.void0,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            floating: true,
            backgroundColor: JBColors.void0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              title: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings', style: JBType.h2),
                  Text('Customise your experience', style: JBType.caption),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── AUDIO ─────────────────────────────────────────────────
                const _SettingsSection(title: 'Audio', icon: Icons.graphic_eq_rounded, delay: 0),

                _SettingsCard(delay: 50, children: [
                  _EQPresetTile(
                    current: _eqPreset,
                    onChanged: (p) {
                      setState(() => _eqPreset = p);
                      // FIXED: applyPreset (not setPreset)
                      context.read<MusicBloc>().dspEngine.applyPreset(p);
                      HapticFeedback.selectionClick();
                    },
                  ),
                ]),

                const SizedBox(height: 8),

                _SettingsCard(delay: 80, children: [
                  _SwitchTile(
                    // FIXED: Icons.speaker_rounded (Icons.bass_clef doesn't exist)
                    icon: Icons.speaker_rounded,
                    label: 'Bass Boost',
                    subtitle: 'Enhance low frequencies',
                    value: _bassBoost,
                    color: JBColors.pulse,
                    onChanged: (v) {
                      setState(() => _bassBoost = v);
                      // setBassBoost is correct ✅
                      context.read<MusicBloc>().dspEngine.setBassBoost(v);
                    },
                  ),
                  _Divider(),
                  _SwitchTile(
                    icon: Icons.record_voice_over_rounded,
                    label: 'Vocal Clarity',
                    subtitle: 'Boost mid-range for clearer vocals',
                    value: _vocalClear,
                    color: JBColors.aurora,
                    onChanged: (v) {
                      setState(() => _vocalClear = v);
                      // setVocalClear is correct ✅
                      context.read<MusicBloc>().dspEngine.setVocalClear(v);
                    },
                  ),
                  _Divider(),
                  _SwitchTile(
                    icon: Icons.surround_sound_outlined,
                    label: '8D Audio',
                    subtitle: 'Spatial / binaural surround effect',
                    value: _is8D,
                    color: JBColors.nova,
                    onChanged: (v) {
                      setState(() => _is8D = v);
                      // FIXED: set8DMode (not set8D)
                      context.read<MusicBloc>().dspEngine.set8DMode(v);
                    },
                  ),
                  _Divider(),
                  _SwitchTile(
                    icon: Icons.shuffle_rounded,
                    label: 'Crossfade',
                    subtitle: 'Smooth transition between tracks',
                    value: _crossfade,
                    color: JBColors.gold,
                    onChanged: (v) => setState(() => _crossfade = v),
                  ),
                ]),

                const SizedBox(height: 16),

                // ── SAFETY ────────────────────────────────────────────────
                const _SettingsSection(title: 'Safety', icon: Icons.shield_outlined, delay: 100),

                _SettingsCard(delay: 130, children: [
                  _SwitchTile(
                    icon: Icons.hearing_outlined,
                    label: 'Ear Safety Mode',
                    subtitle: 'Alerts when volume is too high',
                    value: _safeListening,
                    color: JBColors.success,
                    onChanged: (v) => setState(() => _safeListening = v),
                  ),
                ]),

                const SizedBox(height: 16),

                // ── VOICE ─────────────────────────────────────────────────
                const _SettingsSection(title: 'Voice Assistant', icon: Icons.mic_none_rounded, delay: 160),

                _SettingsCard(delay: 190, children: [
                  _SwitchTile(
                    icon: Icons.auto_awesome_rounded,
                    label: 'JB Voice Assistant',
                    subtitle: 'Always-on voice commands',
                    value: _voiceEnabled,
                    color: JBColors.nova,
                    onChanged: (v) {
                      setState(() => _voiceEnabled = v);
                      if (v) {
                        context.read<MusicBloc>().add(StartVoiceListeningEvent());
                      } else {
                        context.read<MusicBloc>().add(StopVoiceListeningEvent());
                      }
                    },
                  ),
                  _Divider(),
                  _VoiceTestTile(
                    listening: _voiceListening,
                    status: _voiceStatus,
                    onTest: _startVoiceTest,
                    onStop: _stopVoiceTest,
                  ),
                ]),

                const SizedBox(height: 16),

                // ── ABOUT ─────────────────────────────────────────────────
                const _SettingsSection(title: 'About', icon: Icons.info_outline_rounded, delay: 230),

                _SettingsCard(delay: 250, children: [
                  const _InfoTile(label: 'Version',       value: '3.1.0'),
                  _Divider(),
                  const _InfoTile(label: 'Design System', value: 'Nova v1.0'),
                  _Divider(),
                  const _InfoTile(label: 'Built with',    value: 'Flutter + BLoC'),
                ]),

              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final int delay;
  const _SettingsSection({required this.title, required this.icon, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
      child: Row(
        children: [
          Icon(icon, color: JBColors.nova, size: 16),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: JBType.label.copyWith(
              color: JBColors.nova,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              fontSize: 11,
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn(duration: 400.ms).slideX(begin: -0.1);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final int delay;
  const _SettingsCard({required this.children, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: JBDecor.card,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      color: JBColors.glassBorder,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String label, subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(!value); },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            AnimatedContainer(
              duration: 200.ms,
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: value ? color.withValues(alpha: 0.15) : JBColors.glass10,
                borderRadius: BorderRadius.circular(JBRadius.sm),
                border: Border.all(
                  color: value ? color.withValues(alpha: 0.4) : JBColors.glassBorder,
                  width: 0.5,
                ),
              ),
              child: Icon(icon, color: value ? color : JBColors.textSecondary, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label,
                    style: JBType.bodyMedium.copyWith(
                      color: value ? JBColors.textPrimary : JBColors.textSecondary,
                    ),
                  ),
                  Text(subtitle, style: JBType.micro),
                ],
              ),
            ),
            AnimatedContainer(
              duration: 250.ms,
              width: 44, height: 24,
              decoration: BoxDecoration(
                color: value ? color : JBColors.glassBorder,
                borderRadius: JBRadius.pill,
                boxShadow: value
                    ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 8)]
                    : null,
              ),
              child: AnimatedAlign(
                duration: 250.ms,
                curve: JBAnim.spring,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 20, height: 20,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _EQPresetTile extends StatelessWidget {
  final EqPreset current;
  final ValueChanged<EqPreset> onChanged;
  const _EQPresetTile({required this.current, required this.onChanged});

  // FIXED: use the EqPresetLabel extension from dsp_engine.dart
  String _label(EqPreset p) => p.label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: JBColors.nova.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(JBRadius.sm),
                  border: Border.all(color: JBColors.nova.withValues(alpha: 0.3), width: 0.5),
                ),
                child: const Icon(Icons.equalizer_rounded, color: JBColors.nova, size: 18),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Equalizer Preset', style: JBType.bodyMedium),
                  Text('Choose your sound profile', style: JBType.micro),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: EqPreset.values.map((p) {
              final active = p == current;
              return GestureDetector(
                onTap: () => onChanged(p),
                child: AnimatedContainer(
                  duration: 200.ms,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: active
                      ? BoxDecoration(
                          gradient: JBGradients.nova,
                          borderRadius: JBRadius.pill,
                          boxShadow: JBShadow.nova,
                        )
                      : JBGlass.card(radius: JBRadius.full),
                  child: Text(
                    _label(p),
                    style: JBType.captionMedium.copyWith(
                      color: active ? JBColors.void0 : JBColors.textSecondary,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _VoiceTestTile extends StatelessWidget {
  final bool listening;
  final String status;
  final VoidCallback onTest, onStop;
  const _VoiceTestTile({
    required this.listening,
    required this.status,
    required this.onTest,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          AnimatedContainer(
            duration: 300.ms,
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: listening
                  ? JBColors.pulse.withValues(alpha: 0.15)
                  : JBColors.glass10,
              borderRadius: BorderRadius.circular(JBRadius.sm),
              border: Border.all(
                color: listening
                    ? JBColors.pulse.withValues(alpha: 0.4)
                    : JBColors.glassBorder,
                width: 0.5,
              ),
            ),
            child: Icon(
              listening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: listening ? JBColors.pulse : JBColors.textSecondary,
              size: 18,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Test Voice Recognition', style: JBType.bodyMedium),
                if (status.isNotEmpty)
                  Text(status, style: JBType.micro.copyWith(color: JBColors.nova)),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              if (listening) { onStop(); } else { onTest(); }
            },
            child: AnimatedContainer(
              duration: 200.ms,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: listening
                    ? JBColors.pulse.withValues(alpha: 0.15)
                    : JBColors.nova.withValues(alpha: 0.12),
                borderRadius: JBRadius.pill,
                border: Border.all(
                  color: listening
                      ? JBColors.pulse.withValues(alpha: 0.4)
                      : JBColors.nova.withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Text(
                listening ? 'Stop' : 'Test',
                style: JBType.captionMedium.copyWith(
                  color: listening ? JBColors.pulse : JBColors.nova,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final String label, value;
  const _InfoTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          Text(label, style: JBType.bodyMedium.copyWith(color: JBColors.textSecondary)),
          const Spacer(),
          Text(value,
            style: JBType.caption.copyWith(color: JBColors.nova, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

