import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/local_storage/hive_setup.dart';
import 'package:uuid/uuid.dart';
import '../../../models/local/lot_local.dart';

final lotRepositoryProvider = Provider((ref) => LotRepository());

class LotRepository {
  Box get _pendingLotsBox => Hive.box(HiveBoxes.pendingLots);
  final _uuid = const Uuid();

  Future<LotLocal> saveLotLocally({
    required String category,
    required double weight,
    required String imagePath,
  }) async {
    try {
      final lot = LotLocal(
        id: _uuid.v4(),
        materialCategory: category,
        approximateWeight: weight,
        imagePath: imagePath,
        timestamp: DateTime.now(),
        isSynced: false,
        serverId: _uuid.v4(),
      );
      await _pendingLotsBox.add(lot);
      return lot;
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  List<LotLocal> getPendingLots() {
    return _pendingLotsBox.values.cast<LotLocal>().where((lot) => !lot.isSynced).toList();
  }
  
  Future<void> markAsSynced(int key) async {
    final lot = _pendingLotsBox.get(key) as LotLocal?;
    if (lot != null) {
      lot.isSynced = true;
      await lot.save();
    }
  }
}
