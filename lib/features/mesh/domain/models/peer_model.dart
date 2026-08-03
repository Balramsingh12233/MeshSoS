/// Peer model represents a discovered node (phone/device) in the MeshSOS network.
/// 
/// System Design Rationale:
/// - In peer-to-peer mesh networks, devices don't connect through a central server.
/// - Instead, every device maintains a list of known "Peers" in range or reachable via relay hops.
/// - Peers can be direct radio neighbors (hopDistance = 1) or multi-hop relays (hopDistance > 1).
class Peer {
  /// Unique device identifier
  final String id;

  /// Human readable display name (e.g. "Alice's Phone")
  final String displayName;

  /// Public key used for X25519 end-to-end payload encryption
  final String? publicKey;

  /// Timestamp of when this device was last seen or connected over radio
  final DateTime lastConnectedAt;

  /// Trust level (0 = unknown stranger relay node, 1 = verified contact)
  final int trustLevel;

  /// Radio hop distance: 1 = direct BLE/WiFi neighbor, >1 = relayed peer
  final int hopDistance;

  /// Whether the peer is currently reachable over mesh radio or cloud
  final bool isOnline;

  Peer({
    required this.id,
    required this.displayName,
    this.publicKey,
    DateTime? lastConnectedAt,
    this.trustLevel = 0,
    this.hopDistance = 1,
    this.isOnline = true,
  }) : lastConnectedAt = lastConnectedAt ?? DateTime.now();

  /// Create a copy of Peer with updated connectivity or hop properties
  Peer copyWith({
    String? displayName,
    String? publicKey,
    DateTime? lastConnectedAt,
    int? trustLevel,
    int? hopDistance,
    bool? isOnline,
  }) {
    return Peer(
      id: id,
      displayName: displayName ?? this.displayName,
      publicKey: publicKey ?? this.publicKey,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      trustLevel: trustLevel ?? this.trustLevel,
      hopDistance: hopDistance ?? this.hopDistance,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  /// Converts Peer object to Map for local database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'publicKey': publicKey,
      'lastConnectedAt': lastConnectedAt.toIso8601String(),
      'trustLevel': trustLevel,
      'hopDistance': hopDistance,
      'isOnline': isOnline,
    };
  }

  /// Reconstructs Peer object from local storage record
  factory Peer.fromJson(Map<String, dynamic> json) {
    return Peer(
      id: json['id'] as String,
      displayName: json['displayName'] as String,
      publicKey: json['publicKey'] as String?,
      lastConnectedAt: DateTime.parse(json['lastConnectedAt'] as String),
      trustLevel: json['trustLevel'] as int? ?? 0,
      hopDistance: json['hopDistance'] as int? ?? 1,
      isOnline: json['isOnline'] as bool? ?? true,
    );
  }
}
