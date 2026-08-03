import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// RadarVisualizerCard renders the full-card glowing radar scanner matching Mockup 100%.
class RadarVisualizerCard extends StatefulWidget {
  final int activePeerCount;

  const RadarVisualizerCard({
    super.key,
    this.activePeerCount = 0,
  });

  @override
  State<RadarVisualizerCard> createState() => _RadarVisualizerCardState();
}

class _RadarVisualizerCardState extends State<RadarVisualizerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        // Dark green-black gradient background matching target mockup screenshot exactly
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0A1811),
            Color(0xFF12281C),
            Color(0xFF09140E),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.transportMesh.withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.transportMesh.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _MockupRadarPainter(
                angle: _controller.value * 2 * math.pi,
                peerCount: widget.activePeerCount,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MockupRadarPainter extends CustomPainter {
  final double angle;
  final int peerCount;

  _MockupRadarPainter({required this.angle, required this.peerCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // Expand radius so rings fill the ENTIRE card box edge-to-edge
    final maxRadius = size.width * 0.72;

    // 1. Draw 5 Luminous Neon Green Concentric Rings
    final glowPaint = Paint()
      ..color = AppColors.transportMesh.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5);

    final linePaint = Paint()
      ..color = AppColors.transportMesh.withOpacity(0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 1; i <= 5; i++) {
      final r = maxRadius * (i / 5);
      canvas.drawCircle(center, r, glowPaint);
      canvas.drawCircle(center, r, linePaint);
    }

    // 2. Rotating Radar Sweep Gradient Beam
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi * 0.65,
        colors: [
          AppColors.transportMesh.withOpacity(0.0),
          AppColors.transportMesh.withOpacity(0.45),
        ],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // 3. Glowing Node Dots Positioned Directly On Ring Orbits
    final nodePaint = Paint()
      ..color = AppColors.transportMesh
      ..style = PaintingStyle.fill;

    final nodeGlow = Paint()
      ..color = AppColors.transportMesh
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Radii of ring 2, 3, 4, 5
    final ringRadii = [
      maxRadius * (2 / 5),
      maxRadius * (3 / 5),
      maxRadius * (4 / 5),
      maxRadius * (5 / 5),
    ];

    final nodeAngles = [
      -math.pi * 0.25, // Top Right
      math.pi * 0.1,   // Right
      math.pi * 0.65,  // Bottom Left
      -math.pi * 0.75, // Top Left
    ];

    final drawCount = math.min(peerCount, ringRadii.length);
    for (int i = 0; i < drawCount; i++) {
      final r = ringRadii[i];
      final a = nodeAngles[i];
      final pos = Offset(
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a),
      );

      // Glowing aura
      canvas.drawCircle(pos, 11, nodeGlow);
      // Bright core dot
      canvas.drawCircle(pos, 6, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MockupRadarPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.peerCount != peerCount;
  }
}
