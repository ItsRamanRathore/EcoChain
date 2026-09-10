import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/api/handover_record.dart';

final handoverRepositoryProvider = Provider((ref) => HandoverRepository());

class HandoverRepository {
  Future<HandoverRecord> generateHandover({
    required String lotId,
    required double actualWeight,
    required double finalPrice,
    required Map<String, double> handoverGps,
    required String recyclerId,
    required String materialCategory,
  }) async {
    final response = await DioClient.instance.post(
      '/handover/$lotId/generate',
      data: {
        'recycler_id': recyclerId,
        'actual_weight': actualWeight,
        'final_price': finalPrice,
        'handover_gps': handoverGps,
        'material_category': materialCategory,
      },
    );
    return HandoverRecord.fromJson(response.data);
  }

  Future<void> confirmHandover({
    required String lotId,
    required String recyclerId,
    required double actualWeight,
    required String handoverGps,
  }) async {
    // For demo purposes, we call the confirm endpoint from the collector app
    // In reality, this would be called by the recycler's portal.
    await DioClient.instance.post(
      '/handover/$lotId/confirm',
      data: {
        'recycler_id': recyclerId,
        'actual_weight': actualWeight,
        'handover_gps': handoverGps,
      },
    );
  }
}
