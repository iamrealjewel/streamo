import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' as yt;
import 'package:url_launcher/url_launcher.dart';
import '../providers/download_provider.dart';
import '../models/queued_video.dart';
import '../widgets/video_info_card.dart';
import '../widgets/streamo_loading.dart';
import '../models/video_info.dart';
import '../services/youtube_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  List<yt.Video> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  bool _hasSearched = false;

  Future<void> _performSearch() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    _focusNode.unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
      _hasSearched = true;
    });

    final ytClient = yt.YoutubeExplode();
    try {
      final results = await ytClient.search.getVideos(query);
      setState(() {
        _searchResults = results.toList();
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch search results. Please check your internet connection.\n$e';
      });
    } finally {
      ytClient.close();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Glowing Search Bar Container
            _buildSearchBar(isDark),
            
            // Results or States
            Expanded(
              child: _buildBody(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF0F0FF),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16162A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF0050).withOpacity(isDark ? 0.05 : 0.03),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _performSearch(),
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1A1A2E),
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Search YouTube videos...',
            hintStyle: const TextStyle(color: Color(0xFF6B6B8A), fontSize: 15),
            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF0050)),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, color: Color(0xFF6B6B8A)),
                    onPressed: () {
                      setState(() {
                        _searchController.clear();
                      });
                    },
                  )
                : null,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return _buildShimmerLoading(isDark);
    }
    
    if (_error != null) {
      return _buildErrorState(isDark);
    }

    if (!_hasSearched) {
      return _buildWelcomeState(isDark);
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final video = _searchResults[index];
        return _buildVideoCard(context, video, isDark)
            .animate(delay: (index * 40).ms)
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.1, end: 0.0, curve: Curves.easeOut);
      },
    );
  }

  Widget _buildVideoCard(BuildContext context, yt.Video video, bool isDark) {
    final downloadProvider = Provider.of<DownloadProvider>(context);
    final videoId = video.id.value;
    final isQueued = downloadProvider.searchQueue.any((q) => q.id == videoId);

    // Format duration nicely
    final dur = video.duration ?? Duration.zero;
    final minutes = dur.inMinutes.remainder(60);
    final seconds = dur.inSeconds.remainder(60).toString().padLeft(2, '0');
    final durationString = dur.inHours > 0 
        ? '${dur.inHours}:${minutes.toString().padLeft(2, '0')}:$seconds' 
        : '$minutes:$seconds';

    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/mqdefault.jpg';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16162A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail Stack
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    thumbnailUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, _, __) => Container(
                      color: isDark ? const Color(0xFF252538) : Colors.grey[200],
                      child: const Icon(Icons.movie_creation_outlined, size: 40),
                    ),
                  ),
                  
                  // Play button overlay in the center
                  Center(
                    child: GestureDetector(
                      onTap: () async {
                        final uri = Uri.parse('https://youtube.com/watch?v=$videoId');
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ),
                  
                  // Duration Badge overlay
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        durationString,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Details Panel
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    video.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                      color: isDark ? Colors.white : const Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    video.author,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B6B8A),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Add to Queue / Queued Button with dynamic styling
                  Row(
                    children: [
                      // Queue Button (Left side)
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: isQueued
                              ? Container(
                                  key: const ValueKey('queued'),
                                  width: double.infinity,
                                  height: 48,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00FF87).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(
                                      color: const Color(0xFF00FF87).withOpacity(0.3),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.check_circle_rounded, color: Color(0xFF00FF87), size: 18),
                                      SizedBox(width: 6),
                                      Text(
                                        'Queued',
                                        style: TextStyle(
                                          color: Color(0xFF00FF87),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().scale(duration: 200.ms, curve: Curves.bounceOut)
                              : SizedBox(
                                  key: const ValueKey('add_to_queue'),
                                  width: double.infinity,
                                  height: 48,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFF0050), Color(0xFFFF6B00)],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFFF0050).withOpacity(0.2),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: () {
                                        downloadProvider.addToQueue(
                                          QueuedVideo(
                                            id: videoId,
                                            title: video.title,
                                            author: video.author,
                                            thumbnailUrl: thumbnailUrl,
                                            durationString: durationString,
                                            url: video.url,
                                          ),
                                        );
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.playlist_add_rounded, color: Colors.white, size: 20),
                                          SizedBox(width: 6),
                                          Text(
                                            'Queue',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Direct Download Button (Right side)
                      SizedBox(
                        width: 130,
                        height: 48,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF00D4FF), Color(0xFF0072FF)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF0072FF).withOpacity(0.25),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () => _showDirectDownloadSheet(context, video),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.download_rounded, color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  'Download',
                                  style: TextStyle(
                                    color: Colors.white,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Container(
          height: 290,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16162A) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1F35) : Colors.grey[200],
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 16,
                        width: double.infinity,
                        color: isDark ? const Color(0xFF1F1F35) : Colors.grey[200],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 12,
                        width: 120,
                        color: isDark ? const Color(0xFF1F1F35) : Colors.grey[200],
                      ),
                      const Spacer(),
                      Container(
                        height: 36,
                        width: double.infinity,
                        color: isDark ? const Color(0xFF1F1F35) : Colors.grey[200],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1000.ms,
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[100]!,
            );
      },
    );
  }

  Widget _buildWelcomeState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF16162A) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 15,
                ),
              ],
            ),
            child: const Icon(
              Icons.search_rounded,
              size: 44,
              color: Color(0xFFFF0050),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Explore YouTube',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Search videos, build your local downloads\nqueue, and transcode in batch.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF6B6B8A),
              fontSize: 13,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 50, color: Color(0xFF6B6B8A)),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Try searching for different keywords.',
            style: TextStyle(color: const Color(0xFF6B6B8A), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
            const SizedBox(height: 16),
            const Text(
              'Search Error',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B6B8A), fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _performSearch,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDirectDownloadSheet(BuildContext context, yt.Video video) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DirectDownloadBottomSheet(video: video);
      },
    );
  }
}

class _DirectDownloadBottomSheet extends StatefulWidget {
  final yt.Video video;

  const _DirectDownloadBottomSheet({required this.video});

  @override
  State<_DirectDownloadBottomSheet> createState() => _DirectDownloadBottomSheetState();
}

class _DirectDownloadBottomSheetState extends State<_DirectDownloadBottomSheet> {
  VideoInfo? _videoInfo;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInfo();
  }

  Future<void> _fetchInfo() async {
    try {
      final info = await YoutubeService.getVideoInfo(widget.video.url);
      if (mounted) {
        setState(() {
          _videoInfo = info;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF3E3E5C) : const Color(0xFFD0D0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          if (_isLoading) ...[
            const SizedBox(height: 20),
            const StreamoLoading(size: 60),
            const SizedBox(height: 24),
            Text(
              'Resolving direct download links...',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 40),
          ] else if (_error != null) ...[
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              'Failed to load video info',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
            const SizedBox(height: 20),
          ] else if (_videoInfo != null) ...[
            VideoInfoCard(videoInfo: _videoInfo!),
          ],
        ],
      ),
    );
  }
}
