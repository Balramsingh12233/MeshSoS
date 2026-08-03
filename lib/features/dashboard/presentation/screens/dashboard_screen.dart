import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../chat/presentation/screens/chat_screen.dart';
import '../../../chat/presentation/screens/chats_list_screen.dart';
import '../../../mesh/domain/models/message_envelope.dart';
import '../../../mesh/domain/providers/mesh_router_provider.dart';
import '../widgets/radar_visualizer_card.dart';
import '../widgets/recent_chat_item.dart';
import '../widgets/sos_panic_card.dart';

/// DashboardScreen is the primary Home Screen of MeshSOS.
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedBottomNavIndex = 0;

  void _navigateToChatScreen(String peerName) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatScreen(peerName: peerName)),
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
    // If user selected 'Chats' tab (index 2), render ChatsListScreen!
    if (_selectedBottomNavIndex == 2) {
      return Scaffold(
        body: const ChatsListScreen(),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

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
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 4,
                  backgroundColor: AppColors.transportMesh,
                ),
                SizedBox(width: 6),
                Text(
                  'Mesh Online',
                  style: TextStyle(
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Radar Visualizer Card
            const RadarVisualizerCard(activePeerCount: 4),

            // 2. SOS Panic Card
            SosPanicCard(onTriggerSos: _handleSosBroadcast),

            const SizedBox(height: 12),

            // Recent Conversations Header
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Text(
                'Recent Conversations',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            // 3. Recent Chat Threads
            RecentChatItem(
              peerName: 'John',
              lastMessageText: "Hello, that's your message?",
              mode: DeliveryStatus.sentMesh,
              onTap: () => _navigateToChatScreen('John'),
            ),
            RecentChatItem(
              peerName: 'Mesh Hinsez',
              lastMessageText: 'Hello, mreth.',
              mode: DeliveryStatus.sentCloud,
              onTap: () => _navigateToChatScreen('Mesh Hinsez'),
            ),
            RecentChatItem(
              peerName: 'Dirok Huvinro',
              lastMessageText: 'Messages that automatically use SMS as backup.',
              mode: DeliveryStatus.sentSms,
              onTap: () => _navigateToChatScreen('Dirok Huvinro'),
            ),

            const SizedBox(height: 20),
          ],
        ),
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
