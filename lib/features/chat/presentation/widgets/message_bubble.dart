import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../mesh/domain/models/message_envelope.dart';

/// MessageBubble is a Google Material 3 inspired chat bubble widget.
/// 
/// Google Product Design Highlights:
/// 1. Asymmetric Rounded Corners: Sent & received bubbles feature smooth Material 3 shapes.
/// 2. Glassmorphism Gradient: Sent messages use a subtle elevated surface container.
/// 3. Embedded Delivery Badges: Every message explicitly renders its transport mode 
///    (Mesh 3 Hops 🟢, Cloud Sync 🔵, SMS Fallback 🟠) directly beneath the text body.
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
    final Color backgroundColor = isMe ? AppColors.surfaceVariant : AppColors.surface;
    final BorderRadius borderRadius = isMe
        ? const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(18),
            bottomRight: Radius.circular(4),
          )
        : const BorderRadius.only(
            topLeft: Radius.circular(18),
            topRight: Radius.circular(18),
            bottomLeft: Radius.circular(4),
            bottomRight: Radius.circular(18),
          );

    return Align(
      alignment: bubbleAlignment,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
          border: Border.all(
            color: envelope.type == MessageType.sos
                ? AppColors.sosAccent.withOpacity(0.8)
                : AppColors.border,
            width: envelope.type == MessageType.sos ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // SOS Emergency Alert Tag if message is panic broadcast
            if (envelope.type == MessageType.sos) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.sosAccent, size: 16),
                  const SizedBox(width: 4),
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
                height: 1.3,
              ),
            ),
            const SizedBox(height: 8),

            // Delivery Status Badge & Timestamp Row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                StatusBadge(
                  status: envelope.deliveryStatus,
                  hopCount: envelope.hopCount > 0 ? envelope.hopCount : 1,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(envelope.timestamp),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Helper to format timestamp into human readable time (e.g. 10:09 AM)
  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}
