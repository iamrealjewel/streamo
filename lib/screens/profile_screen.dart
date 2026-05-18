import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/user_model.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFFFF0050);

    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, auth, theme, _) {
        final user = auth.currentUser!;
        
        return Scaffold(
          appBar: AppBar(
            title: const Text('Streamo Standalone Settings'),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Profile Header
                _buildProfileHeader(context, user, isDark),
                const SizedBox(height: 30),
                
                // Subscription Card
                _buildSubscriptionCard(context, user, isDark, primary),
                const SizedBox(height: 24),
                
                // Local Preferences
                _buildSettingsSection(
                  context, 
                  'Preferences', 
                  [
                    ListTile(
                      leading: Icon(isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded, size: 20),
                      title: const Text('Theme Mode', style: TextStyle(fontSize: 14)),
                      trailing: Switch(
                        value: theme.themeMode == ThemeMode.dark,
                        activeColor: primary,
                        onChanged: (val) {
                          theme.toggleTheme();
                        },
                      ),
                    ),
                  ],
                  isDark
                ),
                
                const SizedBox(height: 24),
                
                // App Information Section
                _buildSettingsSection(
                  context, 
                  'App Information', 
                  [
                    const _InfoTile(
                      icon: Icons.info_outline_rounded,
                      title: 'Version',
                      value: '1.0.0 (Standalone Mode)',
                    ),
                    const _InfoTile(
                      icon: Icons.android_rounded,
                      title: 'Platform',
                      value: 'Android Only (No Login Required)',
                    ),
                    const _InfoTile(
                      icon: Icons.hd_rounded,
                      title: 'Features',
                      value: 'All premium features unlocked (best video resolutions, high bitrates)',
                    ),
                  ],
                  isDark
                ),
                
                const SizedBox(height: 40),
                
                // Developer Credits Footer
                Center(
                  child: Column(
                    children: [
                      const Text(
                        'YT MP3 & STREAMO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2.0,
                          color: Color(0xFFFF0050),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Standalone Developer Edition',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF6B6B8A) : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserModel user, bool isDark) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(colors: [Color(0xFFFF0050), Color(0xFFFF6B00)]),
            boxShadow: [BoxShadow(color: const Color(0xFFFF0050).withOpacity(0.3), blurRadius: 20)],
          ),
          child: const Center(
            child: Icon(
              Icons.bolt_rounded,
              size: 40,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Streamo Pro User', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text('Local Off-Grid Standalone Mode', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF8A8AAA) : Colors.grey)),
      ],
    );
  }

  Widget _buildSubscriptionCard(BuildContext context, UserModel user, bool isDark, Color primary) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E2DE2), Color(0xFF4A00E0)], // Beautiful glowing purple-blue gradient
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.stars_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text(
                'Current Tier: PRO UNLOCKED',
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
              Spacer(),
              Icon(Icons.check_circle, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'You are running in developer standalone mode. The weekly limit checks, login requirements, and resolution locks are fully deactivated. Enjoy 8K, 4K, and 320kbps conversion capabilities directly on your device.',
            style: TextStyle(
              fontSize: 13, 
              height: 1.4,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, String title, List<Widget> children, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title, 
            style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold, 
              letterSpacing: 1.2,
              color: isDark ? const Color(0xFF6B6B8A) : Colors.grey[600],
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16162A) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0)),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoTile({required this.icon, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      leading: Icon(icon, size: 20),
      title: Text(title, style: const TextStyle(fontSize: 14)),
      trailing: Container(
        width: 180,
        alignment: Alignment.centerRight,
        child: Text(
          value,
          textAlign: TextAlign.end,
          maxLines: 2,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFF8A8AAA) : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
