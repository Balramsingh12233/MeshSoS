import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/hive_service.dart';
import '../../../../core/database/local_storage_repository.dart';
import '../../data/services/nearby_service.dart';
import '../../data/services/permission_service.dart';
import '../../domain/models/peer_model.dart';
import '../services/mesh_router.dart';

/// Provider for HiveService database instance
final hiveServiceProvider = Provider<HiveService>((ref) {
  return HiveService();
});

/// Provider for LocalStorageRepository persistence layer
final localStorageRepositoryProvider = Provider<LocalStorageRepository>((ref) {
  final hiveService = ref.watch(hiveServiceProvider);
  return LocalStorageRepository(hiveService);
});

/// Provider for current device unique ID (e.g. generated or phone identifier)
final currentDeviceIdProvider = Provider<String>((ref) {
  return 'device_local_user';
});

/// Provider for PermissionService — handles BLE + Location runtime permissions
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

/// Provider for NearbyService — wraps Google Nearby Connections API.
///
/// WHY: NearbyService needs the deviceId to advertise its name to other
/// peers, and is lifecycle-managed by Riverpod (disposed on app exit).
final nearbyServiceProvider = Provider<NearbyService>((ref) {
  final deviceId = ref.watch(currentDeviceIdProvider);
  final service = NearbyService(deviceId: deviceId);

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for MeshRouter multi-hop engine.
///
/// WHY: MeshRouter is now wired to NearbyService so that:
/// 1. Packets received via Nearby → router.onReceiveEnvelope()
/// 2. Router forwards packets via NearbyService.broadcastEnvelope()
/// This keeps routing logic clean and transport-agnostic in MeshRouter itself.
final meshRouterProvider = Provider<MeshRouter>((ref) {
  final repository = ref.watch(localStorageRepositoryProvider);
  final deviceId = ref.watch(currentDeviceIdProvider);
  final nearbyService = ref.watch(nearbyServiceProvider);

  final router = MeshRouter(
    repository: repository,
    currentDeviceId: deviceId,
    // Forward outbound packets through the Nearby transport layer
    onForwardEnvelope: (envelope, excludeId) async {
      await nearbyService.broadcastEnvelope(
        envelope,
        excludePeerId: excludeId,
      );
    },
  );

  // Wire incoming Nearby payloads → MeshRouter
  final subscription = nearbyService.incomingEnvelopeStream.listen((envelope) {
    router.onReceiveEnvelope(
      envelope: envelope,
      fromPeerId: envelope.senderId,
    );
  });

  ref.onDispose(() {
    subscription.cancel();
    router.dispose();
  });

  return router;
});

/// StreamProvider that emits the live list of connected Nearby peers.
///
/// WHY: UI widgets (RadarVisualizerCard, DashboardScreen status badge) need
/// to reactively update when peers join or leave the mesh. StreamProvider
/// automatically rebuilds the widget tree on each emission from NearbyService.
final nearbyPeersProvider = StreamProvider<List<Peer>>((ref) {
  final nearbyService = ref.watch(nearbyServiceProvider);
  return nearbyService.discoveredPeersStream;
});

/// FutureProvider that bootstraps the full mesh on first read.
///
/// WHY: Permissions must be requested and Nearby must be started ONCE
/// when the app opens. This provider is watched by MeshBootstrapWidget
/// so it triggers automatically at app launch without any manual call.
///
/// Flow: requestAllPermissions() → startMesh() (advertise + discover)
final meshBootstrapProvider = FutureProvider<bool>((ref) async {
  final permService = ref.watch(permissionServiceProvider);
  final nearbyService = ref.watch(nearbyServiceProvider);

  // Step 1: Request all runtime permissions (BLE + Location)
  final granted = await permService.requestAllPermissions();
  if (!granted) return false;

  // Step 2: Check GPS is on (Nearby requires location service)
  final locationOn = await permService.isLocationServiceEnabled();
  if (!locationOn) return false;

  // Step 3: Start advertising + discovery simultaneously
  await nearbyService.startMesh();

  return true;
});
