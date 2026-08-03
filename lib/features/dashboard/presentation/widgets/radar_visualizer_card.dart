import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// RadarVisualizerCard renders a high-tech animated radar scanner card.
/// 
/// Technical Implementation Highlights:
/// 1. CustomPainter Radar Sweep: Uses Flutter's `CustomPainter` to draw concentric 
///    radar circles and a smooth 360-degree rotating radar sweep gradient.
/// 2. Discovered Peer Nodes: Renders glowing neon green dots (`#00E676`) 
///    at radial coordinates representing nearby mesh devices discovered over radio.
/// 3. Performance & Battery Optimization: Driven by an `AnimationController` with 
///    low CPU overhead, ideal for emergency low-power mobile execution.
class RadarVisualizerCard extends StatefulWidget {
  final int activePeerCount;

  const RadarVisualizerCard({
    super.key,
    this.activePeerCount = 3,
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
    // Continuous 4-second smooth radar sweep rotation animation
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
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.transportMesh.withOpacity(0.4),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.transportMesh.withOpacity(0.08),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _RadarPainter(
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

/// CustomPainter that draws radar rings, sweep beam, and discovered node dots
class _RadarPainter extends CustomPainter {
  final double angle;
  final int peerCount;

  _RadarPainter({required this.angle, required this.peerCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = math.min(size.width, size.height) * 0.42;

    // 1. Draw 4 Concentric Radar Circles
    final circlePaint = Paint()
      ..color = AppColors.transportMesh.withOpacity(0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 1; i <= 4; i++) {
      final r = maxRadius * (i / 4);
      canvas.drawCircle(center, r, circlePaint);
    }

    // 2. Draw Rotating Radar Sweep Gradient Beam
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi * 0.5, // 90 degree sweep arc
        colors: [
          AppColors.transportMesh.withOpacity(0.0),
          AppColors.transportMesh.withOpacity(0.35),
        ],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // 3. Draw Discovered Mesh Peer Node Dots (Glowing Circles)
    final nodePaint = Paint()
      ..color = AppColors.transportMesh
      ..style = PaintingStyle.fill;

    final nodeGlowPaint = Paint()
      ..color = AppColors.transportMesh.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Fixed mock radial positions for nearby discovered peers
    final nodePositions = [
      Offset(center.dx + maxRadius * 0.5, center.dy - maxRadius * 0.3),
      Offset(center.dx - maxRadius * 0.6, center.dy + maxRadius * 0.2),
      Offset(center.dx + maxRadius * 0.2, center.dy + maxRadius * 0.6),
      Offset(center.dx - maxRadius * 0.3, center.dy - maxRadius * 0.5),
    ];

    final nodesToDraw = math.min(peerCount, nodePositions.length);
    for (int i = 0; i < nodesToDraw; i++) {
      final pos = nodePositions[i];
      // Draw outer glow effect
      canvas.drawCircle(pos, 9, nodeGlowPaint);
      // Draw solid node dot
      canvas.drawCircle(pos, 5, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.peerCount != peerCount;
  }
}
