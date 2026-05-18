import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/download_provider.dart';
import '../models/download_item.dart';
import '../widgets/download_item_tile.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<DownloadProvider>(
      builder: (context, provider, _) {
        final completed = provider.completedDownloads;
        final failed = provider.downloads
            .where((d) => d.status == DownloadStatus.failed)
            .toList();
        final all = [...completed, ...failed];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Download History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  if (completed.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => provider.clearCompleted(),
                      icon: const Icon(Icons.clear_all_rounded, size: 16),
                      label: const Text('Clear'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF8A8AAA),
                        textStyle: const TextStyle(fontSize: 12),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: all.isEmpty
                  ? _EmptyHistoryState(isDark: isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: all.length,
                      itemBuilder: (context, i) {
                        return DownloadItemTile(
                          item: all[i],
                          key: ValueKey(all[i].id),
                          showOpen: all[i].status == DownloadStatus.completed,
                        ).animate(delay: (i * 50).ms).fadeIn(duration: 300.ms);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyHistoryState extends StatelessWidget {
  final bool isDark;
  const _EmptyHistoryState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0F0FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.history_rounded,
              size: 48,
              color: Color(0xFF6B6B8A),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No downloads yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your completed downloads\nwill appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? const Color(0xFF6B6B8A) : Colors.grey[500],
              height: 1.5,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
