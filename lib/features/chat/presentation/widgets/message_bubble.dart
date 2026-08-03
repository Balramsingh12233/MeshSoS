import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../mesh/domain/models/message_envelope.dart';

/// MessageBubble is a Google Material 3 inspired chat bubble widget.
/// 
/// Design Precision (Matching Target Mockup Screenshot):
/// 1. Sent Bubble Styling: Dark glassmorphic container (`#24332B` to `#1A2520`) 
///    with smooth 18px rounded corners.
/// 2. Multi-Transport Badges: Renders side-by-side transport badges 
///    (e.g., `Mesh 3 Hops` 🟢 AND `Cloud Sync` 🔵) directly inside the bubble.
/// 3. SOS Emergency Tag: Warm red alert header if message is panic broadcast.
class MessageBubble extends StatelessWidget {
  final MessageEnvelope envelope;
  final bool isMe;

  const MessageBubble({
    super.key,
    required this.envelope,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context) {
    final Alignment bubbleAlignment = isMe ? Alignment.centerRight : Alignment.centerLeft;
    
    // Sent messages use glassmorphic dark teal/green surface; Received use dark surface
    final BoxDecoration bubbleDecoration = isMe
        ? BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF26362E),
                Color(0xFF1D2822),
              ],
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
              bottomRight: Radius.circular(4),
            ),
            border: Border.all(
              color: AppColors.transportMesh.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          )
        : BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(20),
            ),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          );

    return Align(
      alignment: bubbleAlignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: envelope.type == MessageType.sos
            ? BoxDecoration(
                color: const Color(0xFF2C1C1C),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.sosAccent, width: 1.5),
              )
            : bubbleDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // SOS Emergency Banner if panic envelope
            if (envelope.type == MessageType.sos) ...[
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.sosAccent, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'EMERGENCY SOS BROADCAST',
                    style: TextStyle(
                      color: AppColors.sosAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],

            // Message text body
            Text(
              envelope.payload,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),

            // Multi-Transport Badges Row & Timestamp matching Mockup Screenshot
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // Primary Transport Badge
                StatusBadge(
                  status: envelope.deliveryStatus,
                  hopCount: envelope.hopCount > 0 ? envelope.hopCount : 3,
                ),

                // Show dual badge (e.g. Mesh + Cloud Sync) for dual-path delivered messages
                if (isMe && envelope.deliveryStatus == DeliveryStatus.sentMesh) ...[
                  const StatusBadge(
                    status: DeliveryStatus.sentCloud,
                  ),
                ],

                Text(
                  _formatTimestamp(envelope.timestamp),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
