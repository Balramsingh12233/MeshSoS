import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../mesh/domain/models/message_envelope.dart';

/// NetworkStatusStrip is a top banner widget showing live mesh & cloud connectivity.
/// 
/// System Design & UI Rationale:
/// - In disaster scenarios, connectivity changes dynamically (e.g. losing cell service, finding BLE peers).
/// - This persistent strip gives users instant, at-a-glance feedback on active radio transport.
class NetworkStatusStrip extends StatelessWidget {
  /// Current active transport mode
  final DeliveryStatus currentMode;

  /// Number of active BLE/WiFi Direct peer nodes connected in range
  final int activePeerCount;

  const NetworkStatusStrip({
    super.key,
    this.currentMode = DeliveryStatus.sentMesh,
    this.activePeerCount = 3,
  });

  @override
  Widget build(BuildContext context) {
    final String labelText;
    final Color badgeColor;
    final IconData statusIcon;

    switch (currentMode) {
      case DeliveryStatus.sentMesh:
        labelText = 'Mesh Active - $activePeerCount Peers Nearby';
        badgeColor = AppColors.transportMesh;
        statusIcon = Icons.sensors_rounded;
        break;
      case DeliveryStatus.sentCloud:
        labelText = 'Cloud Sync - Server Connected';
        badgeColor = AppColors.transportCloud;
        statusIcon = Icons.cloud_done_rounded;
        break;
      case DeliveryStatus.sentSms:
        labelText = 'SMS Fallback - Telephony Active';
        badgeColor = AppColors.transportSms;
        statusIcon = Icons.signal_cellular_alt_rounded;
        break;
      default:
        labelText = 'Mesh Scanning...';
        badgeColor = AppColors.textSecondary;
        statusIcon = Icons.radar_rounded;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.surface,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: badgeColor.withOpacity(0.18),
            borderRadius: BorderRadius.circular(20), // Pill shape
            border: Border.all(color: badgeColor.withOpacity(0.6), width: 1.2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(statusIcon, color: badgeColor, size: 16),
              const SizedBox(width: 8),
              Text(
                labelText,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
