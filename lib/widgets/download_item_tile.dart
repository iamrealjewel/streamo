import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_file/open_file.dart';
import 'package:provider/provider.dart';
import '../models/download_item.dart';
import '../providers/download_provider.dart';

class DownloadItemTile extends StatelessWidget {
  final DownloadItem item;
  final bool showOpen;

  const DownloadItemTile({
    super.key,
    required this.item,
    this.showOpen = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final statusColor = _statusColor(item.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16162A) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: item.status == DownloadStatus.failed
              ? const Color(0xFFFF5722).withOpacity(0.3)
              : isDark
                  ? const Color(0xFF2A2A45)
                  : const Color(0xFFE0E0F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: item.thumbnailUrl,
                  width: 60,
                  height: 44,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => Container(
                    width: 60,
                    height: 44,
                    color: isDark
                        ? const Color(0xFF2A2A45)
                        : const Color(0xFFF0F0FF),
                    child: Icon(
                      item.type == DownloadType.audio
                          ? Icons.music_note_rounded
                          : Icons.videocam_rounded,
                      color: const Color(0xFF6B6B8A),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (item.type == DownloadType.audio
                                    ? const Color(0xFF00D4FF)
                                    : const Color(0xFFFF0050))
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                item.type == DownloadType.audio
                                    ? Icons.music_note_rounded
                                    : Icons.videocam_rounded,
                                size: 10,
                                color: item.type == DownloadType.audio
                                    ? const Color(0xFF00D4FF)
                                    : const Color(0xFFFF0050),
                              ),
                              const SizedBox(width: 3),
                              Text(
                                item.type == DownloadType.audio
                                    ? 'MP3 · ${item.quality}'
                                    : 'VIDEO · ${item.quality}',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: item.type == DownloadType.audio
                                      ? const Color(0xFF00D4FF)
                                      : const Color(0xFFFF0050),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _statusLabel(item.status),
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              Row(
                children: [
                  if (showOpen && item.filePath != null)
                    IconButton(
                      onPressed: () => OpenFile.open(item.filePath!),
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      style: IconButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50).withOpacity(0.15),
                        foregroundColor: const Color(0xFF4CAF50),
                        minimumSize: const Size(36, 36),
                        padding: EdgeInsets.zero,
                      ),
                      tooltip: 'Play file',
                    ),
                  IconButton(
                    onPressed: () =>
                        context.read<DownloadProvider>().removeDownload(item.id),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          const Color(0xFFFF5722).withOpacity(0.08),
                      foregroundColor: const Color(0xFFFF5722),
                      minimumSize: const Size(36, 36),
                      padding: EdgeInsets.zero,
                    ),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            ],
          ),
          // Progress bar (only for active)
          if (item.status == DownloadStatus.downloading ||
              item.status == DownloadStatus.converting) ...[
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: item.progress,
                backgroundColor: isDark
                    ? const Color(0xFF2A2A45)
                    : const Color(0xFFE0E0F0),
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 5,
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
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  item.status == DownloadStatus.converting
                      ? 'Converting...'
                      : 'Downloading...',
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF6B6B8A) : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ],
          // Error message
          if (item.status == DownloadStatus.failed &&
              item.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      size: 14, color: Color(0xFFFF5722)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.errorMessage!,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFFFF5722),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
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
        return 'DOWNLOADING';
      case DownloadStatus.converting:
        return 'CONVERTING';
      case DownloadStatus.completed:
        return 'DONE';
      case DownloadStatus.failed:
        return 'FAILED';
      default:
        return 'QUEUED';
    }
  }
}
