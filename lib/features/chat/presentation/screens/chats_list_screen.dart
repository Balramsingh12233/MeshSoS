import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../mesh/domain/models/message_envelope.dart';
import 'chat_screen.dart';

/// Data class representing a conversation item in the WhatsApp-style Chats List.
class ChatConversationItem {
  final String peerId;
  final String peerName;
  final String initials;
  final String lastMessage;
  final String timeAgo;
  final DeliveryStatus transportMode;
  final bool isSosEmergency;
  final int unreadCount;
  final Color avatarBgColor;

  ChatConversationItem({
    required this.peerId,
    required this.peerName,
    required this.initials,
    required this.lastMessage,
    required this.timeAgo,
    required this.transportMode,
    this.isSosEmergency = false,
    this.unreadCount = 0,
    required this.avatarBgColor,
  });
}

/// ChatsListScreen renders the WhatsApp/Messages-style conversation list.
///
/// UI Design Rules (consistent across all screens):
/// 1. AppBar uses same hub icon + MeshSOS RichText branding as DashboardScreen.
/// 2. SOS FAB uses circular FloatingActionButton with shield_outlined icon,
///    matching the same panic button used on ChatScreen.
/// 3. Tapping a tile opens ChatScreen with peer name AND avatar color passed in.
class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  final List<ChatConversationItem> _conversations = [
    ChatConversationItem(
      peerId: 'peer_rahul',
      peerName: 'Rahul K',
      initials: 'RK',
      lastMessage: 'Reached base camp, all good',
      timeAgo: '2m',
      transportMode: DeliveryStatus.sentMesh,
      avatarBgColor: const Color(0xFF0D3B66),
    ),
    ChatConversationItem(
      peerId: 'peer_priya_sos',
      peerName: 'SOS - Priya S',
      initials: '!',
      lastMessage: 'Need help - location attached',
      timeAgo: '5m',
      transportMode: DeliveryStatus.sentMesh,
      isSosEmergency: true,
      avatarBgColor: const Color(0xFFD32F2F),
    ),
    ChatConversationItem(
      peerId: 'peer_amit',
      peerName: 'Amit V',
      initials: 'AV',
      lastMessage: 'Synced once back online',
      timeAgo: '18m',
      transportMode: DeliveryStatus.sentCloud,
      unreadCount: 2,
      avatarBgColor: const Color(0xFF311B92),
    ),
    ChatConversationItem(
      peerId: 'peer_sneha',
      peerName: 'Sneha G',
      initials: 'SG',
      lastMessage: 'Sent via SMS fallback',
      timeAgo: '1h',
      transportMode: DeliveryStatus.sentSms,
      avatarBgColor: const Color(0xFF4E342E),
    ),
  ];

  void _openChatForUser(ChatConversationItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          peerName: item.peerName,
          avatarColor: item.avatarBgColor,
          initials: item.isSosEmergency ? null : item.initials,
          isSosContact: item.isSosEmergency,
        ),
      ),
    );
  }

  void _triggerSosBroadcast() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppColors.sosAccent,
        content: Text(
          '🚨 EMERGENCY SOS BROADCASTED TO ALL REACHABLE PEERS',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // ─── Brand AppBar identical to DashboardScreen ────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            // Hub icon pill — same as Dashboard
            Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: AppColors.sosAccent,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            // "Mesh" white + "SOS" red — same RichText as Dashboard
            RichText(
              text: const TextSpan(
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                children: [
                  TextSpan(text: 'Mesh', style: TextStyle(color: Colors.white)),
                  TextSpan(text: 'SOS', style: TextStyle(color: AppColors.sosAccent)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
            onPressed: () {},
          ),
        ],
      ),

      // ─── SOS Panic FAB — circle, shield_outlined, same across all screens ──
      floatingActionButton: FloatingActionButton(
        elevation: 8,
        backgroundColor: AppColors.sosAccent,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: _triggerSosBroadcast,
        child: const Icon(Icons.shield_outlined, size: 26),
      ),

      body: Column(
        children: [
          // Network Status Pill
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0E2214),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.transportMesh.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.network_cell_rounded,
                    color: AppColors.transportMesh, size: 18),
                SizedBox(width: 8),
                Text(
                  'Mesh: 3 peers nearby',
                  style: TextStyle(
                    color: AppColors.transportMesh,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Conversation List
          Expanded(
            child: ListView.separated(
              itemCount: _conversations.length,
              separatorBuilder: (_, __) =>
                  const Divider(color: AppColors.border, height: 1),
              itemBuilder: (context, index) {
                return _buildConversationTile(_conversations[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ChatConversationItem item) {
    final bool sos = item.isSosEmergency;
    final Color tileBg = sos ? const Color(0xFF2A0E0E) : AppColors.background;
    final Color nameColor = sos ? const Color(0xFFFF8A80) : AppColors.textPrimary;
    final Color subColor = sos ? const Color(0xFFFF8A80) : AppColors.textSecondary;

    // Transport icon prefix in subtitle
    IconData transportIcon;
    Color transportColor;
    switch (item.transportMode) {
      case DeliveryStatus.sentMesh:
        transportIcon = Icons.bluetooth_rounded;
        transportColor = AppColors.transportMesh;
        break;
      case DeliveryStatus.sentCloud:
        transportIcon = Icons.cloud_outlined;
        transportColor = AppColors.transportCloud;
        break;
      case DeliveryStatus.sentSms:
        transportIcon = Icons.chat_bubble_outline_rounded;
        transportColor = AppColors.transportSms;
        break;
      default:
        transportIcon = Icons.bluetooth_rounded;
        transportColor = AppColors.transportMesh;
    }

    return Material(
      color: tileBg,
      child: InkWell(
        onTap: () => _openChatForUser(item),
        splashColor: AppColors.sosAccent.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // ── Peer Avatar ──────────────────────────────────────────────
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: item.avatarBgColor,
                    child: sos
                        ? const Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 24)
                        : Text(
                            item.initials,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  // Online indicator dot
                  if (!sos)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: item.transportMode == DeliveryStatus.sentMesh
                              ? AppColors.transportMesh
                              : item.transportMode == DeliveryStatus.sentCloud
                                  ? AppColors.transportCloud
                                  : AppColors.transportSms,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: AppColors.background, width: 2),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 14),

              // ── Name + Last Message ───────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.peerName,
                          style: TextStyle(
                            color: nameColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          item.timeAgo,
                          style: TextStyle(
                            color: sos
                                ? const Color(0xFFFF8A80)
                                : AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          sos ? Icons.location_on_outlined : transportIcon,
                          color: sos ? const Color(0xFFFF8A80) : transportColor,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            item.lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: subColor, fontSize: 14),
                          ),
                        ),
                        // Unread badge
                        if (item.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: AppColors.transportCloud,
                            child: Text(
                              '${item.unreadCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
