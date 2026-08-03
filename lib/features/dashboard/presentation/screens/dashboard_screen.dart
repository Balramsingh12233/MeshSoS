import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../chat/presentation/screens/chats_list_screen.dart';
import '../../../mesh/domain/models/message_envelope.dart';
import '../../../mesh/domain/providers/mesh_router_provider.dart';
import '../widgets/mesh_status_banner.dart';
import '../widgets/nearby_peer_item.dart';
import '../widgets/radar_visualizer_card.dart';
import '../widgets/recent_chat_item.dart';
import '../widgets/sos_panic_card.dart';

/// Representation of recent demo conversation item
class ConversationSummary {
  final String peerName;
  final String lastMessage;
  final DeliveryStatus deliveryStatus;
  final Color avatarColor;
  final String initials;

  const ConversationSummary({
    required this.peerName,
    required this.lastMessage,
    required this.deliveryStatus,
    required this.avatarColor,
    required this.initials,
  });
}

const List<ConversationSummary> recentConversations = [
  ConversationSummary(
    peerName: 'John',
    lastMessage: "Hello, that's your message?",
    deliveryStatus: DeliveryStatus.sentMesh,
    avatarColor: Color(0xFF0D3B66),
    initials: 'JN',
  ),
  ConversationSummary(
    peerName: 'Mesh Hinsez',
    lastMessage: 'Hello, mreth.',
    deliveryStatus: DeliveryStatus.sentCloud,
    avatarColor: Color(0xFF311B92),
    initials: 'MH',
  ),
  ConversationSummary(
    peerName: 'Dirok Huvinro',
    lastMessage: 'Messages that automatically use SMS as backup.',
    deliveryStatus: DeliveryStatus.sentSms,
    avatarColor: Color(0xFF4E342E),
    initials: 'DH',
  ),
];

/// DashboardScreen is the primary Home Screen of MeshSOS.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedBottomNavIndex = 0;

  void _navigateToChatScreen(
    String peerName, {
    Color avatarColor = const Color(0xFF0D3B66),
    String? initials,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          peerName: peerName,
          avatarColor: avatarColor,
          initials: initials,
        ),
      ),
    );
  }

  void _handleSosBroadcast() {
    final myId = ref.read(currentDeviceIdProvider);
    final router = ref.read(meshRouterProvider);

    final sosEnvelope = MessageEnvelope(
      senderId: myId,
      payload: 'EMERGENCY SOS: Help needed! GPS location attached.',
      type: MessageType.sos,
      deliveryStatus: DeliveryStatus.sentMesh,
      ttl: 8,
    );

    router.sendNewMessage(sosEnvelope);

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
    // Trigger mesh bootstrap (permissions + advertising/discovery) once.
    // meshBootstrapProvider is a FutureProvider that starts mesh on first read.
    ref.watch(meshBootstrapProvider);

    // If user selected 'Chats' tab (index 2), render ChatsListScreen!
    if (_selectedBottomNavIndex == 2) {
      return Scaffold(
        body: const ChatsListScreen(),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    // Watch real-time discovered nearby peers
    final nearbyPeersAsync = ref.watch(nearbyPeersProvider);
    final nearbyPeers = nearbyPeersAsync.value ?? [];
    final hasNearbyPeers = nearbyPeers.isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Row(
          children: [
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
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.transportMesh.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.transportMesh, width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: AppColors.transportMesh.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: hasNearbyPeers ? AppColors.transportMesh : Colors.amber,
                ),
                const SizedBox(width: 6),
                Text(
                  hasNearbyPeers ? 'Mesh (${nearbyPeers.length})' : 'Mesh Online',
                  style: const TextStyle(
                    color: AppColors.transportMesh,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── FIXED SECTION: Radar + Status Banner + SOS Panic card ──────────
          // Real peer count controls glowing dots on radar (0 when no peers found)
          RadarVisualizerCard(activePeerCount: nearbyPeers.length),
          // Shows actionable error card when permissions/GPS/mesh fails
          const MeshStatusBanner(),
          SosPanicCard(onTriggerSos: _handleSosBroadcast),

          const SizedBox(height: 12),

          // Dynamic Header: 'Discovered Devices' when nearby peers found, else 'Recent Conversations'
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasNearbyPeers ? 'Discovered Devices (${nearbyPeers.length})' : 'Recent Conversations',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasNearbyPeers)
                  const Text(
                    'Active Now',
                    style: TextStyle(
                      color: AppColors.transportMesh,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),

          // ── SCROLLABLE SECTION: shows nearby devices or recent chats ────────
          Expanded(
            child: hasNearbyPeers
                ? ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    itemCount: nearbyPeers.length,
                    itemBuilder: (context, index) {
                      final peer = nearbyPeers[index];
                      return NearbyPeerItem(
                        peer: peer,
                        onTap: () => _navigateToChatScreen(
                          peer.displayName,
                          avatarColor: const Color(0xFF0D3B66),
                          initials: peer.displayName.isNotEmpty
                              ? peer.displayName.substring(0, 1).toUpperCase()
                              : '?',
                        ),
                      );
                    },
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 16),
                    children: recentConversations
                        .map(
                          (c) => RecentChatItem(
                            peerName: c.peerName,
                            lastMessageText: c.lastMessage,
                            mode: c.deliveryStatus,
                            onTap: () => _navigateToChatScreen(
                              c.peerName,
                              avatarColor: c.avatarColor,
                              initials: c.initials,
                            ),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      currentIndex: _selectedBottomNavIndex,
      onTap: (index) {
        setState(() {
          _selectedBottomNavIndex = index;
        });
      },
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.textPrimary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.radar_rounded),
          label: 'Radar',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline_rounded),
          label: 'Chats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    );
  }
}
