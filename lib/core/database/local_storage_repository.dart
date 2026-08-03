import '../../features/mesh/domain/models/message_envelope.dart';
import '../../features/mesh/domain/models/peer_model.dart';
import 'hive_service.dart';

/// LocalStorageRepository provides a clean API for reading & writing offline data.
/// 
/// Design Pattern Rationale (Repository Pattern):
/// - Decouples the underlying database implementation (Hive) from the app's domain logic.
/// - If we ever change storage engines in the future, domain logic won't need to change.
class LocalStorageRepository {
  final HiveService _hiveService;

  LocalStorageRepository(this._hiveService);

  // ===========================================================================
  // 1. MESSAGE ENVELOPE STORAGE & DEDUPLICATION (IDEMPOTENCY)
  // ===========================================================================

  /// Saves a message packet to offline storage and marks its UUID as seen.
  Future<void> saveEnvelope(MessageEnvelope envelope) async {
    // 1. Store message envelope JSON in messages box
    await _hiveService.messagesBox.put(envelope.id, envelope.toJson());

    // 2. Mark packet UUID in seen_ids cache for fast O(1) deduplication
    await markSeen(envelope.id);
  }

  /// Checks if a message UUID has already been processed by this device.
  /// 
  /// Returns `true` if seen (drop duplicate packet), `false` if brand new.
  bool isSeen(String messageId) {
    return _hiveService.seenIdsBox.containsKey(messageId);
  }

  /// Marks a message UUID as processed in the seen_ids cache.
  Future<void> markSeen(String messageId) async {
    await _hiveService.seenIdsBox.put(messageId, true);
  }

  /// Retrieves all offline chat messages, sorted chronologically by timestamp.
  List<MessageEnvelope> getAllMessages() {
    final rawList = _hiveService.messagesBox.values;
    final envelopes = rawList
        .map((map) => MessageEnvelope.fromJson(Map<String, dynamic>.from(map)))
        .toList();

    // Sort by creation timestamp (oldest first)
    envelopes.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return envelopes;
  }

  // ===========================================================================
  // 2. DISCOVERED PEER NODE STORAGE
  // ===========================================================================

  /// Saves or updates a discovered mesh peer in local storage.
  Future<void> savePeer(Peer peer) async {
    await _hiveService.peersBox.put(peer.id, peer.toJson());
  }

  /// Retrieves all cached mesh peer nodes.
  List<Peer> getAllPeers() {
    final rawList = _hiveService.peersBox.values;
    return rawList
        .map((map) => Peer.fromJson(Map<String, dynamic>.from(map)))
        .toList();
  }
}
