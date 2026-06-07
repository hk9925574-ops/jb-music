// ─────────────────────────────────────────────────────────────
// FILE: lib/presentation/screens/downloads_screen.dart
// ─────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});
  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  String _quality = '320kbps';
  bool _offlineOnly = false;

  final List<Map<String, dynamic>> _downloads = [
    {'title': 'Dandelions', 'artist': 'Ruth B.', 'size': '4.2 MB', 'quality': '320kbps', 'status': 'done'},
    {'title': 'Dheema', 'artist': 'Anirudh', 'size': '3.8 MB', 'quality': '320kbps', 'status': 'done'},
    {'title': 'Dhandiya', 'artist': 'Unnimenon', 'size': '2.9 MB', 'quality': '256kbps', 'status': 'downloading', 'progress': 0.65},
    {'title': 'Blinding Lights', 'artist': 'The Weeknd', 'size': '3.1 MB', 'quality': '320kbps', 'status': 'queued'},
    {'title': 'As It Was', 'artist': 'Harry Styles', 'size': '4.8 MB', 'quality': '320kbps', 'status': 'done'},
  ];

  Color _statusColor(String s) => s == 'done'
      ? Colors.greenAccent
      : s == 'downloading'
          ? Colors.blueAccent
          : Colors.white38;

  String _statusLabel(String s) => s == 'done'
      ? 'Downloaded'
      : s == 'downloading'
          ? 'Downloading...'
          : 'Queued';

  @override
  Widget build(BuildContext context) {
    final done = _downloads.where((d) => d['status'] == 'done').length;
    final queued = _downloads.where((d) => d['status'] == 'queued').length;

    return Scaffold(
      backgroundColor: RG.black,
      appBar: AppBar(
        backgroundColor: RG.black,
        title: const Text('Downloads',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Text('23.4 MB used',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary cards ─────────────────────────────────────
          Row(
            children: [
              _summaryCard('Downloaded', done, Colors.greenAccent),
              const SizedBox(width: 10),
              _summaryCard('Queued', queued, Colors.amber),
              const SizedBox(width: 10),
              _summaryCard('Total', _downloads.length, Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 16),

          // ── Settings card ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: RG.surface, borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Download Quality',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      value: _quality,
                      dropdownColor: RG.surface,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                      underline: const SizedBox(),
                      onChanged: (v) => setState(() => _quality = v!),
                      items: ['128kbps', '256kbps', '320kbps', 'Lossless']
                          .map((q) => DropdownMenuItem(value: q, child: Text(q)))
                          .toList(),
                    ),
                  ],
                ),
                Divider(color: Colors.white.withValues(alpha: 0.08), height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Offline Mode',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                        Text('Play only downloaded tracks',
                            style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                    Switch(
                      value: _offlineOnly,
                      onChanged: (v) => setState(() => _offlineOnly = v),
                      activeThumbColor: RG.gold,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Text('Downloads (${_downloads.length})',
              style: const TextStyle(color: Colors.white54, fontSize: 13)),
          const SizedBox(height: 10),

          ..._downloads.asMap().entries.map((e) {
            final i = e.key;
            final item = e.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: RG.surface, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _statusColor(item['status']).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          item['status'] == 'done'
                              ? Icons.check_circle_outline
                              : Icons.download_outlined,
                          color: _statusColor(item['status']),
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['title'],
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(item['artist'],
                                style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _statusColor(item['status']).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _statusLabel(item['status']),
                                    style: TextStyle(
                                        color: _statusColor(item['status']),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('${item['size']} · ${item['quality']}',
                                    style: const TextStyle(
                                        color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.redAccent, size: 20),
                        onPressed: () => setState(() => _downloads.removeAt(i)),
                      ),
                    ],
                  ),
                  if (item['status'] == 'downloading') ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: item['progress'] as double,
                        minHeight: 4,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation(Colors.blueAccent),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${((item['progress'] as double) * 100).toInt()}% complete',
                        style: const TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int value, Color color) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: RG.surface, borderRadius: BorderRadius.circular(14)),
          child: Column(
            children: [
              Text('$value',
                  style: TextStyle(
                      color: color, fontSize: 24, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
            ],
          ),
        ),
      );
}