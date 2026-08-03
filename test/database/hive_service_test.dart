import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh_sos/core/database/hive_service.dart';
import 'package:mesh_sos/core/database/local_storage_repository.dart';
import 'package:mesh_sos/features/mesh/domain/models/message_envelope.dart';
import 'package:mesh_sos/features/mesh/domain/models/peer_model.dart';

/// ============================================================================
/// 📚 UNIT TESTS FOR HIVE OFFLINE DATABASE & DE-DUPLICATION CACHE
/// ============================================================================
/// 
/// Why do we test Hive database persistence?
/// 1. Offline Storage Guarantee: Messages must survive app restarts and 
///    loss of battery/internet connectivity.
/// 2. Deduplication Cache: We must verify that `saveEnvelope` automatically 
///    marks packet UUIDs as seen so duplicate flooding packets are dropped.
/// ============================================================================

void main() {
  late HiveService hiveService;
  late LocalStorageRepository repository;
  late Directory tempDir;

  setUp(() async {
    // Create a temporary isolated directory for test database files
    tempDir = await Directory.systemTemp.createTemp('mesh_sos_hive_test_');
    hiveService = HiveService();
    await hiveService.init(customPath: tempDir.path);
    repository = LocalStorageRepository(hiveService);
  });

  tearDown(() async {
    await hiveService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Hive Offline Persistence & Deduplication Tests', () {
    test('1. Save Envelope & O(1) Deduplication Check', () async {
      final envelope = MessageEnvelope(
        senderId: 'device_Alice',
        payload: 'Emergency SOS Broadcast',
      );

      // Initially message ID should NOT be in seenIds cache
      expect(repository.isSeen(envelope.id), isFalse);

      // Save envelope to offline DB
      await repository.saveEnvelope(envelope);

      // Verify message ID is NOW marked as seen
      expect(repository.isSeen(envelope.id), isTrue);
    });

    test('2. Message Retrieval & Timestamp Sorting', () async {
      final env1 = MessageEnvelope(
        senderId: 'device_A',
        payload: 'First Message',
        timestamp: 1000,
      );

      final env2 = MessageEnvelope(
        senderId: 'device_B',
        payload: 'Second Message',
        timestamp: 2000,
      );

      await repository.saveEnvelope(env1);
      await repository.saveEnvelope(env2);

      final allMessages = repository.getAllMessages();

      expect(allMessages.length, equals(2));
      expect(allMessages.first.payload, equals('First Message'));
      expect(allMessages.last.payload, equals('Second Message'));
    });

    test('3. Peer Discovered Cache Storage', () async {
      final peer = Peer(
        id: 'peer_99',
        displayName: "Charlie's Device",
        hopDistance: 2,
      );

      await repository.savePeer(peer);

      final peers = repository.getAllPeers();
      expect(peers.length, equals(1));
      expect(peers.first.id, equals('peer_99'));
      expect(peers.first.displayName, equals("Charlie's Device"));
      expect(peers.first.hopDistance, equals(2));
    });
  });
}
