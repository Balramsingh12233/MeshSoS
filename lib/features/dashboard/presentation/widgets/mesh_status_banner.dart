import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../mesh/data/services/nearby_service.dart';
import '../../../mesh/domain/providers/mesh_router_provider.dart';

/// MeshStatusBanner shows an actionable error card when mesh fails to start.
///
/// WHY: Users need clear, actionable feedback when BT/location permissions
/// are missing or GPS is disabled. This replaces a silent failure.
///
/// The banner is:
///   - Hidden when status is [MeshStatus.active] or [MeshStatus.initializing]
///   - Shown with "Open Settings" CTA when status is [MeshStatus.permissionDenied]
///   - Shown with "Enable GPS" CTA when status is [MeshStatus.locationDisabled]
///   - Shown with "Retry" CTA when status is [MeshStatus.error]
class MeshStatusBanner extends ConsumerWidget {
  const MeshStatusBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(meshStatusProvider);

    return statusAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (status) {
        if (status == MeshStatus.active || status == MeshStatus.initializing) {
          return const SizedBox.shrink();
        }
        return _BannerCard(status: status, ref: ref);
      },
    );
  }
}

class _BannerCard extends StatelessWidget {
  final MeshStatus status;
  final WidgetRef ref;

  const _BannerCard({required this.status, required this.ref});

  @override
  Widget build(BuildContext context) {
    final (icon, title, subtitle, actionLabel, onAction) = _config(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0E0E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.4), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.12),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              backgroundColor: Colors.redAccent.withOpacity(0.14),
              foregroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              actionLabel,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  (IconData, String, String, String, VoidCallback) _config(BuildContext ctx) {
    switch (status) {
      case MeshStatus.permissionDenied:
        return (
          Icons.bluetooth_disabled_rounded,
          'Permissions Required',
          'Bluetooth & Location access needed for mesh',
          'Fix',
          () => ref.invalidate(meshBootstrapProvider),
        );
      case MeshStatus.locationDisabled:
        return (
          Icons.location_off_rounded,
          'GPS Disabled',
          'Enable Location Services for device discovery',
          'Enable',
          () => ref.invalidate(meshBootstrapProvider),
        );
      case MeshStatus.error:
        final msg = ref.read(nearbyServiceProvider).lastErrorMessage ?? 'Unknown error';
        return (
          Icons.wifi_off_rounded,
          'Mesh Error',
          msg,
          'Retry',
          () => ref.invalidate(meshBootstrapProvider),
        );
      default:
        return (
          Icons.error_outline_rounded,
          'Mesh Offline',
          'Tap retry to reconnect',
          'Retry',
          () => ref.invalidate(meshBootstrapProvider),
        );
    }
  }
}
