import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../mesh/domain/models/peer_model.dart';

/// A sleek tile representing a discovered nearby device (peer).
/// Mirrors the visual glassmorphic style of RecentChatItem.
class NearbyPeerItem extends StatelessWidget {
  final Peer peer;
  final VoidCallback onTap;

  const NearbyPeerItem({
    super.key,
    required this.peer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final initials = peer.displayName.isNotEmpty
        ? peer.displayName.substring(0, peer.displayName.length >= 2 ? 2 : 1).toUpperCase()
        : '?';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Card(
        color: AppColors.surface,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: AppColors.transportMesh.withOpacity(0.4),
            width: 1,
          ),
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
                      backgroundColor: AppColors.transportMesh.withOpacity(0.2),
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: AppColors.transportMesh,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: peer.isOnline ? AppColors.transportMesh : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.surface, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Name & Connection info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        peer.displayName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        peer.isOnline ? 'Direct BLE / WiFi Peer' : 'Offline Peer',
                        style: TextStyle(
                          color: peer.isOnline ? AppColors.transportMesh : AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Transport Mode Badge (Mesh)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.transportMesh.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.transportMesh.withOpacity(0.5), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sensors_rounded, size: 12, color: AppColors.transportMesh),
                      SizedBox(width: 4),
                      Text(
                        'Mesh',
                        style: TextStyle(
                          color: AppColors.transportMesh,
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
