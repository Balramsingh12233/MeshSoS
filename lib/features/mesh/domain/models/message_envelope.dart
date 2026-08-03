import 'package:uuid/uuid.dart';

/// Enum representing the type of packet traveling through the mesh network.
enum MessageType {
  /// Standard 1-on-1 text chat message
  chat,
  
  /// High-priority emergency SOS broadcast with GPS coordinates
  sos,
  
  /// Delivery Acknowledgment envelope sent back when recipient receives a message
  ack,
  
  /// GPS location update packet
  location,
}

/// Enum representing how the message was delivered.
enum DeliveryStatus {
  /// Stored locally, waiting to be sent
  pending,
  
  /// Transmitted via peer-to-peer Bluetooth/WiFi Direct mesh relay
  sentMesh,
  
  /// Uploaded/synced via Cloudflare Workers backend
  sentCloud,
  
  /// Sent via native device SIM card (cellular SMS fallback)
  sentSms,
  
  /// Confirmed delivered to final recipient (via ACK)
  delivered,
}

/// MessageEnvelope is the fundamental network packet data structure in MeshSOS.
/// 
/// 💡 System Design Concepts for Big Tech Interviews:
/// 1. IDEMPOTENCY: Every message gets a unique UUID generated at creation time.
///    If a device receives the same packet multiple times from different relay paths, 
///    it checks its local `seenIds` cache and drops duplicate packets safely.
/// 2. CONTROLLED FLOODING & TTL: The `ttl` (Time-To-Live) field starts at 8. 
///    Every time a peer node forwards the packet to another peer, `ttl` is decremented by 1.
///    When `ttl` reaches 0, forwarding stops. This prevents infinite packet loops in the mesh.
/// 3. IMMUTABILITY: Messages are append-only. No vector clocks or complex CRDTs 
///    are required because payload data is immutable once sent.
class MessageEnvelope {
  /// Globally unique identifier (UUIDv4) for duplicate suppression (Idempotency)
  final String id;

  /// Unique ID of the device that created and sent the original message
  final String senderId;

  /// Unique ID of the intended recipient device (null if broadcast SOS to everyone)
  final String? recipientId;

  /// Message payload (encrypted text body or JSON string)
  final String payload;

  /// Hop budget counter. Starts at 8, decrements by 1 on each hop. Stoppage at 0.
  final int ttl;

  /// Creation timestamp in milliseconds since epoch
  final int timestamp;

  /// Type of packet (chat, sos, ack, location)
  final MessageType type;

  /// Current delivery transport status
  final DeliveryStatus deliveryStatus;

  /// Number of hops this message has traveled so far (starts at 0)
  final int hopCount;

  MessageEnvelope({
    String? id,
    required this.senderId,
    this.recipientId,
    required this.payload,
    this.ttl = 8,
    int? timestamp,
    this.type = MessageType.chat,
    this.deliveryStatus = DeliveryStatus.pending,
    this.hopCount = 0,
  })  : id = id ?? const Uuid().v4(),
        timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  /// Helper method to create a new envelope with decremented TTL when forwarding.
  /// 
  /// Returns null if TTL has expired (ttl <= 1), signaling the router to drop packet.
  MessageEnvelope? copyForForwarding() {
    if (ttl <= 1) return null; // Expired hop budget
    return MessageEnvelope(
      id: id,
      senderId: senderId,
      recipientId: recipientId,
      payload: payload,
      ttl: ttl - 1, // Decrement hop budget by 1
      timestamp: timestamp,
      type: type,
      deliveryStatus: deliveryStatus,
      hopCount: hopCount + 1, // Increment traveled hops
    );
  }

  /// Converts envelope to a Map for JSON serialization over Bluetooth radio or API.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'recipientId': recipientId,
      'payload': payload,
      'ttl': ttl,
      'timestamp': timestamp,
      'type': type.name,
      'deliveryStatus': deliveryStatus.name,
      'hopCount': hopCount,
    };
  }

  /// Factory constructor to reconstruct envelope from received JSON packet bytes.
  factory MessageEnvelope.fromJson(Map<String, dynamic> json) {
    return MessageEnvelope(
      id: json['id'] as String,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String?,
      payload: json['payload'] as String,
      ttl: json['ttl'] as int? ?? 8,
      timestamp: json['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MessageType.chat,
      ),
      deliveryStatus: DeliveryStatus.values.firstWhere(
        (e) => e.name == json['deliveryStatus'],
        orElse: () => DeliveryStatus.pending,
      ),
      hopCount: json['hopCount'] as int? ?? 0,
    );
  }
}
