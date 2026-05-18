import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class StreamoLoading extends StatelessWidget {
  final double size;
  final Color? color;

  const StreamoLoading({
    super.key,
    this.size = 48.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFFFF0050);

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Circular progress start ring
          SizedBox(
            width: size * 1.48,
            height: size * 1.48,
            child: CircularProgressIndicator(
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFF0050)),
              strokeWidth: size > 40 ? 3.0 : 1.8,
              backgroundColor: const Color(0xFFFF6B00).withOpacity(0.12),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat())
              .rotate(duration: 1800.ms),
          // Logo container
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.24),
              boxShadow: [
                BoxShadow(
                  color: effectiveColor.withOpacity(0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.24),
              child: Image.asset(
                'assets/Streamo.png',
                width: size,
                height: size,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback if image asset fails to load
                  return Container(
                    color: const Color(0xFF1E1E30),
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: size * 0.6,
                    ),
                  );
                },
              ),
            ),
          )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 1000.ms,
                curve: Curves.easeInOut,
              )
              .shimmer(
                duration: 1600.ms,
                color: Colors.white.withOpacity(0.6),
                angle: 45,
              ),
        ],
      ),
    );
  }
}
