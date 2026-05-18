import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/download_provider.dart';
import '../widgets/download_item_tile.dart';

class DownloadScreen extends StatelessWidget {
  const DownloadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<DownloadProvider>(
      builder: (context, provider, _) {
        final active = provider.activeDownloads;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Active Downloads',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const Spacer(),
                  if (active.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0050).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${active.length} active',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFFFF0050),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: active.isEmpty
                  ? _EmptyQueueState(isDark: isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: active.length,
                      itemBuilder: (context, i) {
                        return DownloadItemTile(
                          item: active[i],
                          key: ValueKey(active[i].id),
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

class _EmptyQueueState extends StatelessWidget {
  final bool isDark;
  const _EmptyQueueState({required this.isDark});

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
              Icons.download_done_rounded,
              size: 48,
              color: Color(0xFF6B6B8A),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No active downloads',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start downloading from the\nDownload tab.',
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
