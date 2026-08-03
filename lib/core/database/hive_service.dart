import 'package:hive_flutter/hive_flutter.dart';

/// HiveService manages offline persistence for MeshSOS using Hive database.
/// 
/// System Design Rationale for Big Tech / Offline-First Apps:
/// 1. Zero Network Dependency: All incoming mesh messages, peer contact lists, 
///    and packet duplicate caches are stored locally on device disk.
/// 2. O(1) Seen ID Cache: We store processed packet UUIDs in `seenIdsBox`. 
///    Checking if a packet has already been received is a fast O(1) key lookup.
/// 3. Crash Recovery: On device restart, Hive reloads message history instantly 
///    without waiting for any server connection.
class HiveService {
  static const String messagesBoxName = 'mesh_sos_messages';
  static const String seenIdsBoxName = 'mesh_sos_seen_ids';
  static const String peersBoxName = 'mesh_sos_peers';

  late Box<Map> _messagesBox;
  late Box<bool> _seenIdsBox;
  late Box<Map> _peersBox;

  /// Initializes Hive database and opens required persistent storage boxes.
  Future<void> init({String? customPath}) async {
    if (customPath != null) {
      Hive.init(customPath);
    } else {
      await Hive.initFlutter();
    }

    _messagesBox = await Hive.openBox<Map>(messagesBoxName);
    _seenIdsBox = await Hive.openBox<bool>(seenIdsBoxName);
    _peersBox = await Hive.openBox<Map>(peersBoxName);
  }

  /// Direct access to messages box
  Box<Map> get messagesBox => _messagesBox;

  /// Direct access to seen packet UUIDs box
  Box<bool> get seenIdsBox => _seenIdsBox;

  /// Direct access to discovered peers box
  Box<Map> get peersBox => _peersBox;

  /// Closes all open database boxes safely
  Future<void> close() async {
    await Hive.close();
  }
}
