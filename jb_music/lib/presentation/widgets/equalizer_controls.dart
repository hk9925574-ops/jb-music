// lib/presentation/widgets/equalizer_controls.dart
// FIXED: Bass Boost, Vocal Clear, enhanced 8D toggle, all EQ presets working
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:jb_music/application/bloc/music_bloc.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';

const _kBandLabels = ['31', '62', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'];

const _kPresets = {
  'Flat':       [0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0,  0.0],
  'Bass+':      [8.0,  7.0,  5.0,  3.0,  1.0,  0.0,  0.0,  0.0,  0.0,  0.0],
  'Treble+':    [0.0,  0.0,  0.0,  0.0,  0.0,  2.0,  4.0,  6.0,  7.0,  8.0],
  'Vocal':      [-2.0,-2.0,  0.0,  3.0,  5.0,  5.0,  3.0,  0.0, -2.0, -2.0],
  'Rock':       [5.0,  4.0,  2.0,  0.0,  0.0,  2.0,  4.0,  5.0,  5.0,  6.0],
  'Pop':        [2.0,  3.0,  4.0,  4.0,  2.0,  0.0,  2.0,  3.0,  3.0,  2.0],
  'Electronic': [6.0,  5.0,  0.0, -3.0, -2.0,  2.0,  4.0,  5.0,  6.0,  7.0],
  'Hip-Hop':    [8.0,  6.0,  3.0,  1.0,  0.0,  0.0,  2.0,  3.0,  2.0,  1.0],
};

class EqualizerControls extends StatefulWidget {
  const EqualizerControls({super.key});
  @override
  State<EqualizerControls> createState() => _EqualizerControlsState();
}

class _EqualizerControlsState extends State<EqualizerControls>
    with SingleTickerProviderStateMixin {
  List<double> _bands = List<double>.filled(10, 0.0);
  String? _activePreset = 'Flat';

  bool _bassBoostOn = false;
  bool _vocalClearOn = false;
  bool _is8DOn = false;

  late final AnimationController _glowCtrl;

  @override
  void initState() {
    super.initState();
    _glowCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bloc = context.read<MusicBloc>();
      setState(() {
        _bassBoostOn  = bloc.dspEngine.isBassBoostEnabled;
        _vocalClearOn = bloc.dspEngine.isVocalClearEnabled;
        _is8DOn       = bloc.dspEngine.is8DEnabled;
      });
    });
  }

  @override
  void dispose() {
    _glowCtrl.dispose();
    super.dispose();
  }

  void _applyPreset(String name) {
    final values = List<double>.from(_kPresets[name]!);
    setState(() { _bands = values; _activePreset = name; });
    for (var i = 0; i < values.length; i++) {
      final hwBand = i ~/ 2;
      context.read<MusicBloc>().dspEngine.setEqualizerBandGain(hwBand, values[i]);
    }
  }

  void _onBandChanged(int index, double value) {
    setState(() { _bands[index] = value; _activePreset = null; });
    final hwBand = (index ~/ 2).clamp(0, 4);
    context.read<MusicBloc>().dspEngine.setEqualizerBandGain(hwBand, value);
  }

  Future<void> _toggleBassBoost() async {
    final newVal = !_bassBoostOn;
    setState(() => _bassBoostOn = newVal);
    await context.read<MusicBloc>().dspEngine.setBassBoost(newVal);
    if (newVal) setState(() => _activePreset = null);
  }

  Future<void> _toggleVocalClear() async {
    final newVal = !_vocalClearOn;
    setState(() => _vocalClearOn = newVal);
    await context.read<MusicBloc>().dspEngine.setVocalClear(newVal);
    if (newVal) setState(() => _activePreset = null);
  }

  Future<void> _toggle8D() async {
    final newVal = !_is8DOn;
    setState(() => _is8DOn = newVal);
    await context.read<MusicBloc>().dspEngine.set8DMode(newVal);
  }

  Color _bandColor(double db) {
    if (db >= 5) return RG.pink;
    if (db >= 2) return Color.lerp(RG.cyan, RG.pink, (db - 2) / 3)!;
    if (db >= 0) return RG.cyan;
    return Color.lerp(Colors.white38, RG.cyan, 1 + db / 10)!;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A0F1E).withValues(alpha: 0.96),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: RG.cyan.withValues(alpha: 0.22), width: 0.8)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 36, height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _glowCtrl,
                        builder: (_, __) => Icon(
                          Icons.equalizer_rounded,
                          color: Color.lerp(RG.cyan, RG.pink, _glowCtrl.value),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'SOUND STUDIO',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const Spacer(),
                      if (_activePreset == null)
                        const _NeonChip(
                          label: 'CUSTOM',
                          active: true,
                          // FIX: was activeThumbColor (invalid) → activeColor
                          activeColor: RG.pink,
                          onTap: null,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Quick Effects Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: _EffectToggle(
                          icon: Icons.speaker,
                          label: 'Bass Boost',
                          isOn: _bassBoostOn,
                          color: const Color(0xFF00BCD4),
                          onToggle: _toggleBassBoost,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EffectToggle(
                          icon: Icons.mic,
                          label: 'Vocal Clear',
                          isOn: _vocalClearOn,
                          color: const Color(0xFF9C27B0),
                          onToggle: _toggleVocalClear,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _EffectToggle(
                          icon: Icons.headphones,
                          label: '8D Audio',
                          isOn: _is8DOn,
                          color: const Color(0xFFFF5722),
                          onToggle: _toggle8D,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // EQ Preset chips
                SizedBox(
                  height: 34,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: _kPresets.keys.map((name) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _NeonChip(
                          label: name.toUpperCase(),
                          active: _activePreset == name,
                          // FIX: was activeThumbColor (invalid) → activeColor
                          activeColor: RG.cyan,
                          onTap: () => _applyPreset(name),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Band sliders
                SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List.generate(10, (i) {
                      final db = _bands[i];
                      return Expanded(
                        child: _BandSlider(
                          label: _kBandLabels[i],
                          value: db,
                          color: _bandColor(db),
                          onChanged: (v) => _onBandChanged(i, v),
                        ),
                      );
                    }),
                  ),
                ),

                // dB scale
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '+10 dB',
                        style: TextStyle(
                          color: RG.cyan.withValues(alpha: 0.5),
                          fontSize: 9,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Text(
                        '0 dB',
                        style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 0.5),
                      ),
                      const Text(
                        '-10 dB',
                        style: TextStyle(color: Colors.white24, fontSize: 9, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Effect Toggle Button ───────────────────────────────────────────────────────
class _EffectToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOn;
  final Color color;
  final VoidCallback onToggle;

  const _EffectToggle({
    required this.icon,
    required this.label,
    required this.isOn,
    required this.color,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isOn ? color.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isOn ? color.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.1),
            width: isOn ? 1.5 : 1.0,
          ),
          boxShadow: isOn
              ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12)]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isOn ? color : Colors.white38, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isOn ? color : Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Container(
              width: 24, height: 3,
              decoration: BoxDecoration(
                color: isOn ? color : Colors.white12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Band Slider ───────────────────────────────────────────────────────────────
class _BandSlider extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;

  const _BandSlider({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value == 0 ? '0' : '${value > 0 ? '+' : ''}${value.toStringAsFixed(0)}',
          style: TextStyle(
            color: value.abs() > 0.5 ? color : Colors.white24,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                activeTrackColor: color,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                thumbColor: Colors.white,
                overlayColor: color.withValues(alpha: 0.2),
              ),
              child: Slider(
                value: value,
                min: -10.0,
                max: 10.0,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 9,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ── Neon Chip ─────────────────────────────────────────────────────────────────
class _NeonChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color activeColor;
  final VoidCallback? onTap;

  const _NeonChip({
    required this.label,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active
              ? activeColor.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          border: Border.all(
            color: active
                ? activeColor.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: active
              ? [BoxShadow(color: activeColor.withValues(alpha: 0.25), blurRadius: 8)]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? activeColor : Colors.white38,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }
}