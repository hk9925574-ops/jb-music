// lib/presentation/screens/features/queue_screen.dart
// JB Music — Smart Queue Screen
// Displays upcoming queue with drag-to-reorder, remove, clear, source badges.

import 'package:flutter/material.dart';
import 'package:jb_music/core/ai/smart_queue.dart';
import 'package:jb_music/core/theme/rg_tokens.dart';

class QueueScreen extends StatefulWidget {
  final JBSmartQueue queue;
  final void Function(JBSmartQueue) onQueueChanged;

  const QueueScreen({
    super.key,
    required this.queue,
    required this.onQueueChanged,
  });

  @override
  State<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends State<QueueScreen> {
  @override
  void initState() {
    super.initState();
    widget.queue.onQueueChanged = () {
      if (mounted) setState(() {});
      widget.onQueueChanged(widget.queue);
    };
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.queue.items;

    return Scaffold(
      backgroundColor: RGTokens.background,
      appBar: AppBar(
        backgroundColor: RGTokens.background,
        title: const Text('Up Next', style: TextStyle(color: RGTokens.gold)),
        iconTheme: const IconThemeData(color: RGTokens.gold),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () {
                widget.queue.clear();
                setState(() {});
              },
              child: const Text('Clear', style: TextStyle(color: Colors.white54)),
            ),
        ],
      ),
      body: items.isEmpty
          ? _buildEmpty()
          : ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: items.length,
              
                // CORRECT — named parameter with typed arguments
              onReorder: (int oldIndex, int newIndex) {
                widget.queue.reorder(oldIndex, newIndex);
                setState(() {});
              },
              
              itemBuilder: (context, index) {
                final item = items[index];
                return Dismissible(
                  key: ValueKey(item.song.id + index.toString()),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    color: Colors.red.shade900,
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) {
                    widget.queue.remove(item.song.id);
                    setState(() {});
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    decoration: BoxDecoration(
                      color: RGTokens.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          color: RGTokens.gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(color: RGTokens.gold, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      ),
                      title: Text(
                        item.song.title,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Row(
                        children: [
                          Text(
                            item.song.artist,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          _sourceBadge(item.source),
                        ],
                      ),
                      trailing: const Icon(Icons.drag_handle, color: Colors.white24),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmpty() => const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.queue_music, color: Colors.white24, size: 64),
        SizedBox(height: 16),
        Text('Queue is empty', style: TextStyle(color: Colors.white38, fontSize: 16)),
        SizedBox(height: 8),
        Text(
          'Long-press any song to add it here',
          style: TextStyle(color: Colors.white24, fontSize: 13),
        ),
      ],
    ),
  );

  Widget _sourceBadge(QueueSource source) {
    final (label, color) = switch (source) {
      QueueSource.aiDj    => ('AI DJ', Colors.purple),
      QueueSource.mood    => ('Mood', Colors.blue),
      QueueSource.athlete => ('Athlete', Colors.green),
      QueueSource.manual  => ('Manual', Colors.white38),
      QueueSource.history => ('History', Colors.orange),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }
}