import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/video_info.dart';
import '../providers/download_provider.dart';

import '../providers/auth_provider.dart';
import '../models/user_model.dart';
import '../screens/subscription_screen.dart';

class FormatSelectorSheet extends StatelessWidget {
  final VideoInfo videoInfo;
  final bool isAudio;

  const FormatSelectorSheet({
    super.key,
    required this.videoInfo,
    required this.isAudio,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isAudio ? const Color(0xFF00D4FF) : const Color(0xFFFF0050);
    final user = context.watch<AuthProvider>().currentUser!;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F0F1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF2A2A45)
                        : const Color(0xFFE0E0F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isAudio
                            ? Icons.music_note_rounded
                            : Icons.video_file_rounded,
                        color: primary,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isAudio
                                ? 'Select MP3 Bitrate'
                                : 'Select Video Quality',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            isAudio
                                ? 'Higher bitrate = better audio quality'
                                : 'Higher resolution = larger file size',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isDark
                                      ? const Color(0xFF8A8AAA)
                                      : Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded,
                          color: isDark
                              ? const Color(0xFF6B6B8A)
                              : Colors.grey),
                    ),
                  ],
                ),
              ),
              // User Status Info
              if (user.tier == SubscriptionTier.starter)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFD4AF37), size: 16),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Starter Plan: 4K & 320kbps are locked.',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFD4AF37)),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        child: const Text('Upgrade', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ).animate().shimmer(duration: 2.seconds),
              Divider(
                color: isDark
                    ? const Color(0xFF2A2A45)
                    : const Color(0xFFE0E0F0),
                height: 1,
              ),
              // Format list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: isAudio
                      ? _buildAudioOptions(context, isDark, primary, user)
                      : _buildVideoOptions(context, isDark, primary, user),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildVideoOptions(
      BuildContext context, bool isDark, Color primary, UserModel user) {
    final formats = videoInfo.videoFormats;
    if (formats.isEmpty) {
      return [_emptyState(isDark, 'No video formats available')];
    }

    return formats.asMap().entries.map((entry) {
      final i = entry.key;
      final format = entry.value;
      final isBest = i == 0;
      final isLocked = user.tier == SubscriptionTier.starter && format.height > 1080;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _FormatTile(
          leading: _resolutionBadge(format, isDark, isLocked),
          title: format.displayLabel,
          subtitle: _videoSubtitle(format),
          badge: isBest ? 'BEST' : (isLocked ? 'PRO ONLY' : null),
          badgeColor: isLocked ? const Color(0xFFD4AF37) : primary,
          color: isLocked ? Colors.grey : primary,
          isDark: isDark,
          icon: isLocked ? Icons.lock_rounded : Icons.video_file_rounded,
          onTap: () {
            if (isLocked) {
              _showUpgradePrompt(context);
              return;
            }
            Navigator.pop(context);
            context.read<DownloadProvider>().startVideoDownload(
                  videoInfo: videoInfo,
                  format: format,
                );
            _showDownloadStarted(context, format.displayLabel, false);
          },
        ),
      ).animate(delay: (i * 40).ms).fadeIn(duration: 200.ms).slideX(begin: 0.1);
    }).toList();
  }

  List<Widget> _buildAudioOptions(
      BuildContext context, bool isDark, Color primary, UserModel user) {
    final bitrates = AudioBitrate.all;

    return bitrates.asMap().entries.map((entry) {
      final i = entry.key;
      final bitrate = entry.value;
      final isBest = i == 0;
      final isLocked = user.tier == SubscriptionTier.starter && bitrate.kbps > 128;

      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _FormatTile(
          leading: _bitrateBadge(bitrate.kbps, isDark, isLocked),
          title: '${bitrate.kbps} kbps',
          subtitle: _bitrateSubtitle(bitrate.kbps),
          badge: isLocked ? 'PRO ONLY' : (isBest ? 'STUDIO' : null),
          badgeColor: isLocked ? const Color(0xFFD4AF37) : primary,
          color: isLocked ? Colors.grey : primary,
          isDark: isDark,
          icon: isLocked ? Icons.lock_rounded : Icons.music_note_rounded,
          onTap: () {
            if (isLocked) {
              _showUpgradePrompt(context);
              return;
            }
            Navigator.pop(context);
            context.read<DownloadProvider>().startAudioDownload(
                  videoInfo: videoInfo,
                  bitrate: bitrate,
                );
            _showDownloadStarted(context, '${bitrate.kbps}kbps MP3', true);
          },
        ),
      ).animate(delay: (i * 60).ms).fadeIn(duration: 200.ms).slideX(begin: 0.1);
    }).toList();
  }

  Widget _resolutionBadge(VideoFormat format, bool isDark, bool isLocked) {
    Color color;
    if (isLocked) {
      color = const Color(0xFF8A8AAA);
    } else if (format.height >= 2160) {
      color = const Color(0xFFFFD700);
    } else if (format.height >= 1440) {
      color = const Color(0xFF9B59B6);
    } else if (format.height >= 1080) {
      color = const Color(0xFFFF0050);
    } else if (format.height >= 720) {
      color = const Color(0xFF00D4FF);
    } else {
      color = const Color(0xFF6B6B8A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked) ...[
            const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF8A8AAA)),
            const SizedBox(width: 4),
          ],
          Text(
            '${format.height}p',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _bitrateBadge(int kbps, bool isDark, bool isLocked) {
    Color color;
    if (isLocked) {
      color = const Color(0xFF8A8AAA);
    } else if (kbps >= 256) {
      color = const Color(0xFF00D4FF);
    } else if (kbps >= 128) {
      color = const Color(0xFF4CAF50);
    } else {
      color = const Color(0xFF6B6B8A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLocked) ...[
            const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF8A8AAA)),
            const SizedBox(width: 4),
          ],
          Text(
            '${kbps}k',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  void _showUpgradePrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.star_rounded, color: Color(0xFFD4AF37)),
            SizedBox(width: 10),
            Text('Pro Feature'),
          ],
        ),
        content: const Text('Higher quality downloads (4K/320kbps) are exclusive to Streamo Pro members.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe Later')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()));
            }, 
            child: const Text('View Plans'),
          ),
        ],
      ),
    );
  }


  String _videoSubtitle(VideoFormat format) {
    final parts = <String>[];
    parts.add(format.container.toUpperCase());
    if (format.fps > 30) parts.add('${format.fps} FPS');
    parts.add(format.hasAudio ? 'Video + Audio' : 'Video only (merged)');
    if (format.bitrate != null) parts.add('~${format.bitrate}kbps');
    return parts.join(' · ');
  }

  String _bitrateSubtitle(int kbps) {
    if (kbps >= 320) return 'Studio quality · Best for audiophiles';
    if (kbps >= 256) return 'High fidelity · Near-lossless';
    if (kbps >= 192) return 'High quality · Recommended';
    if (kbps >= 128) return 'Standard quality · Good for most uses';
    if (kbps >= 96) return 'Medium quality · Smaller file size';
    return 'Low quality · Smallest file size';
  }

  Widget _emptyState(bool isDark, String msg) {
    return Center(
      child: Text(msg,
          style: TextStyle(
              color: isDark ? const Color(0xFF6B6B8A) : Colors.grey)),
    );
  }

  void _showDownloadStarted(BuildContext context, String quality, bool isAudio) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isAudio ? Icons.music_note_rounded : Icons.download_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${isAudio ? "Converting" : "Downloading"} $quality...',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}

class _FormatTile extends StatelessWidget {
  final Widget leading;
  final String title;
  final String subtitle;
  final String? badge;
  final Color badgeColor;
  final Color color;
  final bool isDark;
  final IconData icon;
  final VoidCallback onTap;

  const _FormatTile({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.badge,
    required this.badgeColor,
    required this.color,
    required this.isDark,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16162A) : const Color(0xFFF8F8FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0),
          ),
        ),
        child: Row(
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: badgeColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            badge!,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: badgeColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? const Color(0xFF8A8AAA)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.download_rounded, color: color, size: 18),
            ),
          ],
        ),
      ),
    );
  }
}
