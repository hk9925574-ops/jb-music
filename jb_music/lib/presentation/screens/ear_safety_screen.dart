// ─────────────────────────────────────────────────────────────
// FILE: lib/presentation/screens/ear_safety_screen.dart
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';

class EarSafetyScreen extends StatefulWidget {
  const EarSafetyScreen({super.key});
  @override
  State<EarSafetyScreen> createState() => _EarSafetyScreenState();
}

class _EarSafetyScreenState extends State<EarSafetyScreen> {
  bool _safeMode = true;
  final double _exposure = 72;
  final int _todayMin = 87;
  final int _weeklyMin = 410;
  final int _whoLimit = 480;
  final int _score = 78;

  Color _riskColor(double db) =>
      db < 70 ? Colors.greenAccent : db < 80 ? Colors.amber : Colors.redAccent;

  String _riskLabel(double db) =>
      db < 70 ? 'Safe' : db < 80 ? 'Moderate' : db < 90 ? 'High' : 'Dangerous';

  Color _scoreColor(int s) =>
      s >= 80 ? Colors.greenAccent : s >= 60 ? Colors.amber : Colors.redAccent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RG.black,
      appBar: AppBar(
        backgroundColor: RG.black,
        title: const Text('Ear Safety',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _riskColor(_exposure).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(_riskLabel(_exposure),
                style: TextStyle(
                    color: _riskColor(_exposure),
                    fontWeight: FontWeight.w700,
                    fontSize: 12)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Hearing score ring ────────────────────────────────
          _card(
            child: Column(
              children: [
                const Text('Hearing Health Score',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 16),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: _score / 100,
                        strokeWidth: 10,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(_scoreColor(_score)),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$_score',
                              style: TextStyle(
                                  color: _scoreColor(_score),
                                  fontSize: 36,
                                  fontWeight: FontWeight.w800)),
                          const Text('/100',
                              style: TextStyle(color: Colors.white54, fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Good — Keep monitoring',
                    style: TextStyle(color: Colors.white54, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Current exposure bar ──────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Current Exposure',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    Text('${_exposure.toInt()} dB',
                        style: TextStyle(
                            color: _riskColor(_exposure),
                            fontSize: 22,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _exposure / 120,
                    minHeight: 8,
                    backgroundColor: Colors.white12,
                    valueColor: AlwaysStoppedAnimation(_riskColor(_exposure)),
                  ),
                ),
                const SizedBox(height: 6),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('0 dB', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    Text('80 dB WHO limit', style: TextStyle(color: Colors.amber, fontSize: 10)),
                    Text('120 dB', style: TextStyle(color: Colors.white38, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Stats grid ────────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.6,
            children: [
              _statCard('Today', '${_todayMin}m', Colors.blue),
              _statCard('This Week', '${_weeklyMin}m', Colors.purpleAccent),
              _statCard('WHO Limit', '${_whoLimit}m', Colors.white38),
              _statCard('Remaining', '${_whoLimit - _weeklyMin}m', Colors.greenAccent),
            ],
          ),
          const SizedBox(height: 14),

          // ── Weekly bar chart ──────────────────────────────────
          _card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Weekly Exposure (minutes)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 80,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final d in [
                        {'day': 'Mon', 'min': 45},
                        {'day': 'Tue', 'min': 90},
                        {'day': 'Wed', 'min': 60},
                        {'day': 'Thu', 'min': 75},
                        {'day': 'Fri', 'min': 55},
                        {'day': 'Sat', 'min': 40},
                        {'day': 'Sun', 'min': 45},
                      ])
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: FractionallySizedBox(
                                  heightFactor: (d['min'] as int) / 90,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    decoration: BoxDecoration(
                                      color: (d['min'] as int) > 80
                                          ? Colors.amber
                                          : Colors.greenAccent,
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(4)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(d['day'] as String,
                                  style: const TextStyle(
                                      color: Colors.white54, fontSize: 10)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Safe listening toggle ─────────────────────────────
          _card(
            child: Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Safe Listening Mode',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      SizedBox(height: 4),
                      Text('WHO-recommended 80 dB cap',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ),
                Switch(
                  value: _safeMode,
                  onChanged: (v) => setState(() => _safeMode = v),
                  activeThumbColor: Colors.greenAccent,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── WHO tip ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.greenAccent.withValues(alpha: 0.07),
              border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('WHO Tip',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                SizedBox(height: 6),
                Text(
                  'Keep listening levels below 80 dB and take breaks every 60 minutes to protect your hearing.',
                  style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: RG.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    color: color, fontSize: 22, fontWeight: FontWeight.w800)),
          ],
        ),
      );

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: RG.surface, borderRadius: BorderRadius.circular(16)),
        child: child,
      );
}