import 'dart:async';
import 'dart:convert';
import 'package:nearby_connections/nearby_connections.dart';
import '../../domain/models/message_envelope.dart';
import '../../domain/models/peer_model.dart';

/// NearbyService wraps the Google Nearby Connections API for Android.
///
/// Architecture (per official nearby_connections 4.3.0 docs):
///   Strategy: P2P_CLUSTER (many-to-many mesh — best for emergency networks)
///   ServiceId: 'com.example.mesh_sos' (unique app identifier)
class NearbyService {
  static const String _serviceId = 'com.example.mesh_sos';
  final Strategy _strategy = Strategy.P2P_CLUSTER;

  final String deviceId;

  NearbyService({required this.deviceId});

  // ── State ─────────────────────────────────────────────────────────────────
  final Map<String, Peer> _discoveredPeers = {};
  final Map<String, Peer> _connectedPeers = {};
  final Map<String, String> _endpointNames = {};
  bool _isRunning = false;

  // ── Streams ───────────────────────────────────────────────────────────────
  final _incomingEnvelopeController =
      StreamController<MessageEnvelope>.broadcast();
  final _peersController = StreamController<List<Peer>>.broadcast();

  Stream<MessageEnvelope> get incomingEnvelopeStream =>
      _incomingEnvelopeController.stream;

  Stream<List<Peer>> get discoveredPeersStream => _peersController.stream;

  List<Peer> get connectedPeers => List.unmodifiable(_connectedPeers.values);
  List<Peer> get discoveredPeers => List.unmodifiable(_discoveredPeers.values);

  bool get isRunning => _isRunning;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Start advertising and discovering simultaneously.
  Future<void> startMesh() async {
    if (_isRunning) return;
    _isRunning = true;

    // Stop any stale sessions first for a clean state
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
    } catch (_) {}

    await _startAdvertising();
    await _startDiscovery();
  }

  Future<void> _startAdvertising() async {
    try {
      await Nearby().startAdvertising(
        deviceId,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
      // ignore: avoid_print
      print('[NearbyService] ✅ Advertising started as "$deviceId"');
    } catch (e) {
      // ignore: avoid_print
      print('[NearbyService] ❌ startAdvertising error: $e');
    }
  }

  Future<void> _startDiscovery() async {
    try {
      await Nearby().startDiscovery(
        deviceId,
        _strategy,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _serviceId,
      );
      // ignore: avoid_print
      print('[NearbyService] ✅ Discovery started as "$deviceId"');
    } catch (e) {
      // ignore: avoid_print
      print('[NearbyService] ❌ startDiscovery error: $e');
    }
  }

  /// Stop all Nearby activity and clean up.
  Future<void> stopAll() async {
    _isRunning = false;
    _discoveredPeers.clear();
    _connectedPeers.clear();
    _endpointNames.clear();
    _peersController.add([]);
    try {
      await Nearby().stopAdvertising();
      await Nearby().stopDiscovery();
      await Nearby().stopAllEndpoints();
    } catch (_) {}
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  /// Called when a remote device initiates OR responds to a connection.
  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    _endpointNames[endpointId] = info.endpointName;
    // ignore: avoid_print
    print('[NearbyService] Connection initiated with $endpointId (${info.endpointName})');

    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (_, __) {},
    );
  }

  /// Called after connection accepted/rejected.
  void _onConnectionResult(String endpointId, Status status) {
    final name = _endpointNames[endpointId] ?? endpointId;
    if (status == Status.CONNECTED) {
      final peer = Peer(
        id: endpointId,
        displayName: name,
        isOnline: true,
        hopDistance: 1,
        lastConnectedAt: DateTime.now(),
      );
      _connectedPeers[endpointId] = peer;
      _discoveredPeers[endpointId] = peer;
      _peersController.add(discoveredPeers);
      // ignore: avoid_print
      print('[NearbyService] ✅ Connected to $endpointId ($name)');
    } else {
      // ignore: avoid_print
      print('[NearbyService] Connection rejected/failed for $endpointId: $status');
    }
  }

  /// Called when a peer disconnects.
  void _onDisconnected(String endpointId) {
    _connectedPeers.remove(endpointId);
    _discoveredPeers.remove(endpointId);
    _peersController.add(discoveredPeers);
    // ignore: avoid_print
    print('[NearbyService] Disconnected from $endpointId');
  }

  /// Called when Discovery finds an advertising device.
  void _onEndpointFound(
      String endpointId, String endpointName, String serviceId) {
    _endpointNames[endpointId] = endpointName;
    // ignore: avoid_print
    print('[NearbyService] 📡 Endpoint found: $endpointId ($endpointName)');

    final peer = Peer(
      id: endpointId,
      displayName: endpointName,
      isOnline: true,
      hopDistance: 1,
      lastConnectedAt: DateTime.now(),
    );
    _discoveredPeers[endpointId] = peer;
    _peersController.add(discoveredPeers);

    try {
      Nearby().requestConnection(
        deviceId,
        endpointId,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[NearbyService] requestConnection error: $e');
    }
  }

  /// Called when a previously found endpoint is no longer visible.
  void _onEndpointLost(String? endpointId) {
    if (endpointId != null) {
      _connectedPeers.remove(endpointId);
      _discoveredPeers.remove(endpointId);
      _peersController.add(discoveredPeers);
    }
  }

  /// Called when a bytes payload arrives from a connected peer.
  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      try {
        final json = utf8.decode(payload.bytes!);
        final envelope = MessageEnvelope.fromJson(jsonDecode(json));
        _incomingEnvelopeController.add(envelope);
      } catch (e) {
        // ignore: avoid_print
        print('[NearbyService] Payload decode error: $e');
      }
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  /// Send a MessageEnvelope as JSON bytes to a specific connected peer.
  Future<void> sendEnvelope(String endpointId, MessageEnvelope envelope) async {
    try {
      final bytes = utf8.encode(jsonEncode(envelope.toJson()));
      await Nearby().sendBytesPayload(endpointId, bytes);
    } catch (e) {
      // ignore: avoid_print
      print('[NearbyService] sendBytesPayload error to $endpointId: $e');
    }
  }

  /// Broadcast an envelope to ALL currently connected peers.
  Future<void> broadcastEnvelope(MessageEnvelope envelope,
      {String? excludePeerId}) async {
    for (final peerId in _connectedPeers.keys) {
      if (peerId != excludePeerId) {
        await sendEnvelope(peerId, envelope);
      }
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  void dispose() {
    stopAll();
    _incomingEnvelopeController.close();
    _peersController.close();
  }
}
