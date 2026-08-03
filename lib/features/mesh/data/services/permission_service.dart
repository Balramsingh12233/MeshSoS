import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// PermissionService handles all runtime permissions required by the
/// Nearby Connections API (BLE + WiFi + Location).
///
/// Per official nearby_connections docs:
/// - ACCESS_FINE_LOCATION, BLUETOOTH_ADVERTISE, BLUETOOTH_CONNECT,
///   BLUETOOTH_SCAN are "dangerous" permissions requiring runtime grant.
/// - GPS service must also be enabled or Nearby will disconnect devices.
class PermissionService {
  /// Request all permissions needed for Nearby Connections to work.
  /// Returns true if every required permission is granted.
  Future<bool> requestAllPermissions() async {
    if (!Platform.isAndroid) return true; // iOS not supported by nearby_connections

    final statuses = await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    final allGranted = statuses.values.every(
      (s) => s == PermissionStatus.granted || s == PermissionStatus.limited,
    );

    return allGranted;
  }

  /// Check if Location service (GPS) is actually enabled.
  /// Nearby Connections needs GPS ON or devices disconnect immediately.
  Future<bool> isLocationServiceEnabled() async {
    if (!Platform.isAndroid) return true;
    return await Permission.location.serviceStatus.isEnabled;
  }

  /// Returns true only if ALL permissions are already granted (no dialog).
  Future<bool> arePermissionsGranted() async {
    if (!Platform.isAndroid) return true;

    final checks = await Future.wait([
      Permission.location.isGranted,
      Permission.bluetooth.isGranted,
      Permission.bluetoothAdvertise.isGranted,
      Permission.bluetoothConnect.isGranted,
      Permission.bluetoothScan.isGranted,
    ]);

    return checks.every((granted) => granted);
  }
}
