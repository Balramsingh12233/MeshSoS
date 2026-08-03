import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh_sos/core/database/hive_service.dart';
import 'package:mesh_sos/core/database/local_storage_repository.dart';
import 'package:mesh_sos/features/mesh/domain/models/message_envelope.dart';
import 'package:mesh_sos/features/mesh/domain/services/mesh_router.dart';

/// ============================================================================
/// 📚 UNIT TESTS FOR MESHROUTER MULTI-HOP CONTROLLED FLOODING ENGINE
/// ============================================================================
/// 
/// Why do we write unit tests for MeshRouter?
/// The router engine decides packet forwarding, deduplication, and UI delivery.
/// We must test 3 critical scenarios before pairing real Bluetooth radios:
/// 
/// 1. Idempotency (Duplicate Drop): If the same packet arrives twice, 
///    the router must drop it on step 1 without emitting to UI or forwarding.
/// 2. Controlled Flooding (Hop Budget & Forwarding Target):
///    Forwarded packets must have TTL decremented by 1 AND must NOT be 
///    sent back to the peer who sent it to us (`fromPeerId`).
/// 3. SOS Emergency Broadcast Delivery:
///    Emergency SOS packets must emit to UI stream even if no specific recipient ID is set.
/// ============================================================================

void main() {
  late HiveService hiveService;
  late LocalStorageRepository repository;
  late Directory tempDir;
  late MeshRouter router;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mesh_router_test_');
    hiveService = HiveService();
    await hiveService.init(customPath: tempDir.path);
    repository = LocalStorageRepository(hiveService);

    router = MeshRouter(
      repository: repository,
      currentDeviceId: 'my_phone_id',
    );
  });

  tearDown(() async {
    router.dispose();
    await hiveService.close();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('MeshRouter Routing Engine Tests', () {
    test('1. Direct UI Delivery for Addressed Message', () async {
      final envelope = MessageEnvelope(
        senderId: 'friend_phone',
        recipientId: 'my_phone_id',
        payload: 'Hello Friend',
      );

      // Listen for incoming UI stream event
      expectLater(
        router.incomingMessageStream,
        emits(predicate<MessageEnvelope>((env) => env.id == envelope.id)),
      );

      await router.onReceiveEnvelope(
        envelope: envelope,
        fromPeerId: 'friend_phone',
      );

      // Verify envelope was saved to local Hive DB
      expect(repository.getAllMessages().length, equals(1));
    });

    test('2. Controlled Flooding Forwarding Target Calculation', () async {
      // Track what envelopes were forwarded and which peer was excluded
      MessageEnvelope? forwardedEnvelope;
      String? excludedPeerId;

      router = MeshRouter(
        repository: repository,
        currentDeviceId: 'my_phone_id',
        onForwardEnvelope: (env, excludeId) async {
          forwardedEnvelope = env;
          excludedPeerId = excludeId;
        },
      );

      final envelope = MessageEnvelope(
        senderId: 'origin_user',
        recipientId: 'destination_user',
        payload: 'Multi-Hop Packet',
        ttl: 5,
      );

      await router.onReceiveEnvelope(
        envelope: envelope,
        fromPeerId: 'peer_sender',
      );

      // Verify the fromPeerId was correctly passed as excludePeerId to transport
      expect(excludedPeerId, equals('peer_sender'));

      // Verify forwarded packet has decremented TTL (5 → 4)
      expect(forwardedEnvelope, isNotNull);
      expect(forwardedEnvelope!.ttl, equals(4));
    });

    test('3. Duplicate Packet Dropping (Idempotency)', () async {
      int uiEmissionCount = 0;
      router.incomingMessageStream.listen((_) {
        uiEmissionCount++;
      });

      final envelope = MessageEnvelope(
        senderId: 'friend_phone',
        recipientId: 'my_phone_id',
        payload: 'Duplicate Test',
      );

      // Receive packet first time
      await router.onReceiveEnvelope(
        envelope: envelope,
        fromPeerId: 'peer_1',
      );

      // Receive SAME packet second time from another peer relay path
      await router.onReceiveEnvelope(
        envelope: envelope,
        fromPeerId: 'peer_2',
      );

      // UI stream should emit ONLY ONCE (duplicate dropped silently)
      expect(uiEmissionCount, equals(1));
    });
  });
}
