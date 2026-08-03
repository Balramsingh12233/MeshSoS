import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/mesh/domain/providers/mesh_router_provider.dart';

/// MeshBootstrapWidget wraps the app root and triggers mesh startup automatically.
///
/// WHY: We need permissions to be requested and NearbyService.startMesh()
/// to be called exactly ONCE when the app first opens. By watching
/// meshBootstrapProvider here (at the root), Riverpod's FutureProvider
/// fires on the first frame without any manual initState() or lifecycle hook.
///
/// The widget transparently passes its child through — it has zero visual impact.
class MeshBootstrapWidget extends ConsumerWidget {
  final Widget child;
  const MeshBootstrapWidget({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch bootstrap — fires once, handles permissions + startMesh()
    final bootstrap = ref.watch(meshBootstrapProvider);

    // Also pre-warm the meshRouterProvider so the NearbyService stream
    // subscription is active before any UI tries to listen
    ref.watch(meshRouterProvider);

    bootstrap.when(
      data: (granted) {
        if (!granted) {
          // Silently log — the app still runs in demo mode without BLE
          debugPrint('[MeshBootstrap] Permissions denied or GPS off — demo mode');
        } else {
          debugPrint('[MeshBootstrap] ✅ Mesh active — advertising + discovering');
        }
      },
      loading: () => debugPrint('[MeshBootstrap] Requesting permissions...'),
      error: (e, _) => debugPrint('[MeshBootstrap] Error: $e'),
    );

    // Always render the child — the mesh runs in background
    return child;
  }
}
