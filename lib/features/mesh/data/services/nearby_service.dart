import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import '../../domain/models/message_envelope.dart';
import '../../domain/models/peer_model.dart';

/// Status state for Nearby Connections P2P Mesh
enum MeshStatus {
  initializing,
  permissionDenied,
  locationDisabled,
  active,
  error,
}

/// NearbyService wraps the Google Nearby Connections API for Android.
///
/// FIX: removed `addSimulatedPeer()` / `clearSimulatedPeers()` entirely.
/// Those two methods were the actual root cause of the "fake devices"
/// bug - dashboard_screen.dart was calling them from a button's onTap
/// and the radar card's onLongPress, injecting fabricated Peer objects
/// into the exact same list the UI renders for REAL discovered peers.
/// There was no way to visually tell a simulated peer from a real one,
/// which is why it looked like discovery was "working" with fake results.
///
/// If you want a simulation/demo mode again later, build it as a
/// SEPARATE explicit debug flag (e.g. only behind `kDebugMode` and a
/// clearly-labeled "DEMO" badge in the UI) - never silently mixed into
/// the same stream as real discovery results.
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
  MeshStatus _status = MeshStatus.initializing;
  String? _lastErrorMessage;

  // ── Streams ───────────────────────────────────────────────────────────────
  final _incomingEnvelopeController =
  StreamController<MessageEnvelope>.broadcast();
  final _peersController = StreamController<List<Peer>>.broadcast();
  final _statusController = StreamController<MeshStatus>.broadcast();

  Stream<MessageEnvelope> get incomingEnvelopeStream =>
      _incomingEnvelopeController.stream;

  Stream<List<Peer>> get discoveredPeersStream => _peersController.stream;
  Stream<MeshStatus> get meshStatusStream => _statusController.stream;

  List<Peer> get connectedPeers => List.unmodifiable(_connectedPeers.values);
  List<Peer> get discoveredPeers => List.unmodifiable(_discoveredPeers.values);

  bool get isRunning => _isRunning;
  MeshStatus get currentStatus => _status;
  String? get lastErrorMessage => _lastErrorMessage;

  void _setStatus(MeshStatus newStatus, {String? errorMessage}) {
    _status = newStatus;
    _lastErrorMessage = errorMessage;
    _statusController.add(_status);
    debugPrint('[NearbyService] Status → $newStatus ${errorMessage != null ? "($errorMessage)" : ""}');
  }

  void markPermissionDenied() =>
      _setStatus(MeshStatus.permissionDenied,
          errorMessage: 'Bluetooth & Location permissions required');

  void markLocationDisabled() =>
      _setStatus(MeshStatus.locationDisabled,
          errorMessage: 'Location service must be enabled for device discovery');

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  Future<void> startMesh() async {
    _setStatus(MeshStatus.initializing);

    if (_isRunning) {
      try {
        await Nearby().stopAdvertising();
        await Nearby().stopDiscovery();
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (_) {}
    }

    _isRunning = true;
    _lastErrorMessage = null;

    debugPrint('[NearbyService] Starting mesh as deviceId="$deviceId", serviceId="$_serviceId"');

    final advSuccess = await _startAdvertising();
    final discSuccess = await _startDiscovery();

    debugPrint('[NearbyService] startMesh result: adv=$advSuccess disc=$discSuccess');

    if (advSuccess && discSuccess) {
      _setStatus(MeshStatus.active);
    } else {
      final errMsg = _lastErrorMessage ?? 'Failed to start advertising or discovery';
      _setStatus(MeshStatus.error, errorMessage: errMsg);
    }
  }

  Future<void> restartMesh() async {
    _isRunning = false;
    _discoveredPeers.clear();
    _connectedPeers.clear();
    _endpointNames.clear();
    _peersController.add([]);
    await startMesh();
  }

  Future<bool> _startAdvertising() async {
    try {
      await Nearby().startAdvertising(
        deviceId,
        _strategy,
        onConnectionInitiated: _onConnectionInitiated,
        onConnectionResult: _onConnectionResult,
        onDisconnected: _onDisconnected,
        serviceId: _serviceId,
      );
      debugPrint('[NearbyService] ✅ Advertising started as "$deviceId"');
      return true;
    } catch (e) {
      _lastErrorMessage = 'Advertising error: ${e.toString()}';
      debugPrint('[NearbyService] ❌ startAdvertising error: $e');
      return false;
    }
  }

  Future<bool> _startDiscovery() async {
    try {
      await Nearby().startDiscovery(
        deviceId,
        _strategy,
        onEndpointFound: _onEndpointFound,
        onEndpointLost: _onEndpointLost,
        serviceId: _serviceId,
      );
      debugPrint('[NearbyService] ✅ Discovery started as "$deviceId"');
      return true;
    } catch (e) {
      _lastErrorMessage = 'Discovery error: ${e.toString()}';
      debugPrint('[NearbyService] ❌ startDiscovery error: $e');
      return false;
    }
  }

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
    debugPrint('[NearbyService] stopAll complete');
  }

  // ── Callbacks ─────────────────────────────────────────────────────────────

  void _onConnectionInitiated(String endpointId, ConnectionInfo info) {
    _endpointNames[endpointId] = info.endpointName;
    debugPrint('[NearbyService] 🔗 Connection initiated: endpointId=$endpointId name="${info.endpointName}"');

    Nearby().acceptConnection(
      endpointId,
      onPayLoadRecieved: _onPayloadReceived,
      onPayloadTransferUpdate: (_, __) {},
    );
  }

  void _onConnectionResult(String endpointId, Status status) {
    final name = _endpointNames[endpointId] ?? endpointId;
    debugPrint('[NearbyService] 🔗 Connection result: $endpointId → $status');
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
      debugPrint('[NearbyService] ✅ Connected to $endpointId ($name). Total peers: ${_connectedPeers.length}');
    } else {
      debugPrint('[NearbyService] ⚠️ Connection rejected/failed for $endpointId: $status');
    }
  }

  void _onDisconnected(String endpointId) {
    _connectedPeers.remove(endpointId);
    _discoveredPeers.remove(endpointId);
    _peersController.add(discoveredPeers);
    debugPrint('[NearbyService] 🔌 Disconnected from $endpointId. Remaining peers: ${_connectedPeers.length}');
  }

  void _onEndpointFound(
      String endpointId, String endpointName, String serviceId) {
    _endpointNames[endpointId] = endpointName;
    debugPrint('[NearbyService] 📡 Endpoint FOUND: $endpointId ($endpointName) serviceId=$serviceId');

    final peer = Peer(
      id: endpointId,
      displayName: endpointName,
      isOnline: true,
      hopDistance: 1,
      lastConnectedAt: DateTime.now(),
    );
    _discoveredPeers[endpointId] = peer;
    _peersController.add(discoveredPeers);

    Nearby().requestConnection(
      deviceId,
      endpointId,
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
    ).catchError((e) {
      debugPrint('[NearbyService] requestConnection error (may be duplicate): $e');
    });
  }

  void _onEndpointLost(String? endpointId) {
    if (endpointId != null) {
      final wasConnected = _connectedPeers.containsKey(endpointId);
      _connectedPeers.remove(endpointId);
      _discoveredPeers.remove(endpointId);
      _peersController.add(discoveredPeers);
      debugPrint('[NearbyService] 📡 Endpoint LOST: $endpointId (wasConnected=$wasConnected)');
    }
  }

  void _onPayloadReceived(String endpointId, Payload payload) {
    if (payload.type == PayloadType.BYTES && payload.bytes != null) {
      try {
        final json = utf8.decode(payload.bytes!);
        final envelope = MessageEnvelope.fromJson(jsonDecode(json));
        _incomingEnvelopeController.add(envelope);
        debugPrint('[NearbyService] 📨 Payload received from $endpointId: ${payload.bytes!.length} bytes');
      } catch (e) {
        debugPrint('[NearbyService] Payload decode error: $e');
      }
    }
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> sendEnvelope(String endpointId, MessageEnvelope envelope) async {
    try {
      final bytes = utf8.encode(jsonEncode(envelope.toJson()));
      await Nearby().sendBytesPayload(endpointId, bytes);
      debugPrint('[NearbyService] 📤 Sent ${bytes.length} bytes to $endpointId');
    } catch (e) {
      debugPrint('[NearbyService] sendBytesPayload error to $endpointId: $e');
    }
  }

  Future<void> broadcastEnvelope(MessageEnvelope envelope,
      {String? excludePeerId}) async {
    final targets = _connectedPeers.keys
        .where((id) => id != excludePeerId)
        .toList();
    debugPrint('[NearbyService] 📢 Broadcasting to ${targets.length} peers');
    for (final peerId in targets) {
      await sendEnvelope(peerId, envelope);
    }
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  void dispose() {
    stopAll();
    _incomingEnvelopeController.close();
    _peersController.close();
    _statusController.close();
  }
}