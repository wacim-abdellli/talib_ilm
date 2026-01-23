import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A single particle with its properties
class _Particle {
  double x;
  double y;
  double dx; // Horizontal drift velocity
  double dy; // Upward velocity
  double size;
  double opacity;
  double fadeDirection; // 1 = fading in, -1 = fading out
  Color color;

  _Particle({
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.size,
    required this.opacity,
    required this.fadeDirection,
    required this.color,
  });
}

/// Floating particles effect for ambient background
class FloatingParticles extends StatefulWidget {
  final int particleCount;
  final Color primaryColor;
  final Color secondaryColor;
  final bool enabled;

  const FloatingParticles({
    super.key,
    this.particleCount = 40,
    this.primaryColor = const Color(0xFF14B8A6), // Teal
    this.secondaryColor = Colors.white,
    this.enabled = true,
  });

  @override
  State<FloatingParticles> createState() => _FloatingParticlesState();
}

class _FloatingParticlesState extends State<FloatingParticles>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  Size _screenSize = Size.zero;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 16), // ~60fps
      vsync: this,
    )..addListener(_updateParticles);

    if (widget.enabled) {
      _controller.repeat();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final newSize = MediaQuery.of(context).size;
    if (!_initialized || _screenSize != newSize) {
      _screenSize = newSize;
      _initializeParticles();
      _initialized = true;
    }
  }

  @override
  void didUpdateWidget(FloatingParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  void _initializeParticles() {
    _particles.clear();
    for (int i = 0; i < widget.particleCount; i++) {
      _particles.add(_createParticle(randomY: true));
    }
  }

  _Particle _createParticle({bool randomY = false}) {
    final isTeal = _random.nextBool();
    return _Particle(
      x: _random.nextDouble() * _screenSize.width,
      y: randomY
          ? _random.nextDouble() * _screenSize.height
          : _screenSize.height + _random.nextDouble() * 50,
      dx: (_random.nextDouble() - 0.5) * 0.3, // Slight horizontal drift
      dy: -(0.3 + _random.nextDouble() * 0.5), // Upward movement
      size: 2 + _random.nextDouble() * 4, // 2-6
      opacity: 0.1 + _random.nextDouble() * 0.2, // 0.1-0.3
      fadeDirection: 1,
      color: isTeal ? widget.primaryColor : widget.secondaryColor,
    );
  }

  void _updateParticles() {
    if (!mounted) return;

    for (int i = 0; i < _particles.length; i++) {
      final p = _particles[i];

      // Update position
      p.x += p.dx;
      p.y += p.dy;

      // Add slight wave motion
      p.x += math.sin(p.y * 0.01) * 0.2;

      // Fade animation
      p.opacity += p.fadeDirection * 0.005;
      if (p.opacity >= 0.3) {
        p.fadeDirection = -1;
      } else if (p.opacity <= 0.05) {
        p.fadeDirection = 1;
      }
      p.opacity = p.opacity.clamp(0.05, 0.3);

      // Reset particle if off-screen (top)
      if (p.y < -20) {
        _particles[i] = _createParticle();
      }

      // Wrap horizontally
      if (p.x < -10) {
        p.x = _screenSize.width + 10;
      } else if (p.x > _screenSize.width + 10) {
        p.x = -10;
      }
    }

    // Trigger repaint
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled || _particles.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(particles: _particles),
        size: Size.infinite,
      ),
    );
  }
}

/// Custom painter for rendering particles
class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;

  const _ParticlePainter({required this.particles});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      final paint = Paint()
        ..color = particle.color.withValues(alpha: particle.opacity)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1);

      canvas.drawCircle(Offset(particle.x, particle.y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
