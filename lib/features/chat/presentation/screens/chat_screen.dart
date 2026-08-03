import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../mesh/domain/models/message_envelope.dart';
import '../../../mesh/domain/providers/mesh_router_provider.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/message_bubble.dart';
import '../widgets/network_status_strip.dart';

/// ChatScreen — WhatsApp / Google Messages styled chat conversation screen.
///
/// Avatar in AppBar uses [avatarColor] + [initials] matching the ChatsListScreen
/// tile so the design is fully consistent across both screens.
class ChatScreen extends ConsumerStatefulWidget {
  final String peerName;
  final Color avatarColor;
  final String? initials;
  final bool isSosContact;

  const ChatScreen({
    super.key,
    this.peerName = 'John',
    this.avatarColor = const Color(0xFF0D3B66),
    this.initials,
    this.isSosContact = false,
  });

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final List<MessageEnvelope> _messages = [];
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<MessageEnvelope>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadHistory();
      _subscribeToRouterStream();
    });
  }

  void _loadHistory() {
    try {
      final repository = ref.read(localStorageRepositoryProvider);
      final history = repository.getAllMessages();
      if (history.isEmpty) {
        _seedDemoMockupMessages();
      } else {
        setState(() {
          _messages.clear();
          _messages.addAll(history);
        });
      }
    } catch (_) {
      _seedDemoMockupMessages();
    }
  }

  void _seedDemoMockupMessages() {
    final myId = ref.read(currentDeviceIdProvider);
    final demoMessages = [
      MessageEnvelope(
        senderId: 'peer_contact',
        recipientId: myId,
        payload: 'Hi, this is so cool for an advanced offline emergency chat app.',
        deliveryStatus: DeliveryStatus.sentMesh,
        hopCount: 3,
        timestamp: DateTime.now()
            .subtract(const Duration(minutes: 10))
            .millisecondsSinceEpoch,
      ),
      MessageEnvelope(
        senderId: myId,
        payload: 'Hello, now I am testing how messages relay across devices.',
        deliveryStatus: DeliveryStatus.sentMesh,
        hopCount: 3,
        timestamp: DateTime.now()
            .subtract(const Duration(minutes: 8))
            .millisecondsSinceEpoch,
      ),
      MessageEnvelope(
        senderId: 'peer_contact',
        recipientId: myId,
        payload: 'Are you confirmed with purely mesh network route?',
        deliveryStatus: DeliveryStatus.sentCloud,
        timestamp: DateTime.now()
            .subtract(const Duration(minutes: 5))
            .millisecondsSinceEpoch,
      ),
      MessageEnvelope(
        senderId: myId,
        payload: 'What is your next test step?',
        deliveryStatus: DeliveryStatus.sentMesh,
        hopCount: 1,
        timestamp: DateTime.now()
            .subtract(const Duration(minutes: 3))
            .millisecondsSinceEpoch,
      ),
      MessageEnvelope(
        senderId: 'peer_contact',
        recipientId: myId,
        payload: 'Messages that automatically use SMS as a backup.',
        deliveryStatus: DeliveryStatus.sentSms,
        timestamp: DateTime.now()
            .subtract(const Duration(minutes: 1))
            .millisecondsSinceEpoch,
      ),
    ];

    setState(() {
      _messages.clear();
      _messages.addAll(demoMessages);
    });
  }

  void _subscribeToRouterStream() {
    final router = ref.read(meshRouterProvider);
    _subscription = router.incomingMessageStream.listen((envelope) {
      setState(() {
        _messages.add(envelope);
      });
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _handleSendMessage(String text) {
    final myId = ref.read(currentDeviceIdProvider);
    final router = ref.read(meshRouterProvider);

    final envelope = MessageEnvelope(
      senderId: myId,
      payload: text,
      deliveryStatus: DeliveryStatus.sentMesh,
      ttl: 8,
    );

    router.sendNewMessage(envelope);
    _scrollToBottom();
  }

  void _handleSosBroadcast() {
    final myId = ref.read(currentDeviceIdProvider);
    final router = ref.read(meshRouterProvider);

    final sosEnvelope = MessageEnvelope(
      senderId: myId,
      payload: 'EMERGENCY SOS: Help needed! GPS attached.',
      type: MessageType.sos,
      deliveryStatus: DeliveryStatus.sentMesh,
      ttl: 8,
    );

    router.sendNewMessage(sosEnvelope);
    _scrollToBottom();

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

  /// Derive display initials from peerName if none passed explicitly.
  String _resolveInitials() {
    if (widget.initials != null && widget.initials!.isNotEmpty) {
      return widget.initials!;
    }
    final parts = widget.peerName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return widget.peerName.substring(0, 2).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(currentDeviceIdProvider);
    final initials = _resolveInitials();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,

        // Back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),

        title: Row(
          children: [
            // ── Avatar matching ChatsListScreen tile ──────────────────────
            Stack(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: widget.avatarColor,
                  child: widget.isSosContact
                      ? const Icon(Icons.warning_amber_rounded,
                          color: Colors.white, size: 20)
                      : Text(
                          initials,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                // Online dot
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: widget.isSosContact
                          ? AppColors.sosAccent
                          : AppColors.transportMesh,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.background, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),

            // ── Name + Mesh subtitle ──────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.peerName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isSosContact
                          ? const Color(0xFFFF8A80)
                          : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.isSosContact
                        ? '🚨 SOS Emergency Contact'
                        : 'Mesh Radio Reachable (3 Hops)',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.isSosContact
                          ? AppColors.sosAccent
                          : AppColors.transportMesh,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            icon: const Icon(Icons.call_outlined, color: Colors.white, size: 22),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),

      body: Column(
        children: [
          // Connectivity Status Strip
          const NetworkStatusStrip(
            currentMode: DeliveryStatus.sentMesh,
            activePeerCount: 3,
          ),

          // Message History
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: 12, bottom: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final envelope = _messages[index];
                final isMe = envelope.senderId == myId;
                return MessageBubble(envelope: envelope, isMe: isMe);
              },
            ),
          ),

          // Chat Input Composer — SOS shield lives inside the input row (left side)
          ChatInputField(
            onSendMessage: _handleSendMessage,
            onSosTap: _handleSosBroadcast,
          ),
        ],
      ),
    );
  }
}
