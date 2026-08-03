import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../mesh/domain/models/message_envelope.dart';
import '../../../mesh/domain/providers/mesh_router_provider.dart';
import '../widgets/chat_input_field.dart';
import '../widgets/message_bubble.dart';
import '../widgets/network_status_strip.dart';

/// ChatScreen is the main Google Product Design chat interface for MeshSOS.
/// 
/// System Design & UI Features:
/// 1. Real-Time Message Stream: Listens to `MeshRouter.incomingMessageStream` 
///    and updates the UI instantly as packets hop through the mesh.
/// 2. Google Product Design Aesthetics: OLED dark theme, top network status strip, 
///    glassmorphic delivery path badges (Mesh, Cloud, SMS).
/// 3. Floating SOS Emergency FAB: High-visibility warm red button (`#FF4D4D`) 
///    to trigger instant one-tap panic broadcasts.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

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

  /// Loads offline chat history from Hive DB on startup
  void _loadHistory() {
    try {
      final repository = ref.read(localStorageRepositoryProvider);
      final history = repository.getAllMessages();
      
      // If database is empty, seed demo messages matching the UI design mockup
      if (history.isEmpty) {
        _seedDemoMockupMessages();
      } else {
        setState(() {
          _messages.clear();
          _messages.addAll(history);
        });
      }
    } catch (_) {
      // Fallback to demo mockup messages if database box is not yet initialized
      _seedDemoMockupMessages();
    }
  }

  /// Seeds initial mockup messages matching the Google Product Design screenshot
  void _seedDemoMockupMessages() {
    final myId = ref.read(currentDeviceIdProvider);
    final demoMessages = [
      MessageEnvelope(
        senderId: 'peer_alex',
        recipientId: myId,
        payload: 'Hi, this is so cool for an advanced offline emergency chat app.',
        deliveryStatus: DeliveryStatus.sentMesh,
        hopCount: 3,
        timestamp: DateTime.now().subtract(const Duration(minutes: 10)).millisecondsSinceEpoch,
      ),
      MessageEnvelope(
        senderId: myId,
        payload: 'Hello, now I am testing how messages relay across devices.',
        deliveryStatus: DeliveryStatus.sentMesh,
        hopCount: 3,
        timestamp: DateTime.now().subtract(const Duration(minutes: 8)).millisecondsSinceEpoch,
      ),
      MessageEnvelope(
        senderId: 'peer_alex',
        recipientId: myId,
        payload: 'Are you confirmed with purely mesh network route?',
        deliveryStatus: DeliveryStatus.sentCloud,
        timestamp: DateTime.now().subtract(const Duration(minutes: 5)).millisecondsSinceEpoch,
      ),
      MessageEnvelope(
        senderId: myId,
        payload: 'What is your next test step?',
        deliveryStatus: DeliveryStatus.sentMesh,
        hopCount: 1,
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)).millisecondsSinceEpoch,
      ),
      MessageEnvelope(
        senderId: 'peer_bob',
        recipientId: myId,
        payload: 'Messages that automatically use SMS as a backup.',
        deliveryStatus: DeliveryStatus.sentSms,
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)).millisecondsSinceEpoch,
      ),
    ];

    setState(() {
      _messages.addAll(demoMessages);
    });
  }

  /// Subscribes to MeshRouter live incoming message stream
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

  /// Sends a new text chat message over the mesh router
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

  /// Triggers emergency SOS broadcast
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

  @override
  Widget build(BuildContext context) {
    final myId = ref.watch(currentDeviceIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MeshSOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // Persistent Top Connectivity Status Strip
          const NetworkStatusStrip(
            currentMode: DeliveryStatus.sentMesh,
            activePeerCount: 3,
          ),

          // Main Chat Message History List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final envelope = _messages[index];
                final isMe = envelope.senderId == myId;
                return MessageBubble(envelope: envelope, isMe: isMe);
              },
            ),
          ),

          // Bottom Text Input Composer
          ChatInputField(onSendMessage: _handleSendMessage),
        ],
      ),

      // Floating Emergency SOS Panic Action Button (Warm Red #FF4D4D)
      floatingActionButton: FloatingActionButton(
        elevation: 6,
        backgroundColor: AppColors.sosAccent,
        foregroundColor: Colors.white,
        onPressed: _handleSosBroadcast,
        child: const Icon(Icons.shield_outlined, size: 26),
      ),
    );
  }
}
