import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/api/recycler_model.dart';

final recyclerRepositoryProvider = Provider((ref) => RecyclerRepository());

class RecyclerRepository {
  Future<List<RecyclerModel>> matchRecyclers({
    required double lat,
    required double lng,
    required String category,
    int radiusKm = 50,
  }) async {
    try {
      final response = await DioClient.instance.get(
        '/recyclers/match',
        queryParameters: {
          'lat': lat,
          'lng': lng,
          'category': category,
          'radius_km': radiusKm,
        },
      );
      final data = response.data as List<dynamic>;
      return data
          .map((e) => RecyclerModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }
}
