import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../providers/download_provider.dart';
import '../providers/theme_provider.dart';
import 'download_screen.dart';
import 'history_screen.dart';
import 'search_screen.dart';
import 'converter_screen.dart';
import '../widgets/download_queue_bar.dart';
import '../widgets/streamo_loading.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const SearchScreen(),
    const ConverterScreen(),
    const DownloadScreen(),
    const HistoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: isDark
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF0A0A14),
                          Color(0xFF0D0D20),
                          Color(0xFF0A0A14),
                        ],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFF0F0FF),
                          Color(0xFFE8E8FF),
                          Color(0xFFF5F0FF),
                        ],
                      ),
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    primary.withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Main content
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, isDark),
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: _pages,
                  ),
                ),
                const DownloadQueueBar(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildNavBar(context, isDark),
    );
  }

  Widget _buildAppBar(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF0050).withOpacity(0.45),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/Streamo.png',
                fit: BoxFit.cover,
                width: 40,
                height: 40,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: const Color(0xFFFF0050),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 22),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Streamo',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      height: 1,
                    ),
              ),
              Text(
                'YouTube Downloader',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isDark
                          ? const Color(0xFF6B6B8A)
                          : Colors.grey[600],
                      fontSize: 11,
                    ),
              ),
            ],
          ),
          const Spacer(),
          // Active downloads badge
          Consumer<DownloadProvider>(
            builder: (context, provider, _) {
              final active = provider.activeDownloads.length;
              return active > 0
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF0050), Color(0xFFFF6B00)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(
                            width: 8,
                            height: 8,
                            child: StreamoLoading(
                              size: 8,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$active downloading',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ).animate(onPlay: (c) => c.repeat()).shimmer(
                          duration: 2.seconds,
                          color: Colors.white.withOpacity(0.3),
                        )
                  : const SizedBox.shrink();
            },
          ),

          // Theme toggle
          GestureDetector(
            onTap: () =>
                context.read<ThemeProvider>().toggleTheme(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1A1A2E)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF2A2A45)
                      : const Color(0xFFE0E0F0),
                ),
              ),
              child: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20,
                color: isDark ? Colors.amber : const Color(0xFF4A4A6A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavBar(BuildContext context, bool isDark) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F0F1A) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE0E0F0),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _NavItem(
                icon: Icons.search_rounded,
                label: 'Search',
                selected: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
                color: primary,
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.change_circle_rounded,
                label: 'Converter',
                selected: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
                color: primary,
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.cloud_download_rounded,
                label: 'Active',
                selected: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 2),
                color: primary,
                isDark: isDark,
              ),
              _NavItem(
                icon: Icons.history_rounded,
                label: 'History',
                selected: _selectedIndex == 3,
                onTap: () => setState(() => _selectedIndex = 3),
                color: primary,
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final bool isDark;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 6),
                decoration: BoxDecoration(
                  color: selected ? color.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? color
                      : (isDark ? const Color(0xFF6B6B8A) : Colors.grey),
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? color
                      : (isDark ? const Color(0xFF6B6B8A) : Colors.grey),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
