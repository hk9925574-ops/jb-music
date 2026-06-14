// lib/presentation/widgets/equalizer_controls.dart
//
// JB MUSIC — NOVA EQUALIZER CONTROLS  (fixed: correct JBDspEngine API)
// ─────────────────────────────────────────────────────────────────────────────
// Full-featured EQ sheet with:
//  • 5-band frequency sliders (vertical, custom painted)
//  • Preset quick-select row
//  • Bass boost, Vocal clarity, 8D toggles
//  • Real-time wiring to DSP engine
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/audio/dsp_engine.dart';
import 'package:jb_music/core/theme/jb_design_system.dart';

class EqualizerControls extends StatefulWidget {
  const EqualizerControls({super.key});

  @override
  State<EqualizerControls> createState() => _EqualizerControlsState();
}

class _EqualizerControlsState extends State<EqualizerControls> {

  // 5-band EQ: Sub-bass, Bass, Mid, Presence, Treble
  static const _bands = ['60Hz', '230Hz', '910Hz', '3.6kHz', '14kHz'];
  late List<double> _gains;     // dB per band, from JBDspEngine.equalizerGains
  late EqPreset _preset;
  late bool _bassBoost;
  late bool _vocalClear;
  late bool _is8D;

  late JBDspEngine _dsp;

  @override
  void initState() {
    super.initState();
    _dsp = context.read<MusicBloc>().dspEngine;
    _preset     = _dsp.activePreset;
    _bassBoost  = _dsp.isBassBoostEnabled;
    _vocalClear = _dsp.isVocalClearEnabled;
    _is8D       = _dsp.is8DEnabled;
    // FIXED: equalizerGains (not bandGains)
    _gains      = List<double>.from(_dsp.equalizerGains);
  }

  void _applyGain(int band, double value) {
    setState(() => _gains[band] = value);
    // FIXED: setEqualizerBandGain (not setBandGain); async, fire-and-forget
    _dsp.setEqualizerBandGain(band, value);
    HapticFeedback.selectionClick();
  }

  void _selectPreset(EqPreset preset) {
    HapticFeedback.selectionClick();
    setState(() {
      _preset = preset;
      // FIXED: preset.gains is an extension getter on EqPreset (not dsp.gainsForPreset)
      _gains  = List<double>.from(preset.gains);
    });
    // FIXED: applyPreset (not setPreset); async, fire-and-forget
    _dsp.applyPreset(preset);
  }

  void _reset() {
    HapticFeedback.mediumImpact();
    setState(() {
      _preset = EqPreset.flat;
      _gains  = List<double>.from(EqPreset.flat.gains);
    });
    _dsp.applyPreset(EqPreset.flat);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: BoxDecoration(
        color: JBColors.void2,
        borderRadius: JBRadius.sheet,
        border: Border.all(color: JBColors.glassBorder, width: 0.5),
      ),
      child: Column(
        children: [
          // Handle + header
          const _SheetHandle(),
          _EQHeader(onReset: _reset),

          // Preset pills
          _PresetRow(current: _preset, onSelect: _selectPreset)
              .animate(delay: 50.ms).fadeIn(duration: 400.ms),

          const SizedBox(height: 8),

          // Band sliders
          Expanded(
            child: _BandSliders(
              bands: _bands,
              gains: _gains,
              onChanged: _applyGain,
            ).animate(delay: 100.ms).fadeIn(duration: 400.ms).slideY(begin: 0.15),
          ),

          // Feature toggles
          _FeatureToggles(
            bassBoost:  _bassBoost,
            vocalClear: _vocalClear,
            is8D:       _is8D,
            onBassBoost: (v) {
              setState(() => _bassBoost = v);
              _dsp.setBassBoost(v);
              HapticFeedback.selectionClick();
            },
            onVocalClear: (v) {
              setState(() => _vocalClear = v);
              _dsp.setVocalClear(v);
              HapticFeedback.selectionClick();
            },
            on8D: (v) {
              setState(() => _is8D = v);
              // FIXED: set8DMode (not set8D)
              _dsp.set8DMode(v);
              HapticFeedback.selectionClick();
            },
          ).animate(delay: 150.ms).fadeIn(duration: 400.ms),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Center(
          child: Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: JBColors.glassBorder,
              borderRadius: JBRadius.pill,
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _EQHeader extends StatelessWidget {
  final VoidCallback onReset;
  const _EQHeader({required this.onReset});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: JBGradients.nova,
              borderRadius: BorderRadius.circular(JBRadius.sm),
              boxShadow: JBShadow.novaSoft,
            ),
            child: const Icon(Icons.equalizer_rounded, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Equalizer', style: JBType.h3),
              Text('Tune your sound', style: JBType.caption),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onReset,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: JBGlass.card(radius: JBRadius.full),
              child: Text('Reset',
                style: JBType.captionMedium.copyWith(color: JBColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _PresetRow extends StatelessWidget {
  final EqPreset current;
  final ValueChanged<EqPreset> onSelect;
  const _PresetRow({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: EqPreset.values.map((p) {
          final active = p == current;
          return GestureDetector(
            onTap: () => onSelect(p),
            child: AnimatedContainer(
              duration: 200.ms,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: active
                  ? BoxDecoration(
                      gradient: JBGradients.nova,
                      borderRadius: JBRadius.pill,
                      boxShadow: JBShadow.nova,
                    )
                  : JBGlass.card(radius: JBRadius.full),
              child: Text(
                // FIXED: use the EqPresetLabel extension (.label) — covers all
                // 9 presets including hipHop, so no exhaustiveness issues.
                p.label,
                style: JBType.captionMedium.copyWith(
                  color: active ? JBColors.void0 : JBColors.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  5-BAND VERTICAL SLIDERS
// ─────────────────────────────────────────────────────────────────────────────
class _BandSliders extends StatelessWidget {
  final List<String> bands;
  final List<double> gains;
  final void Function(int, double) onChanged;

  const _BandSliders({
    required this.bands, required this.gains, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: bands.asMap().entries.map((e) {
        final i     = e.key;
        final label = e.value;
        final gain  = i < gains.length ? gains[i] : 0.0;

        return _VerticalBandSlider(
          label: label,
          gain: gain,
          onChanged: (v) => onChanged(i, v),
        );
      }).toList(),
    );
  }
}

class _VerticalBandSlider extends StatelessWidget {
  final String label;
  final double gain;
  final ValueChanged<double> onChanged;

  const _VerticalBandSlider({
    required this.label, required this.gain, required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dB     = gain.toStringAsFixed(1);
    final color  = gain > 0
        ? Color.lerp(JBColors.nova, JBColors.pulse, gain / 15)!
        : gain < 0
            ? Color.lerp(JBColors.textTertiary, JBColors.aurora, -gain / 15)!
            : JBColors.nova;

    return SizedBox(
      width: 56,
      child: Column(
        children: [
          // dB value
          Text(
            '${gain >= 0 ? '+' : ''}$dB',
            style: JBType.micro.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 6),

          // Vertical slider
          Expanded(
            child: RotatedBox(
              quarterTurns: 3,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  activeTrackColor: color,
                  inactiveTrackColor: JBColors.glass15,
                  thumbColor: Colors.white,
                  overlayColor: color.withValues(alpha: 0.2),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  // FIXED: clamp to ±15 dB to match JBDspEngine's actual range
                  value: gain.clamp(-15.0, 15.0),
                  min: -15,
                  max: 15,
                  divisions: 60,
                  onChanged: onChanged,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Frequency label
          Text(
            label,
            style: JBType.micro.copyWith(fontSize: 9),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  FEATURE TOGGLES ROW
// ─────────────────────────────────────────────────────────────────────────────
class _FeatureToggles extends StatelessWidget {
  final bool bassBoost, vocalClear, is8D;
  final ValueChanged<bool> onBassBoost, onVocalClear, on8D;

  const _FeatureToggles({
    required this.bassBoost, required this.vocalClear, required this.is8D,
    required this.onBassBoost, required this.onVocalClear, required this.on8D,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          _ToggleChip(
            label: 'Bass+',
            icon: Icons.graphic_eq_rounded,
            active: bassBoost,
            color: JBColors.pulse,
            onTap: () => onBassBoost(!bassBoost),
          ),
          const SizedBox(width: 10),
          _ToggleChip(
            label: 'Vocals',
            icon: Icons.record_voice_over_rounded,
            active: vocalClear,
            color: JBColors.aurora,
            onTap: () => onVocalClear(!vocalClear),
          ),
          const SizedBox(width: 10),
          _ToggleChip(
            label: '8D',
            icon: Icons.surround_sound_outlined,
            active: is8D,
            color: JBColors.nova,
            onTap: () => on8D(!is8D),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label, required this.icon,
    required this.active, required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: 250.ms,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: active
              ? BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: JBRadius.card,
                  border: Border.all(color: color.withValues(alpha: 0.5), width: 0.8),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 12),
                  ],
                )
              : JBGlass.card(radius: JBRadius.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: active ? color : JBColors.textSecondary, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: JBType.micro.copyWith(
                  color: active ? color : JBColors.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
