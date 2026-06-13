// lib/presentation/screens/features/stats_screen.dart
// JB Music — Listening Stats Screen
// Shows: current streak, today's time, weekly time, top songs, milestones.

import 'package:flutter/material.dart';
import 'package:jb_music/core/ai/listening_stats.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';

class StatsScreen extends StatelessWidget {
  final JBListeningStats stats;
  const StatsScreen({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final wrapped  = stats.weeklyWrapped();
    final topSongs = stats.topSongs;
    final artists  = stats.topArtists;
    final milestones = stats.allMilestones;

    return Scaffold(
      backgroundColor: RGTokens.background,
      appBar: AppBar(
        backgroundColor: RGTokens.background,
        title: const Text('Your Stats', style: TextStyle(color: RGTokens.gold)),
        iconTheme: const IconThemeData(color: RGTokens.gold),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Summary cards ────────────────────────────────────────────────
            Row(
              children: [
                _statCard('Streak', '${stats.currentStreak}d 🔥', flex: 1),
                const SizedBox(width: 12),
                _statCard('Today', _formatTime(stats.todayListenTime), flex: 1),
                const SizedBox(width: 12),
                _statCard('This Week', _formatTime(stats.thisWeekListenTime), flex: 1),
              ],
            ),

            const SizedBox(height: 28),

            // ── Weekly Wrapped ────────────────────────────────────────────────
            _sectionLabel('This Week'),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: RGTokens.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: RGTokens.gold.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  _wrappedRow('🎵 Top Song',   wrapped['topSong'] ?? '—'),
                  const Divider(color: Colors.white12, height: 20),
                  _wrappedRow('🎤 Top Artist', wrapped['topArtist'] ?? '—'),
                  const Divider(color: Colors.white12, height: 20),
                  _wrappedRow('🎧 Tracks Played', '${wrapped['tracksPlayed']}'),
                  const Divider(color: Colors.white12, height: 20),
                  _wrappedRow('⏱️ Minutes Listened', '${wrapped['weekMinutes']} min'),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ── Top Songs ─────────────────────────────────────────────────────
            if (topSongs.isNotEmpty) ...[
              _sectionLabel('Most Played'),
              ...topSongs.asMap().entries.map((e) {
                final i    = e.key;
                final stat = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: RGTokens.surface,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}',
                        style: TextStyle(
                          color: i == 0 ? RGTokens.gold : Colors.white38,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(stat.song.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
                            Text(stat.song.artist, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        '${stat.playCount} plays',
                        style: TextStyle(color: RGTokens.gold.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 28),
            ],

            // ── Top Artists ───────────────────────────────────────────────────
            if (artists.isNotEmpty) ...[
              _sectionLabel('Top Artists'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: artists.entries.map((e) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: RGTokens.gold.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: RGTokens.gold.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${e.key}  ${e.value}',
                    style: const TextStyle(color: RGTokens.gold, fontSize: 13),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 28),
            ],

            // ── Milestones ────────────────────────────────────────────────────
            _sectionLabel('Milestones'),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.4,
              children: milestones.map((m) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: m.achieved
                      ? RGTokens.gold.withValues(alpha: 0.12)
                      : RGTokens.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: m.achieved
                        ? RGTokens.gold.withValues(alpha: 0.4)
                        : Colors.white12,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      m.achieved ? '🏆 ${m.title}' : '🔒 ${m.title}',
                      style: TextStyle(
                        color: m.achieved ? RGTokens.gold : Colors.white38,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.description,
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              )).toList(),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RGTokens.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RGTokens.gold.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 0.8)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(color: RGTokens.gold, fontSize: 13, letterSpacing: 1.2)),
  );

  Widget _wrappedRow(String label, String value) => Row(
    children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      const Spacer(),
      Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
    ],
  );

  String _formatTime(Duration d) {
    if (d.inHours > 0) return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    return '${d.inMinutes}m';
  }
}
