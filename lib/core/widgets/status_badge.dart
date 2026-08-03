import 'package:flutter/material.dart';
import '../../features/mesh/domain/models/message_envelope.dart';
import '../constants/app_colors.dart';

/// StatusBadge renders transport mode indicators (Mesh, Cloud, SMS).
class StatusBadge extends StatelessWidget {
  final DeliveryStatus status;
  final int hopCount;
  final String? customLabel;
  final IconData? customIcon;
  final Color? customColor;

  const StatusBadge({
    super.key,
    required this.status,
    this.hopCount = 0,
    this.customLabel,
    this.customIcon,
    this.customColor,
  });

  @override
  Widget build(BuildContext context) {
    Color badgeColor = customColor ?? AppColors.textSecondary;
    IconData badgeIcon = customIcon ?? Icons.hourglass_empty_rounded;
    String badgeLabel = customLabel ?? 'Pending';

    if (customLabel == null) {
      switch (status) {
        case DeliveryStatus.pending:
          badgeColor = AppColors.textSecondary;
          badgeIcon = Icons.hourglass_empty_rounded;
          badgeLabel = 'Pending';
          break;
        case DeliveryStatus.sentMesh:
          badgeColor = AppColors.transportMesh;
          badgeIcon = Icons.hub_rounded;
          badgeLabel = hopCount > 1 ? 'Mesh $hopCount Hops' : 'Mesh 1 Hop';
          break;
        case DeliveryStatus.sentCloud:
          badgeColor = AppColors.transportCloud;
          badgeIcon = Icons.cloud_outlined;
          badgeLabel = 'Cloud Sync';
          break;
        case DeliveryStatus.sentSms:
          badgeColor = AppColors.transportSms;
          badgeIcon = Icons.chat_bubble_outline_rounded;
          badgeLabel = 'SMS Fallback';
          break;
        case DeliveryStatus.delivered:
          badgeColor = AppColors.transportMesh;
          badgeIcon = Icons.done_all_rounded;
          badgeLabel = 'Delivered';
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14), // Pill badge
        border: Border.all(color: badgeColor.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(badgeIcon, size: 12, color: badgeColor),
          const SizedBox(width: 5),
          Text(
            badgeLabel,
            style: TextStyle(
              color: badgeColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
