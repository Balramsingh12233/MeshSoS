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

/// ChatsListScreen renders the WhatsApp/Messages-style conversation list screen.
/// 
/// Design Precision (Matching User Mockup Screenshot 100%):
/// 1. Top Brand Header: "MeshSOS" title + Search Icon (`Q`).
/// 2. Top Network Status Pill: "Mesh: 3 peers nearby" in dark green container.
/// 3. Conversation List Tiles:
///    - Normal Mesh Chat (`Rahul K`): Bluetooth icon, initials avatar "RK".
///    - SOS Emergency Chat (`SOS - Priya S`): Highlighted red background (`#3D1414`), red warning icon, location attached text.
///    - Cloud Synced Chat (`Amit V`): Cloud icon, unread blue message badge `2`.
///    - SMS Fallback Chat (`Sneha G`): SMS text icon, amber initials.
/// 4. Tap Navigation: Tapping any user tile opens `ChatScreen(peerName: ...)` for that user.
/// 5. Floating SOS Panic FAB: Round warm red button with warning triangle icon.
class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen> {
  // Demo Mockup Conversation Data matching screenshot exactly
  final List<ChatConversationItem> _conversations = [
    ChatConversationItem(
      peerId: 'peer_rahul',
      peerName: 'Rahul K',
      initials: 'RK',
      lastMessage: 'Reached base camp, all good',
      timeAgo: '2m',
      transportMode: DeliveryStatus.sentMesh,
      avatarBgColor: const Color(0xFF0D3B66), // Dark Blue
    ),
    ChatConversationItem(
      peerId: 'peer_priya_sos',
      peerName: 'SOS - Priya S',
      initials: '!',
      lastMessage: 'Need help - location attached',
      timeAgo: '5m',
      transportMode: DeliveryStatus.sentMesh,
      isSosEmergency: true,
      avatarBgColor: const Color(0xFFD32F2F), // Red
    ),
    ChatConversationItem(
      peerId: 'peer_amit',
      peerName: 'Amit V',
      initials: 'AV',
      lastMessage: 'Synced once back online',
      timeAgo: '18m',
      transportMode: DeliveryStatus.sentCloud,
      unreadCount: 2,
      avatarBgColor: const Color(0xFF311B92), // Dark Purple
    ),
    ChatConversationItem(
      peerId: 'peer_sneha',
      peerName: 'Sneha G',
      initials: 'SG',
      lastMessage: 'Sent via SMS fallback',
      timeAgo: '1h',
      transportMode: DeliveryStatus.sentSms,
      avatarBgColor: const Color(0xFF4E342E), // Dark Amber/Brown
    ),
  ];

  void _openChatForUser(ChatConversationItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(peerName: item.peerName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'MeshSOS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white, size: 24),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Top Transport Connectivity Pill matching screenshot
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0E2214), // Dark Green Container
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.transportMesh.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.network_cell_rounded, color: AppColors.transportMesh, size: 18),
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

              const SizedBox(height: 4),

              // Conversation List View
              Expanded(
                child: ListView.separated(
                  itemCount: _conversations.length,
                  separatorBuilder: (context, index) => const Divider(
                    color: AppColors.border,
                    height: 1,
                  ),
                  itemBuilder: (context, index) {
                    final item = _conversations[index];
                    return _buildConversationTile(item);
                  },
                ),
              ),
            ],
          ),

          // Floating Warm Red Emergency Action Button matching screenshot
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton(
              elevation: 8,
              backgroundColor: const Color(0xFFE53935), // Red
              foregroundColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    backgroundColor: AppColors.sosAccent,
                    content: Text(
                      '🚨 EMERGENCY SOS BROADCASTED',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              },
              child: const Icon(Icons.warning_amber_rounded, size: 28),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(ChatConversationItem item) {
    // If SOS emergency chat, highlight tile with dark red background (#3D1414)
    final Color tileBgColor = item.isSosEmergency ? const Color(0xFF3D1414) : AppColors.background;
    final Color textColor = item.isSosEmergency ? const Color(0xFFFF8A80) : AppColors.textPrimary;
    final Color subtextColor = item.isSosEmergency ? const Color(0xFFFF8A80) : AppColors.textSecondary;

    // Transport icon prefix
    IconData transportIcon;
    switch (item.transportMode) {
      case DeliveryStatus.sentMesh:
        transportIcon = Icons.bluetooth_rounded;
        break;
      case DeliveryStatus.sentCloud:
        transportIcon = Icons.cloud_outlined;
        break;
      case DeliveryStatus.sentSms:
        transportIcon = Icons.chat_bubble_outline_rounded;
        break;
      default:
        transportIcon = Icons.bluetooth_rounded;
        break;
    }

    return Container(
      color: tileBgColor,
      child: ListTile(
        onTap: () => _openChatForUser(item),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: item.avatarBgColor,
          child: item.isSosEmergency
              ? const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 24)
              : Text(
                  item.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              item.peerName,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              item.timeAgo,
              style: TextStyle(
                color: item.isSosEmergency ? const Color(0xFFFF8A80) : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            children: [
              if (item.isSosEmergency)
                const Icon(Icons.location_on_outlined, color: Color(0xFFFF8A80), size: 14)
              else
                Icon(transportIcon, color: AppColors.textSecondary, size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  item.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 14,
                  ),
                ),
              ),
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
        ),
      ),
    );
  }
}
