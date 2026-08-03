import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

/// PermissionService handles all runtime permissions required by the
/// Nearby Connections API (BLE + WiFi + Location).
///
/// Per official nearby_connections docs:
/// - ACCESS_FINE_LOCATION, BLUETOOTH_ADVERTISE, BLUETOOTH_CONNECT,
///   BLUETOOTH_SCAN, NEARBY_WIFI_DEVICES are "dangerous" permissions requiring runtime grant.
/// - Location Service (GPS) MUST be enabled or Nearby will fail to discover or disconnect immediately.
class PermissionService {
  /// Request all permissions needed for Nearby Connections to work.
  /// Returns true if essential permissions are granted.
  Future<bool> requestAllPermissions() async {
    if (!Platform.isAndroid) return true;

    // 1. Request Runtime Permissions using permission_handler
    final statuses = await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.nearbyWifiDevices,
    ].request();

    // Check location permission is granted
    final locationGranted = (statuses[Permission.location]?.isGranted ?? false) ||
        (statuses[Permission.locationWhenInUse]?.isGranted ?? false);

    return locationGranted;
  }

  /// Check if Location service (GPS) is actually enabled.
  Future<bool> isLocationServiceEnabled() async {
    if (!Platform.isAndroid) return true;
    return await Permission.location.serviceStatus.isEnabled;
  }

  /// Returns true only if essential permissions are already granted.
  Future<bool> arePermissionsGranted() async {
    if (!Platform.isAndroid) return true;

    final locationGranted = await Permission.location.isGranted ||
        await Permission.locationWhenInUse.isGranted;

    return locationGranted;
  }
}
