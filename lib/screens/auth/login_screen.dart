import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'register_screen.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = const Color(0xFFFF0050);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark 
                    ? [const Color(0xFF0F0F1A), const Color(0xFF1A1A2E)]
                    : [const Color(0xFFF0F0FF), Colors.white],
                ),
              ),
            ),
          ),
          // Decorative blur circles
          Positioned(
            top: -50,
            left: -50,
            child: _BlurCircle(color: primary.withOpacity(0.2), size: 200),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: _BlurCircle(color: const Color(0xFF00D4FF).withOpacity(0.15), size: 250),
          ),
          // Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF0050), Color(0xFFFF6B00)],
                        ),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: primary.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          )
                        ],
                      ),
                      child: const Icon(Icons.music_note_rounded, color: Colors.white, size: 40),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                    const SizedBox(height: 24),
                    Text(
                      'Streamo',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    Text(
                      'Ultimate HD Downloader',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF8A8AAA) : Colors.grey[600],
                        fontSize: 14,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 50),
                    
                    // Inputs
                    _AuthField(
                      controller: _emailController,
                      hint: 'Email Address',
                      icon: Icons.email_outlined,
                      isDark: isDark,
                    ).animate().slideX(begin: 0.1, delay: 600.ms).fadeIn(),
                    const SizedBox(height: 16),
                    _AuthField(
                      controller: _passwordController,
                      hint: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isDark: isDark,
                      isPassword: true,
                    ).animate().slideX(begin: 0.1, delay: 700.ms).fadeIn(),
                    
                    const SizedBox(height: 30),
                    
                    // Login Button
                    Consumer<AuthProvider>(
                      builder: (context, auth, _) {
                        return SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: auth.isLoading ? null : () {
                              auth.login(_emailController.text, _passwordController.text);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 10,
                              shadowColor: primary.withOpacity(0.4),
                            ),
                            child: auth.isLoading 
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ).animate().slideY(begin: 0.2, delay: 800.ms).fadeIn(),
                    
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ", style: TextStyle(color: isDark ? const Color(0xFF8A8AAA) : Colors.grey)),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RegisterScreen()),
                            );
                          },
                          child: Text("Register", style: TextStyle(color: primary, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1.seconds),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BlurCircle extends StatelessWidget {
  final Color color;
  final double size;
  const _BlurCircle({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true))
     .move(duration: 4.seconds, begin: const Offset(0, 0), end: const Offset(20, 20))
     .blur(begin: const Offset(50, 50), end: const Offset(80, 80));
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool isPassword;

  const _AuthField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.isPassword = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: isDark ? const Color(0xFF6B6B8A) : Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF16162A) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: isDark ? const Color(0xFF2A2A45) : const Color(0xFFE0E0F0)),
        ),
      ),
    );
  }
}
