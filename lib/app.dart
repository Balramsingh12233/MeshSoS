import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/mesh_bootstrap_widget.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

/// MeshSOSApp is the root MaterialApp widget.
///
/// Setup Rationale:
/// Configures MaterialApp with the high-contrast dark emergency AppTheme.
/// MeshBootstrapWidget wraps DashboardScreen to auto-trigger BLE permissions
/// and NearbyService.startMesh() on first frame — fully transparent to the UI.
class MeshSOSApp extends StatelessWidget {
  const MeshSOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MeshSOS',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const MeshBootstrapWidget(
        child: DashboardScreen(),
      ),
    );
  }
}