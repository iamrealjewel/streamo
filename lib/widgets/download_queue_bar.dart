import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../models/download_item.dart';

class DownloadQueueBar extends StatelessWidget {
  const DownloadQueueBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadProvider>(
      builder: (context, provider, _) {
        final active = provider.activeDownloads;
        if (active.isEmpty) return const SizedBox.shrink();

        final item = active.first;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16162A) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A2A45)
                  : const Color(0xFFE0E0F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 15,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  // Animated icon
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _statusColor(item.status).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: item.status == DownloadStatus.converting
                        ? const _SpinningIcon(
                            icon: Icons.loop_rounded,
                            color: Color(0xFF00D4FF))
                        : const _SpinningIcon(
                            icon: Icons.download_rounded,
                            color: Color(0xFFFF0050)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_statusLabel(item.status)} · ${item.quality}',
                          style: TextStyle(
                            fontSize: 10,
                            color: _statusColor(item.status),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (active.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF0050).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '+${active.length - 1} more',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFFFF0050),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.progress,
                  backgroundColor: isDark
                      ? const Color(0xFF2A2A45)
                      : const Color(0xFFE0E0F0),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _statusColor(item.status),
                  ),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(item.progress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: _statusColor(item.status),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${item.type == DownloadType.audio ? "🎵" : "🎬"} ${item.quality}',
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark
                          ? const Color(0xFF6B6B8A)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _statusColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return const Color(0xFFFF0050);
      case DownloadStatus.converting:
        return const Color(0xFF00D4FF);
      case DownloadStatus.completed:
        return const Color(0xFF4CAF50);
      case DownloadStatus.failed:
        return const Color(0xFFFF5722);
      default:
        return const Color(0xFF8A8AAA);
    }
  }

  String _statusLabel(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.downloading:
        return 'Downloading';
      case DownloadStatus.converting:
        return 'Converting to MP3';
      case DownloadStatus.completed:
        return 'Completed';
      case DownloadStatus.failed:
        return 'Failed';
      default:
        return 'Queued';
    }
  }
}

class _SpinningIcon extends StatefulWidget {
  final IconData icon;
  final Color color;

  const _SpinningIcon({required this.icon, required this.color});

  @override
  State<_SpinningIcon> createState() => _SpinningIconState();
}

class _SpinningIconState extends State<_SpinningIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Icon(widget.icon, color: widget.color, size: 18),
    );
  }
}
