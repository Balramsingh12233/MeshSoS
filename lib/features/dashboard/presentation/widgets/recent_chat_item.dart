import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../mesh/domain/models/message_envelope.dart';

/// RecentChatItem renders a conversation tile on the Main Dashboard screen.
/// 
/// Google Product Design Highlights:
/// - Dark glassmorphic surface card (`#1E1E1E`).
/// - Live online green indicator dot (`#00E676`) next to user avatar.
/// - Integrated transport mode badge (`Mesh`, `Cloud`, `SMS`) showing active connection mode.
/// - Tapping opens the full ChatScreen conversation.
class RecentChatItem extends StatelessWidget {
  final String peerName;
  final String lastMessageText;
  final DeliveryStatus mode;
  final VoidCallback onTap;

  const RecentChatItem({
    super.key,
    required this.peerName,
    required this.lastMessageText,
    required this.mode,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determine transport mode badge styling
    final String modeLabel;
    final Color modeColor;
    final IconData modeIcon;

    switch (mode) {
      case DeliveryStatus.sentMesh:
        modeLabel = 'Mesh';
        modeColor = AppColors.transportMesh;
        modeIcon = Icons.sensors_rounded;
        break;
      case DeliveryStatus.sentCloud:
        modeLabel = 'Cloud';
        modeColor = AppColors.transportCloud;
        modeIcon = Icons.cloud_rounded;
        break;
      case DeliveryStatus.sentSms:
        modeLabel = 'SMS';
        modeColor = AppColors.transportSms;
        modeIcon = Icons.sms_rounded;
        break;
      default:
        modeLabel = 'Mesh';
        modeColor = AppColors.transportMesh;
        modeIcon = Icons.sensors_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Row(
              children: [
                // Avatar with online green status dot
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.surfaceVariant,
                      child: const Icon(
                        Icons.person_rounded,
                        color: AppColors.textPrimary,
                        size: 24,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.transportMesh, // Green online indicator
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name & Message text preview
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peerName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        lastMessageText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Transport Mode Badge (Mesh / Cloud / SMS)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: modeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: modeColor.withOpacity(0.5), width: 1),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(modeIcon, size: 12, color: modeColor),
                      const SizedBox(width: 4),
                      Text(
                        modeLabel,
                        style: TextStyle(
                          color: modeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
