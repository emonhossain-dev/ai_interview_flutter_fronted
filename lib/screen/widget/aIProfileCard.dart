import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class AvatarGlowBackground extends StatelessWidget {
  final Widget? child;
  final double size;

  const AvatarGlowBackground({
    super.key,
    this.child,
    this.size = 220,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // ── Layer 1: Big blurred glow (feMorphology + feGaussianBlur) ──
          CustomPaint(
            size: Size(size, size),
            painter: _GlowPainter(),
          ),

          // ── Layer 2: Solid purple circle (the actual circle in SVG) ──
          Container(
            width: size * 0.53,
            height: size * 0.53,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF4F44FF),
            ),
          ),

          // ── Layer 3: Child (avatar image, icon, etc.) ──
          if (child != null)
            Container(
              width: size * 0.53,
              height: size * 0.53,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF4F44FF), // stroke color
              ),
              padding: const EdgeInsets.all(6), // ← এই value বাড়ালে padding বাড়বে
              child: ClipOval(child: child),
            ),
        ],
      ),
    );
  }
}

// ── CustomPainter: replicates feGaussianBlur glow ─────────
class _GlowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Multiple layered blurs to simulate feGaussianBlur stdDeviation=51.95
    // + feMorphology radius=133 (spread)
    final glowColor = const Color(0xFF3E32FF).withOpacity(0.12);

    for (int i = 5; i >= 1; i--) {
      final radius = size.width * 0.2 + (i * size.width * 0.08);
      final paint = Paint()
        ..color = glowColor
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.14);
      canvas.drawCircle(center, radius, paint);
    }

    // Core brighter glow ring just outside the circle
    final corePaint = Paint()
      ..color = const Color(0xFF4F44FF).withOpacity(0.22)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.10);
    canvas.drawCircle(center, size.width * 0.30, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────
//  AIProfileCard  — full card with glow bg + avatar + text
// ─────────────────────────────────────────────────────────

class AIProfileCard extends StatelessWidget {
  final String name;
  final String subtitle;
  final String imagePath;

  const AIProfileCard({
    super.key,
    this.name = 'Dr. Sarah (AI)',
    this.subtitle = 'Clinical Assessment',
    this.imagePath = 'assets/images/dr_sarah.png',
  });

  @override
  Widget build(BuildContext context) {
    const double glowSize = 280;
    const double topPadding = 50; // ← বাড়ালে নিচে নামবে, কমালে উপরে যাবে
    const double cardHeight = glowSize + topPadding + 60;

    return SizedBox(
      width: double.infinity,
      height: cardHeight,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [

          // ── 1. Glow + Avatar ──
          Positioned(
            top: topPadding, // AppBar থেকে দূরত্ব এখানে
            child: AvatarGlowBackground(
              size: glowSize,

              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF1A237E),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF7C6FFF),
                    size: 54,
                  ),
                ),
              ),
            ),
          ),

          // ── 2. Name + Subtitle ──
          Positioned(
            top: topPadding + glowSize - 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF7B8FCC),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),

        ],
      ),
    );
  }

}


