import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// FIX: currentDeviceIdProvider previously generated a random "Node_XXXX"
/// on EVERY app launch, and that same random string was used as both:
///   1. The name advertised to nearby peers (what they see in the UI)
///   2. The stable id used to address messages (recipientId matching)
///
/// This meant a device's name changed every time the app restarted, and
/// there was no human-readable way for a peer to know who they're
/// talking to. This service persists a display name the user sets once,
/// so it stays stable across launches and is actually recognizable.
class IdentityService {
  static const _displayNameKey = 'meshsos_display_name';
  static const _stableIdKey = 'meshsos_stable_id';

  final SharedPreferences _prefs;

  IdentityService(this._prefs);

  static Future<IdentityService> create() async {
    final prefs = await SharedPreferences.getInstance();
    return IdentityService(prefs);
  }

  String? get displayName => _prefs.getString(_displayNameKey);

  Future<void> setDisplayName(String name) async {
    await _prefs.setString(_displayNameKey, name.trim());
  }

  bool get hasDisplayName =>
      displayName != null && displayName!.trim().isNotEmpty;

  /// A short, stable suffix so two people who pick the same first name
  /// don't collide as the same mesh identity. Generated once, persisted
  /// forever after - NOT regenerated on every launch like the old code.
  String get stableSuffix {
    var id = _prefs.getString(_stableIdKey);
    if (id == null) {
      id = const Uuid().v4().substring(0, 4).toUpperCase();
      _prefs.setString(_stableIdKey, id);
    }
    return id;
  }

  /// The actual identity string advertised to peers AND used for
  /// message addressing - e.g. "Rahul-9F3A". Stable across restarts.
  String get meshDeviceId {
    final name = displayName ?? 'Guest';
    return '$name-$stableSuffix';
  }
}