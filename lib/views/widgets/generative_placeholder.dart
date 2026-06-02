import 'dart:math' as math;
import 'package:flutter/material.dart';

class GenerativePlaceholder extends StatefulWidget {
  final String title;
  final String subtitle;

  const GenerativePlaceholder({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  State<GenerativePlaceholder> createState() => _GenerativePlaceholderState();
}

class _GenerativePlaceholderState extends State<GenerativePlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final int _particleCount = 35;
  final math.Random _random = math.Random(42); // Seeded for consistent baseline
  Offset? _touchPosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Initialize particles
    for (int i = 0; i < _particleCount; i++) {
      _particles.add(
        Particle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          vx: (_random.nextDouble() - 0.5) * 0.002,
          vy: (_random.nextDouble() - 0.5) * 0.002,
          radius: _random.nextDouble() * 2.5 + 1.5,
          phase: _random.nextDouble() * math.pi * 2,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanUpdate: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          setState(() {
            _touchPosition = box.globalToLocal(details.globalPosition);
          });
        }
      },
      onPanEnd: (_) {
        setState(() {
          _touchPosition = null;
        });
      },
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          setState(() {
            _touchPosition = box.globalToLocal(details.globalPosition);
          });
        }
      },
      onTapUp: (_) {
        setState(() {
          _touchPosition = null;
        });
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: ParticlePainter(
              particles: _particles,
              animationValue: _controller.value,
              touchPosition: _touchPosition,
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // A glowing circular frame representing the empty state
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.tealAccent.withValues(alpha: 0.04),
                        border: Border.all(
                          color: Colors.tealAccent.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.library_books_outlined,
                        size: 48,
                        color: Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class Particle {
  double x; // normalized 0.0 - 1.0
  double y; // normalized 0.0 - 1.0
  double vx;
  double vy;
  final double radius;
  final double phase;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.radius,
    required this.phase,
  });

  void update(double animationValue, Offset? touchPosition, Size size) {
    // Drifts
    x += vx;
    y += vy;

    // Bounce off normalized bounds
    if (x < 0 || x > 1) vx = -vx;
    if (y < 0 || y > 1) vy = -vy;

    // React to touch position
    if (touchPosition != null) {
      double px = x * size.width;
      double py = y * size.height;
      double dx = px - touchPosition.dx;
      double dy = py - touchPosition.dy;
      double dist = math.sqrt(dx * dx + dy * dy);

      if (dist < 120 && dist > 0) {
        // Push force away from touch
        double force = (120 - dist) / 120 * 0.005;
        vx += (dx / dist) * force;
        vy += (dy / dist) * force;

        // Clamp velocity
        double speed = math.sqrt(vx * vx + vy * vy);
        if (speed > 0.005) {
          vx = (vx / speed) * 0.005;
          vy = (vy / speed) * 0.005;
        }
      }
    }
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Offset? touchPosition;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.touchPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.tealAccent.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    // Update and draw particles
    for (int i = 0; i < particles.length; i++) {
      final p1 = particles[i];
      p1.update(animationValue, touchPosition, size);

      final p1X = p1.x * size.width;
      final p1Y = p1.y * size.height;

      // Draw particle glow
      final double glowOpacity =
          0.2 + 0.1 * math.sin(animationValue * math.pi * 2 + p1.phase);
      final glowPaint = Paint()
        ..color = Colors.tealAccent.withValues(alpha: glowOpacity)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(p1X, p1Y), p1.radius, glowPaint);

      // Web connections - O(P^2) but with small P (35) it is extremely fast and performant.
      for (int j = i + 1; j < particles.length; j++) {
        final p2 = particles[j];
        final p2X = p2.x * size.width;
        final p2Y = p2.y * size.height;

        final double dx = p1X - p2X;
        final double dy = p1Y - p2Y;
        final double dist = math.sqrt(dx * dx + dy * dy);

        if (dist < 100) {
          // Fade connection line based on distance
          final double opacity = (1.0 - (dist / 100)) * 0.15;
          paint.color = Colors.tealAccent.withValues(alpha: opacity);
          canvas.drawLine(Offset(p1X, p1Y), Offset(p2X, p2Y), paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) => true;
}
