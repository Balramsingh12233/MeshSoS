import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// PermissionService handles all runtime permissions required by the
/// Nearby Connections API (error 8032 = STATUS_MISSING_PERMISSION when any is missing).
///
/// Required permissions per Android API level:
///   All APIs : ACCESS_FINE_LOCATION
///   API 31+  : BLUETOOTH_ADVERTISE, BLUETOOTH_CONNECT, BLUETOOTH_SCAN
///   API 33+  : NEARBY_WIFI_DEVICES  ← most common cause of error 8032!
///
/// Root cause of "PlatformException(Failure, 8032: MISSING_PERMISSION_NEARBY_WIFI_DEVICES)":
///   The old code requested nearbyWifiDevices but never checked if it was
///   actually granted before calling startDiscovery() → Nearby SDK threw 8032.
class PermissionService {
  /// Request ALL permissions needed for Nearby Connections in a single batch.
  ///
  /// Batching via List.request() is more reliable than sequential requests on
  /// OEM devices (OPPO, Realme, Xiaomi) that throttle per-permission dialogs.
  ///
  /// Returns true only when EVERY required permission is granted.
  Future<bool> requestAllPermissions() async {
    if (!Platform.isAndroid) return true;

    // ── Batch request all dangerous permissions at once ───────────────────
    // permission_handler automatically skips permissions not applicable to the
    // current API level (e.g. BLUETOOTH_SCAN is auto-granted on API < 31).
    final statuses = await [
      Permission.location,            // Required on ALL API levels
      Permission.bluetoothAdvertise,  // Required API 31+  (auto-granted below)
      Permission.bluetoothConnect,    // Required API 31+  (auto-granted below)
      Permission.bluetoothScan,       // Required API 31+  (auto-granted below)
      Permission.nearbyWifiDevices,   // Required API 33+ — THE CAUSE OF ERROR 8032
    ].request();

    final locationStatus    = statuses[Permission.location]!;
    final btAdvertise       = statuses[Permission.bluetoothAdvertise]!;
    final btConnect         = statuses[Permission.bluetoothConnect]!;
    final btScan            = statuses[Permission.bluetoothScan]!;
    final nearbyWifi        = statuses[Permission.nearbyWifiDevices]!;

    debugPrint('[PermissionService] Results:');
    debugPrint('  location          → $locationStatus');
    debugPrint('  bluetoothAdvertise→ $btAdvertise');
    debugPrint('  bluetoothConnect  → $btConnect');
    debugPrint('  bluetoothScan     → $btScan');
    debugPrint('  nearbyWifiDevices → $nearbyWifi  ← must be granted on API 33+');

    // ── Check each permission ─────────────────────────────────────────────
    final locationGranted  = locationStatus.isGranted || locationStatus == PermissionStatus.limited;
    final btAdvertiseOk    = btAdvertise.isGranted;
    final btConnectOk      = btConnect.isGranted;
    final btScanOk         = btScan.isGranted;
    // CRITICAL FIX: nearbyWifi MUST be granted on API 33+ for startDiscovery()
    // to succeed. On API < 33, permission_handler returns isGranted=true automatically.
    final nearbyWifiOk     = nearbyWifi.isGranted;

    debugPrint('[PermissionService] Check: location=$locationGranted '
        'btAdvertise=$btAdvertiseOk btConnect=$btConnectOk '
        'btScan=$btScanOk nearbyWifi=$nearbyWifiOk');

    // ── Handle permanently denied — guide user to Settings ───────────────
    final permanentlyDenied = [
      locationStatus,
      btAdvertise,
      btConnect,
      btScan,
      nearbyWifi,
    ].any((s) => s.isPermanentlyDenied);

    if (permanentlyDenied) {
      debugPrint('[PermissionService] ⚠️ One or more permissions permanently denied — opening Settings');
      await openAppSettings();
      return false;
    }

    // ALL required permissions must be granted
    final allGranted = locationGranted &&
        btAdvertiseOk &&
        btConnectOk &&
        btScanOk &&
        nearbyWifiOk;       // ← was MISSING before — caused error 8032

    debugPrint('[PermissionService] allGranted=$allGranted');
    return allGranted;
  }

  /// Check if Location SERVICE (GPS) is actually enabled on the device.
  ///
  /// WHY: Google Nearby Connections requires location services to be ON.
  /// Even with permission granted, Nearby disconnects immediately when GPS is off.
  Future<bool> isLocationServiceEnabled() async {
    if (!Platform.isAndroid) return true;
    final enabled = await Permission.location.serviceStatus.isEnabled;
    debugPrint('[PermissionService] locationServiceEnabled=$enabled');
    return enabled;
  }

  /// Check if Bluetooth hardware service is ON.
  ///
  /// WHY: Nearby also fails if Bluetooth is disabled even with permissions granted.
  Future<bool> isBluetoothEnabled() async {
    if (!Platform.isAndroid) return true;
    final enabled = await Permission.bluetooth.serviceStatus.isEnabled;
    debugPrint('[PermissionService] bluetoothEnabled=$enabled');
    return enabled;
  }

  /// Returns true only if ALL essential permissions are already granted.
  Future<bool> arePermissionsGranted() async {
    if (!Platform.isAndroid) return true;

    final location         = await Permission.location.isGranted;
    final btAdvertise      = await Permission.bluetoothAdvertise.isGranted;
    final btConnect        = await Permission.bluetoothConnect.isGranted;
    final btScan           = await Permission.bluetoothScan.isGranted;
    final nearbyWifi       = await Permission.nearbyWifiDevices.isGranted;

    return location && btAdvertise && btConnect && btScan && nearbyWifi;
  }
}
