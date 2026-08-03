import 'dart:async';
import '../../../../core/database/local_storage_repository.dart';
import '../models/message_envelope.dart';

/// MeshRouter is the central algorithmic engine of MeshSOS.
/// 
/// 💡 System Design & Interview Deep-Dive: Controlled Flooding Algorithm
/// -------------------------------------------------------------------------
/// In an ad-hoc peer-to-peer mesh network (where phones connect directly over BLE/WiFi),
/// there is no central server or fixed router table to decide the "best route".
/// 
/// We use CONTROLLED FLOODING:
/// 1. Node receives an incoming envelope from a peer.
/// 2. Deduplication check: O(1) hash lookup in `seen_ids`. If already seen, drop silently.
/// 3. Persistence: Store envelope locally in Hive DB so user doesn't lose message history.
/// 4. UI Delivery: If envelope is addressed to THIS device OR is a public SOS broadcast,
///    emit to `incomingMessageStream` so UI renders the message bubble.
/// 5. Forwarding: Decrement TTL hop budget by 1 (`copyForForwarding()`).
///    If TTL > 0, forward the packet to all connected peers EXCEPT the sender (`fromPeerId`).
///    If TTL reaches 0, stop forwarding (prevents infinite network loops).
class MeshRouter {
  final LocalStorageRepository repository;
  final String currentDeviceId;

  /// Stream controller emitting incoming messages to UI screens
  final _incomingMessageController = StreamController<MessageEnvelope>.broadcast();

  /// Callback function provided by transport layer to send raw JSON bytes to a peer device
  Future<void> Function(String targetPeerId, MessageEnvelope envelope)? onSendToPeer;

  /// List of currently connected radio peer device IDs
  List<String> connectedPeerIds = [];

  MeshRouter({
    required this.repository,
    required this.currentDeviceId,
    this.onSendToPeer,
  });

  /// Exposes incoming messages stream for UI state listeners
  Stream<MessageEnvelope> get incomingMessageStream => _incomingMessageController.stream;

  /// Primary Entry Point: Called whenever a radio packet arrives from a peer
  Future<void> onReceiveEnvelope({
    required MessageEnvelope envelope,
    required String fromPeerId,
  }) async {
    // -----------------------------------------------------------------------
    // STEP 1: IDEMPOTENCY CHECK (O(1) Hash Lookup)
    // -----------------------------------------------------------------------
    // If packet UUID has already been processed by this phone, drop it silently!
    if (repository.isSeen(envelope.id)) {
      return;
    }

    // -----------------------------------------------------------------------
    // STEP 2: PERSISTENCE
    // -----------------------------------------------------------------------
    // Store message envelope in local Hive DB & mark UUID as seen in cache
    await repository.saveEnvelope(envelope);

    // -----------------------------------------------------------------------
    // STEP 3: UI DELIVERY CHECK
    // -----------------------------------------------------------------------
    // Render in UI if addressed to this phone, OR if it is an emergency SOS broadcast
    final bool isAddressedToMe = envelope.recipientId == currentDeviceId;
    final bool isSosBroadcast = envelope.type == MessageType.sos;

    if (isAddressedToMe || isSosBroadcast) {
      _incomingMessageController.add(envelope);
    }

    // -----------------------------------------------------------------------
    // STEP 4: MULTI-HOP FORWARDING LOGIC (Controlled Flooding)
    // -----------------------------------------------------------------------
    // Decrement TTL (Time-To-Live). If TTL > 0, copyForForwarding() returns new packet.
    // If TTL <= 1, copyForForwarding() returns null (hop budget exhausted).
    final MessageEnvelope? outgoingEnvelope = envelope.copyForForwarding();

    if (outgoingEnvelope != null) {
      for (final peerId in connectedPeerIds) {
        // CRITICAL RULE: Never forward packet back to the peer who just sent it to us!
        if (peerId != fromPeerId) {
          if (onSendToPeer != null) {
            await onSendToPeer!(peerId, outgoingEnvelope);
          }
        }
      }
    }
  }

  /// Send a brand new message originated from this device
  Future<void> sendNewMessage(MessageEnvelope envelope) async {
    // 1. Save to local DB & mark seen
    await repository.saveEnvelope(envelope);

    // 2. Emit to local UI
    _incomingMessageController.add(envelope);

    // 3. Broadcast to all directly connected mesh peers
    if (onSendToPeer != null) {
      for (final peerId in connectedPeerIds) {
        await onSendToPeer!(peerId, envelope);
      }
    }
  }

  /// Closes stream controllers on app disposal
  void dispose() {
    _incomingMessageController.close();
  }
}
