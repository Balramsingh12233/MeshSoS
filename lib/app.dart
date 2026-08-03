import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_colors.dart';
import 'core/widgets/status_badge.dart';
import 'features/mesh/domain/models/message_envelope.dart';

/// MeshSOSApp is the root MaterialApp widget.
/// 
/// Setup Rationale:
/// Configures the MaterialApp with the high-contrast dark emergency AppTheme 
/// and displays an initial foundation preview screen showing the transport delivery badges.
class MeshSOSApp extends StatelessWidget {
  const MeshSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeshSOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('MeshSOS Emergency System'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // System Status Banner Strip
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.radar, color: AppColors.transportMesh, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Network Mode: Offline Mesh Active',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Transport Mode Indicators',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              // Transport Badges Preview
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge(status: DeliveryStatus.sentMesh, hopCount: 3),
                  StatusBadge(status: DeliveryStatus.sentCloud),
                  StatusBadge(status: DeliveryStatus.sentSms),
                  StatusBadge(status: DeliveryStatus.pending),
                ],
              ),
              const SizedBox(height: 32),
              
              // SOS Emergency Button Preview Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text(
                        'Emergency Broadcast System',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Zero-infrastructure mesh messaging active. GPS location will be attached to SOS alerts.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.sosAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {},
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: const Text(
                          'BROADCAST SOS',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}