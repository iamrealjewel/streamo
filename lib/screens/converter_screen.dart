import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/download_provider.dart';
import '../models/download_item.dart';
import '../models/video_info.dart';
import '../models/queued_video.dart';
import '../widgets/url_input_section.dart';
import '../widgets/video_info_card.dart';
import '../widgets/streamo_loading.dart';

class ConverterScreen extends StatefulWidget {
  const ConverterScreen({super.key});

  @override
  State<ConverterScreen> createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFFFF0050);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF0F0FF),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: primary,
            indicatorWeight: 3,
            labelColor: primary,
            unselectedLabelColor: const Color(0xFF6B6B8A),
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.link_rounded, size: 18),
                    SizedBox(width: 8),
                    Text('Direct Link'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.playlist_play_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Batch Queue'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _DirectLinkPage(),
          const _BatchQueuePage(),
        ],
      ),
    );
  }
}

// ─── Direct Link Downloader Page ──────────────────────────────────────────────

class _DirectLinkPage extends StatelessWidget {
  const _DirectLinkPage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Consumer<DownloadProvider>(
      builder: (context, provider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Download Directly',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 6),
              Text(
                'Paste a YouTube URL to extract direct high-fidelity formats.',
                style: TextStyle(
                  color: isDark ? const Color(0xFF8A8AAA) : Colors.grey[600],
                  fontSize: 13,
                  height: 1.4,
                ),
              ).animate().fadeIn(duration: 400.ms, delay: 50.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),
              
              // URL input section
              const UrlInputSection()
                  .animate()
                  .fadeIn(duration: 400.ms, delay: 100.ms)
                  .slideY(begin: 0.1, end: 0),
              const SizedBox(height: 24),

              // Dynamic extraction views
              if (provider.isFetchingInfo) const _FetchingLoader(),
              if (provider.currentVideoInfo != null)
                VideoInfoCard(videoInfo: provider.currentVideoInfo!)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .scale(begin: const Offset(0.96, 0.96)),
              if (provider.fetchError != null) _ErrorCard(provider.fetchError!),
            ],
          ),
        );
      },
    );
  }
}

// ─── Batch Queue Downloader Page ──────────────────────────────────────────────

class _BatchQueuePage extends StatelessWidget {
  const _BatchQueuePage();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFFFF0050);

    return Consumer<DownloadProvider>(
      builder: (context, provider, _) {
        final queue = provider.searchQueue;
        final selectedItems = queue.where((v) => v.isSelected).toList();
        final allSelected = queue.isNotEmpty && selectedItems.length == queue.length;

        if (queue.isEmpty) {
          return _buildEmptyQueueState(context, isDark);
        }

        return Column(
          children: [
            // Batch Controls Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101020) : Colors.grey[50],
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: allSelected,
                    activeColor: primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                    onChanged: (val) {
                      provider.toggleAllQueueSelection(val ?? false);
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select All',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${selectedItems.length} of ${queue.length} selected',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF6B6B8A),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 22),
                    tooltip: 'Clear Queue',
                    onPressed: () {
                      provider.clearQueue();
                    },
                  ),
                ],
              ),
            ),

            // Queue List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                itemCount: queue.length,
                itemBuilder: (context, index) {
                  final video = queue[index];
                  return _buildQueuedCard(context, video, provider, isDark);
                },
              ),
            ),

            // Download Trigger Bottom Bar
            if (selectedItems.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF0F0FF),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE0E0F0),
                    ),
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF0050), Color(0xFFFF6B00)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF0050).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _showBatchOptionsSheet(context, provider, selectedItems),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_download_rounded, color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Download Selected (${selectedItems.length})',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.2, end: 0, duration: 250.ms, curve: Curves.easeOut),
              ),
          ],
        );
      },
    );
  }

  Widget _buildQueuedCard(
    BuildContext context, 
    dynamic video, 
    DownloadProvider provider, 
    bool isDark
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16162A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0),
        ),
      ),
      child: Row(
        children: [
          // Select Checkbox
          Checkbox(
            value: video.isSelected,
            activeColor: const Color(0xFFFF0050),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            onChanged: (val) {
              provider.toggleQueueSelection(video.id);
            },
          ),

          // Small Thumbnail
          Container(
            width: 80,
            height: 50,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              image: DecorationImage(
                image: NetworkImage(video.thumbnailUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      video.durationString,
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  video.author,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF6B6B8A),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Play Button
          IconButton(
            icon: const Icon(Icons.play_circle_outline_rounded, color: Color(0xFF4CAF50), size: 20),
            tooltip: 'Preview on YouTube',
            onPressed: () async {
              final uri = Uri.parse('https://youtube.com/watch?v=${video.id}');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
          ),
          // Remove Button
          IconButton(
            icon: const Icon(Icons.remove_circle_outline_rounded, color: Color(0xFF6B6B8A), size: 20),
            tooltip: 'Remove',
            onPressed: () {
              provider.removeFromQueue(video.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyQueueState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF16162A) : Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.playlist_add_rounded,
                size: 40,
                color: Color(0xFF6B6B8A),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Your Batch Queue is Empty',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Visit the Search tab, search for videos, and add them to this queue. You can then download them all at once in high quality.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF6B6B8A),
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Batch Format Selection bottom sheet ───────────────────────────────────

  void _showBatchOptionsSheet(
    BuildContext context, 
    DownloadProvider provider, 
    List<QueuedVideo> selectedItems
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFFFF0050);
    DownloadType selectedType = DownloadType.audio;
    dynamic selectedFormat = 320; // 320kbps MP3 default

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF101020) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Batch Download Options',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Processing ${selectedItems.length} videos concurrently.',
                    style: const TextStyle(color: Color(0xFF6B6B8A), fontSize: 12),
                  ),
                  const SizedBox(height: 20),

                  // Mode selector (Video vs Audio)
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedType = DownloadType.audio;
                              selectedFormat = 320; // Default MP3 kbps
                            });
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: selectedType == DownloadType.audio 
                                  ? primary.withOpacity(0.12) 
                                  : (isDark ? const Color(0xFF16162A) : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == DownloadType.audio ? primary : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.audiotrack_rounded, 
                                    color: selectedType == DownloadType.audio ? primary : const Color(0xFF6B6B8A), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Audio (MP3)',
                                  style: TextStyle(
                                    color: selectedType == DownloadType.audio ? primary : const Color(0xFF6B6B8A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedType = DownloadType.video;
                              selectedFormat = '1080p'; // Default Video quality
                            });
                          },
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: selectedType == DownloadType.video 
                                  ? primary.withOpacity(0.12) 
                                  : (isDark ? const Color(0xFF16162A) : Colors.grey[100]),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: selectedType == DownloadType.video ? primary : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.videocam_rounded, 
                                    color: selectedType == DownloadType.video ? primary : const Color(0xFF6B6B8A), size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  'Video (MP4)',
                                  style: TextStyle(
                                    color: selectedType == DownloadType.video ? primary : const Color(0xFF6B6B8A),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quality Options Selector
                  const Text(
                    'Select Download Quality:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6B6B8A)),
                  ),
                  const SizedBox(height: 10),
                  
                  if (selectedType == DownloadType.audio)
                    _buildBitrateDropdown(setModalState, selectedFormat, (val) {
                      setModalState(() => selectedFormat = val);
                    }, isDark)
                  else
                    _buildResolutionDropdown(setModalState, selectedFormat, (val) {
                      setModalState(() => selectedFormat = val);
                    }, isDark),
                  
                  const SizedBox(height: 28),

                  // Trigger batch downloads
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFFFF0050), Color(0xFFFF6B00)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        // 1. Trigger provider batch download
                        provider.startBatchDownload(
                          items: selectedItems,
                          type: selectedType,
                          formatOrBitrate: selectedFormat,
                        );

                        // 2. Remove items from search queue
                        for (final item in selectedItems) {
                          provider.removeFromQueue(item.id);
                        }

                        // 3. Close bottom sheet
                        Navigator.pop(context);
                        
                        // 4. Alert user
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Downloading ${selectedItems.length} items. Check progress in the Active tab!',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            backgroundColor: const Color(0xFFFF0050),
                            duration: const Duration(seconds: 4),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                      ),
                      child: const Text(
                        'Start Download',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBitrateDropdown(
    void Function(void Function()) setModalState, 
    dynamic currentVal, 
    void Function(int) onChange, 
    bool isDark
  ) {
    final bitrates = [320, 256, 192, 128];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: bitrates.map((b) {
        final active = currentVal == b;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChange(b),
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: active 
                    ? const Color(0xFFFF0050).withOpacity(0.08) 
                    : (isDark ? const Color(0xFF16162A) : Colors.grey[100]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? const Color(0xFFFF0050) : Colors.transparent),
              ),
              child: Center(
                child: Text(
                  '${b}k',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: active ? const Color(0xFFFF0050) : const Color(0xFF6B6B8A),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildResolutionDropdown(
    void Function(void Function()) setModalState, 
    dynamic currentVal, 
    void Function(String) onChange, 
    bool isDark
  ) {
    final resolutions = ['1080p', '720p', '480p'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: resolutions.map((r) {
        final active = currentVal == r;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChange(r),
            child: Container(
              height: 40,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: active 
                    ? const Color(0xFFFF0050).withOpacity(0.08) 
                    : (isDark ? const Color(0xFF16162A) : Colors.grey[100]),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: active ? const Color(0xFFFF0050) : Colors.transparent),
              ),
              child: Center(
                child: Text(
                  r,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: active ? const Color(0xFFFF0050) : const Color(0xFF6B6B8A),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Local Extraction Views ──────────────────────────────────────────────────

class _FetchingLoader extends StatelessWidget {
  const _FetchingLoader();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16162A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0),
        ),
      ),
      child: Column(
        children: [
          const StreamoLoading(size: 36),
          const SizedBox(height: 16),
          Text(
            'Extracting stream details...',
            style: TextStyle(
              color: isDark ? const Color(0xFF8A8AAA) : Colors.grey[600],
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1.5.seconds, color: Colors.white.withOpacity(0.05));
  }
}

class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard(this.error);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFF0050).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFF0050).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Color(0xFFFF0050), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: const TextStyle(color: Color(0xFFFF0050), fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).shakeX();
  }
}
