import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// RadarVisualizerCard renders an immersive full-card animated radar scanner.
/// 
/// Design Precision (Matching Mockup Image 2):
/// 1. Full-Card Expanding Orbital Rings: Concentric radar circles expand across 
///    the full width of the card container instead of being constrained to a small center circle.
/// 2. Luminous Neon Green Glow: Uses Paint mask filters and multi-layered stroke 
///    effects to give the radar rings and orbital node points a vibrant neon glow (`#00E676`).
/// 3. Orbital Node Points: Node dots sit directly along the circular orbital paths.
class RadarVisualizerCard extends StatefulWidget {
  final int activePeerCount;

  const RadarVisualizerCard({
    super.key,
    this.activePeerCount = 4,
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
    // 5-second smooth rotating radar sweep
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
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
      height: 220, // Increased height for full-card immersive radar
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.transportMesh.withOpacity(0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.transportMesh.withOpacity(0.12),
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
              painter: _ImmersiveRadarPainter(
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

/// CustomPainter delivering full-card glowing radar visuals
class _ImmersiveRadarPainter extends CustomPainter {
  final double angle;
  final int peerCount;

  _ImmersiveRadarPainter({required this.angle, required this.peerCount});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Set maxRadius large enough so rings fill full container width
    final maxRadius = size.width * 0.65;

    // 1. Draw 5 Glowing Concentric Orbital Rings
    final glowPaint = Paint()
      ..color = AppColors.transportMesh.withOpacity(0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

    final linePaint = Paint()
      ..color = AppColors.transportMesh.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 1; i <= 5; i++) {
      final r = maxRadius * (i / 5);
      // Draw outer neon glow ring
      canvas.drawCircle(center, r, glowPaint);
      // Draw crisp inner ring
      canvas.drawCircle(center, r, linePaint);
    }

    // 2. Draw Rotating Radar Sweep Gradient Beam
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        center: Alignment.center,
        startAngle: 0.0,
        endAngle: math.pi * 0.6, // 108 degree sweep arc
        colors: [
          AppColors.transportMesh.withOpacity(0.0),
          AppColors.transportMesh.withOpacity(0.4),
        ],
        transform: GradientRotation(angle),
      ).createShader(Rect.fromCircle(center: center, radius: maxRadius));

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // 3. Draw Discovered Mesh Peer Node Dots Along Orbital Rings
    final nodeSolidPaint = Paint()
      ..color = AppColors.transportMesh
      ..style = PaintingStyle.fill;

    final nodeGlowPaint = Paint()
      ..color = AppColors.transportMesh
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    // Calculate node positions along specific orbital ring radii & angles matching mockup image 2
    final ringRadii = [
      maxRadius * (2 / 5),
      maxRadius * (3 / 5),
      maxRadius * (4 / 5),
      maxRadius * (5 / 5),
    ];

    final nodeAngles = [
      -math.pi * 0.2, // Top right orbital
      math.pi * 0.15,  // Mid right orbital
      math.pi * 0.7,   // Bottom left orbital
      -math.pi * 0.8,  // Top left orbital
    ];

    final countToDraw = math.min(peerCount, ringRadii.length);
    for (int i = 0; i < countToDraw; i++) {
      final r = ringRadii[i];
      final a = nodeAngles[i];
      final pos = Offset(
        center.dx + r * math.cos(a),
        center.dy + r * math.sin(a),
      );

      // Draw strong neon glow outer aura
      canvas.drawCircle(pos, 10, nodeGlowPaint);
      // Draw inner solid node dot
      canvas.drawCircle(pos, 6, nodeSolidPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ImmersiveRadarPainter oldDelegate) {
    return oldDelegate.angle != angle || oldDelegate.peerCount != peerCount;
  }
}
