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

  /// Callback provided by the transport layer (NearbyService) to forward
  /// a packet to all connected peers except [excludePeerId].
  /// WHY: MeshRouter stays transport-agnostic — it decides WHO to forward to
  /// based on TTL/routing logic, but DELEGATES the actual radio send to
  /// NearbyService via this callback.
  final Future<void> Function(MessageEnvelope envelope, String? excludePeerId)?
      onForwardEnvelope;

  MeshRouter({
    required this.repository,
    required this.currentDeviceId,
    this.onForwardEnvelope,
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
    // Decrement TTL. If TTL > 0, copyForForwarding() returns new packet.
    // If TTL <= 1, returns null (hop budget exhausted — prevents loops).
    final MessageEnvelope? outgoingEnvelope = envelope.copyForForwarding();

    if (outgoingEnvelope != null && onForwardEnvelope != null) {
      // Delegate broadcast to NearbyService, excluding the original sender
      await onForwardEnvelope!(outgoingEnvelope, fromPeerId);
    }
  }

  /// Send a brand new message originated from this device
  Future<void> sendNewMessage(MessageEnvelope envelope) async {
    // 1. Save to local DB & mark seen
    await repository.saveEnvelope(envelope);

    // 2. Emit to local UI immediately
    _incomingMessageController.add(envelope);

    // 3. Broadcast to all connected peers via NearbyService
    if (onForwardEnvelope != null) {
      await onForwardEnvelope!(envelope, null); // null = broadcast to everyone
    }
  }

  /// Closes stream controllers on app disposal
  void dispose() {
    _incomingMessageController.close();
  }
}
