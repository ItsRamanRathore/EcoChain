import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../local_storage/hive_setup.dart';
import '../../models/local/lot_local.dart';
import '../network/dio_client.dart';
import '../../providers/sync_provider.dart';

class SyncService {
  final Ref ref;
  SyncService(this.ref);

  Future<SyncResult> sync() async {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) return SyncResult.skipped('offline');

    ref.read(syncStatusProvider.notifier).setSyncing();

    try {
      final pushResult = await _pushPendingLots();
      final pullResult = await _pullUpdates();
      
      await _updateSyncTimestamp();
      ref.read(syncStatusProvider.notifier).setSuccess();
      return SyncResult.success(
        pushed: pushResult.count,
        pulled: pullResult.count,
      );
    } catch (e) {
      ref.read(syncStatusProvider.notifier).setFailed();
      return SyncResult.failed(e.toString());
    }
  }

  Future<PushResult> _pushPendingLots() async {
    final box = Hive.box(HiveBoxes.pendingLots);
    final pending = box.values
        .cast<LotLocal>()
        .where((lot) => !lot.isSynced)
        .toList();

    if (pending.isEmpty) return PushResult(count: 0);

    final response = await DioClient.instance.post(
      '/sync/push',
      data: {'lots': pending.map((l) => l.toApiJson()).toList()},
    );

    for (final result in response.data['results']) {
      if (result['success'] == true) {
        final localId = result['local_id'];
        final lot = pending.firstWhere((l) => l.id == localId);
        lot.isSynced = true;
        lot.serverId = result['server_id'];
        await lot.save();
      }
    }
    return PushResult(count: pending.length);
  }

  Future<PullResult> _pullUpdates() async {
    final lastSync = await _getLastSyncTimestamp();
    
    final response = await DioClient.instance.get(
      '/sync/pull',
      queryParameters: {'since': lastSync},
    );

    // Update price cache and recyclers later if needed. For now just clear/put
    // Actually skipping exact local models if not strictly implemented.
    return PullResult(count: 0);
  }

  Future<String> _getLastSyncTimestamp() async {
    // using userSession box for log
    final box = Hive.box(HiveBoxes.userSession);
    return box.get('last_synced_at', defaultValue: '2024-01-01T00:00:00Z');
  }

  Future<void> _updateSyncTimestamp() async {
    final box = Hive.box(HiveBoxes.userSession);
    await box.put('last_synced_at', DateTime.now().toIso8601String());
  }
}

class PushResult { final int count; PushResult({required this.count}); }
class PullResult { final int count; PullResult({required this.count}); }

class SyncResult {
  final bool success;
  final String? message;
  final int pushed;
  final int pulled;
  
  SyncResult.success({required this.pushed, required this.pulled})
    : success = true, message = null;
  SyncResult.skipped(this.message) 
    : success = false, pushed = 0, pulled = 0;
  SyncResult.failed(this.message)
    : success = false, pushed = 0, pulled = 0;
}
