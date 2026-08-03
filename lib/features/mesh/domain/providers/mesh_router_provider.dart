import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/hive_service.dart';
import '../../../../core/database/local_storage_repository.dart';
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
  // Static or device UUID used to identify this node in the mesh
  return 'device_local_user';
});

/// Provider for MeshRouter multi-hop engine
final meshRouterProvider = Provider<MeshRouter>((ref) {
  final repository = ref.watch(localStorageRepositoryProvider);
  final deviceId = ref.watch(currentDeviceIdProvider);

  final router = MeshRouter(
    repository: repository,
    currentDeviceId: deviceId,
  );

  ref.onDispose(() {
    router.dispose();
  });

  return router;
});
