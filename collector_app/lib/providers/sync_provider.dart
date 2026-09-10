import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/network/sync_service.dart';

final isOnlineProvider = StateProvider<bool>((ref) => true);

enum SyncStatus { idle, syncing, success, failed, offline }

class SyncStatusNotifier extends StateNotifier<SyncStatus> {
  SyncStatusNotifier() : super(SyncStatus.idle);
  void setSyncing() => state = SyncStatus.syncing;
  void setSuccess() => state = SyncStatus.success;
  void setFailed() => state = SyncStatus.failed;
  void setOffline() => state = SyncStatus.offline;
  void setIdle() => state = SyncStatus.idle;
}

final syncStatusProvider = StateNotifierProvider<SyncStatusNotifier, SyncStatus>((ref) {
  return SyncStatusNotifier();
});

final syncServiceProvider = Provider<SyncService>((ref) {
  return SyncService(ref);
});

final connectivitySyncProvider = Provider((ref) {
  Connectivity().onConnectivityChanged.listen((results) {
    final result = results.isNotEmpty ? results.first : ConnectivityResult.none;
    final isNowOnline = result != ConnectivityResult.none;
    final wasOnline = ref.read(isOnlineProvider);
    
    ref.read(isOnlineProvider.notifier).state = isNowOnline;
    
    if (!wasOnline && isNowOnline) {
      ref.read(syncServiceProvider).sync();
    } else if (!isNowOnline) {
      ref.read(syncStatusProvider.notifier).setOffline();
    }
  });
});
