import 'package:flutter/material.dart';
import '../../features/mesh/domain/models/message_envelope.dart';
import '../constants/app_colors.dart';

/// StatusBadge is a reusable UI badge component that displays the current transport delivery mode.
/// 
/// System Design & Portfolio Value:
/// Unlike traditional messaging apps that hide transport details from users, MeshSOS exposes 
/// the exact delivery path (Mesh radio hops, Cloud sync, or Cellular SMS) directly in the UI.
/// This makes network conditions transparent during disaster emergencies.
class StatusBadge extends StatelessWidget {
  /// Delivery status enum value
  final DeliveryStatus status;

  /// Optional hop count for mesh relays
  final int hopCount;

  const StatusBadge({
    super.key,
    required this.status,
    this.hopCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Determine color and text based on transport status
    final Color badgeColor;
    final IconData badgeIcon;
    final String badgeLabel;

    switch (status) {
      case DeliveryStatus.pending:
        badgeColor = AppColors.textSecondary;
        badgeIcon = Icons.hourglass_empty_rounded;
        badgeLabel = 'Pending';
        break;
      case DeliveryStatus.sentMesh:
        badgeColor = AppColors.transportMesh;
        badgeIcon = Icons.bluetooth_searching_rounded;
        badgeLabel = hopCount > 1 ? 'Mesh ($hopCount hops)' : 'Mesh (1 hop)';
        break;
      case DeliveryStatus.sentCloud:
        badgeColor = AppColors.transportCloud;
        badgeIcon = Icons.cloud_done_rounded;
        badgeLabel = 'Cloud Sync';
        break;
      case DeliveryStatus.sentSms:
        badgeColor = AppColors.transportSms;
        badgeIcon = Icons.sms_rounded;
        badgeLabel = 'SMS Fallback';
        break;
      case DeliveryStatus.delivered:
        badgeColor = AppColors.transportMesh;
        badgeIcon = Icons.done_all_rounded;
        badgeLabel = 'Delivered';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha:0.15),//semi-transparent background
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: badgeColor.withValues(alpha:0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            badgeLabel,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
