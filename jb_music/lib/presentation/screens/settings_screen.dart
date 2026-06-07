// ─────────────────────────────────────────────────────────────
// FILE: lib/presentation/screens/settings_screen.dart
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _theme = 'dark';
  String _audioMode = 'normal';
  String _eqPreset = 'flat';
  bool _safeListening = true;
  bool _voiceCmd = true;
  bool _crossfade = true;
  bool _notifications = true;
  bool _voiceActive = false;
  String _voiceFeedback = '';

  final List<Map<String, String>> _themes = [
    {'id': 'dark', 'label': 'Dark'},
    {'id': 'amoled', 'label': 'AMOLED'},
    {'id': 'midnight', 'label': 'Midnight'},
    {'id': 'forest', 'label': 'Forest'},
  ];

  final List<Map<String, dynamic>> _audioModes = [
    {'id': 'normal', 'label': 'Normal', 'icon': Icons.volume_up},
    {'id': 'bass', 'label': 'Bass Boost', 'icon': Icons.graphic_eq},
    {'id': 'vocal', 'label': 'Vocal Clear', 'icon': Icons.record_voice_over},
    {'id': 'surround', 'label': 'Surround', 'icon': Icons.surround_sound},
  ];

  final List<String> _eqPresets = [
    'Flat', 'Bass+', 'Treble+', 'Pop', 'Rock', 'Jazz', 'Classical'
  ];

  void _testVoice() {
    setState(() {
      _voiceActive = true;
      _voiceFeedback = 'Listening...';
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _voiceFeedback = 'Recognized: "Next song"');
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
            _voiceActive = false;
            _voiceFeedback = '';
          });
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RG.black,
      appBar: AppBar(
        backgroundColor: RG.black,
        title: const Text('Settings',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── VOICE COMMAND PANEL ──────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: _voiceActive
                  ? Colors.redAccent.withValues(alpha: 0.08)
                  : RG.gold.withValues(alpha: 0.06),
              border: Border.all(
                  color: _voiceActive
                      ? Colors.redAccent.withValues(alpha: 0.4)
                      : RG.gold.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Voice Commands',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        SizedBox(height: 2),
                        Text('Say "Hey Music" to activate',
                            style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    Switch(
                      value: _voiceCmd,
                      onChanged: (v) => setState(() => _voiceCmd = v),
                      activeThumbColor: RG.gold,
                    ),
                  ],
                ),
                if (_voiceCmd) ...[
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final cmd in [
                        'Next song', 'Play', 'Pause',
                        'Volume up', 'Shuffle', 'Sleep timer'
                      ])
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: RG.gold.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(cmd,
                              style: const TextStyle(
                                  color: RG.gold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _voiceActive ? Colors.redAccent : RG.gold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _voiceActive ? null : _testVoice,
                      icon: Icon(_voiceActive ? Icons.stop : Icons.mic, size: 18),
                      label: Text(
                        _voiceActive ? _voiceFeedback : 'Test Voice Command',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── APPEARANCE ───────────────────────────────────────
          _sectionLabel('Appearance'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Theme',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 12),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 3,
                  children: _themes.map((t) {
                    final active = _theme == t['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _theme = t['id']!),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: active ? RG.gold : Colors.white24,
                              width: active ? 1.5 : 0.5),
                          borderRadius: BorderRadius.circular(10),
                          color: RG.black,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (active)
                              const Padding(
                                padding: EdgeInsets.only(right: 6),
                                child: Icon(Icons.check, color: RG.gold, size: 14),
                              ),
                            Text(t['label']!,
                                style: TextStyle(
                                    color: active ? RG.gold : Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── AUDIO ─────────────────────────────────────────────
          _sectionLabel('Audio'),
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Audio Mode',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 3,
                  children: _audioModes.map((m) {
                    final active = _audioMode == m['id'];
                    return GestureDetector(
                      onTap: () => setState(() => _audioMode = m['id']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: active ? RG.gold : Colors.white12,
                              width: active ? 1.5 : 0.5),
                          borderRadius: BorderRadius.circular(10),
                          color: active ? RG.gold.withValues(alpha: 0.08) : RG.black,
                        ),
                        child: Row(
                          children: [
                            Icon(m['icon'] as IconData,
                                color: active ? RG.gold : Colors.white38, size: 16),
                            const SizedBox(width: 6),
                            Text(m['label'],
                                style: TextStyle(
                                    color: active ? RG.gold : Colors.white54,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                const SizedBox(height: 14),
                const Text('EQ Preset',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _eqPresets.map((p) {
                      final active = _eqPreset == p.toLowerCase();
                      return GestureDetector(
                        onTap: () => setState(() => _eqPreset = p.toLowerCase()),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: active ? RG.gold : Colors.transparent,
                            border: Border.all(
                                color: active ? RG.gold : Colors.white24),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(p,
                              style: TextStyle(
                                  color: active ? Colors.black : Colors.white54,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13)),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                _settingsRow(
                  'Crossfade',
                  'Smooth transitions between tracks',
                  Switch(
                    value: _crossfade,
                    onChanged: (v) => setState(() => _crossfade = v),
                    activeThumbColor: RG.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── SAFETY ────────────────────────────────────────────
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
                    activeThumbColor: Colors.greenAccent,
                  ),
                ),
                Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                _settingsRow(
                  'Notifications',
                  'Ear safety alerts',
                  Switch(
                    value: _notifications,
                    onChanged: (v) => setState(() => _notifications = v),
                    activeThumbColor: RG.gold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── ABOUT ─────────────────────────────────────────────
          _sectionLabel('About'),
          _card(
            child: Column(
              children: [
                _settingsRow('Version', 'JB Musiq v3.0.0',
                    const Text('Up to date',
                        style: TextStyle(color: Colors.greenAccent, fontSize: 12))),
                Divider(color: Colors.white.withValues(alpha: 0.07), height: 1),
                _settingsRow('Privacy Policy', '',
                    const Icon(Icons.chevron_right, color: Colors.white38)),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(label.toUpperCase(),
            style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: RG.surface, borderRadius: BorderRadius.circular(16)),
        child: child,
      );

  Widget _settingsRow(String label, String sub, Widget trailing) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                if (sub.isNotEmpty)
                  Text(sub,
                      style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            trailing,
          ],
        ),
      );
}