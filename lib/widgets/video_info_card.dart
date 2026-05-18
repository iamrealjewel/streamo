import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/video_info.dart';
import 'format_selector_sheet.dart';
import 'streamo_loading.dart';

class VideoInfoCard extends StatelessWidget {
  final VideoInfo videoInfo;

  const VideoInfoCard({super.key, required this.videoInfo});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16162A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: CachedNetworkImage(
                    imageUrl: videoInfo.thumbnailUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: isDark
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFF0F0FF),
                      child: const Center(
                        child: StreamoLoading(size: 24),
                      ),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      color: isDark
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFF0F0FF),
                      child: const Icon(Icons.videocam_off_rounded,
                          size: 48, color: Color(0xFF6B6B8A)),
                    ),
                  ),
                ),
                // Duration badge
                Positioned(
                  bottom: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      videoInfo.durationString,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                // YouTube play overlay
                Positioned.fill(
                  child: Center(
                    child: GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('https://youtube.com/watch?v=${videoInfo.id}');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF0050).withOpacity(0.85),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF0050).withOpacity(0.4),
                              blurRadius: 20,
                            )
                          ],
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 32),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Info section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  videoInfo.title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.person_rounded,
                        size: 14, color: Color(0xFF8A8AAA)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        videoInfo.author,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF8A8AAA),
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D4FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF00D4FF).withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${videoInfo.videoFormats.length} formats',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF00D4FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Download buttons
                Row(
                  children: [
                    Expanded(
                      child: _DownloadButton(
                        icon: Icons.video_file_rounded,
                        label: 'Download Video',
                        subtitle: 'All resolutions',
                        color: const Color(0xFFFF0050),
                        onTap: () => _showVideoFormats(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DownloadButton(
                        icon: Icons.music_note_rounded,
                        label: 'Convert to MP3',
                        subtitle: 'All bitrates',
                        color: const Color(0xFF00D4FF),
                        onTap: () => _showAudioBitrates(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showVideoFormats(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FormatSelectorSheet(
        videoInfo: videoInfo,
        isAudio: false,
      ),
    );
  }

  void _showAudioBitrates(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FormatSelectorSheet(
        videoInfo: videoInfo,
        isAudio: true,
      ),
    );
  }
}

class _DownloadButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DownloadButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: color,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 10,
                color: color.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
          begin: const Offset(1, 1),
          end: const Offset(0.97, 0.97),
          duration: 100.ms,
        );
  }
}
