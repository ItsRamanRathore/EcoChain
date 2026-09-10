import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/local_storage/hive_setup.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/api/price_model.dart';

final priceRepositoryProvider = Provider((ref) => PriceRepository());

class PriceRepository {
  Box get _cacheBox => Hive.box(HiveBoxes.cachedPrices);

  /// Fetches current prices for [district] from the API.
  /// Returns ([prices], isCached). On failure, returns cached data if available.
  Future<(List<PriceModel>, bool)> fetchCurrentPrices({String? district}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (district != null) queryParams['district'] = district;

      final response = await DioClient.instance.get(
        '/prices/current',
        queryParameters: queryParams,
      );

      final data = response.data as List<dynamic>;
      final prices = data
          .map((e) => PriceModel.fromJson(e as Map<String, dynamic>))
          .toList();

      await _cacheLocally(prices);
      return (prices, false);
    } on DioException {
      final cached = _readFromCache();
      return (cached, true);
    }
  }

  Future<void> _cacheLocally(List<PriceModel> prices) async {
    await _cacheBox.put('prices_data', prices.map((p) => p.toJson()).toList());
    await _cacheBox.put('cached_at', DateTime.now().toIso8601String());
  }

  List<PriceModel> _readFromCache() {
    final raw = _cacheBox.get('prices_data');
    if (raw == null) return [];
    return (raw as List<dynamic>)
        .map((e) => PriceModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// Returns a human-readable "last updated" label from the cache timestamp.
  String getLastUpdatedLabel() {
    final cachedAt = _cacheBox.get('cached_at') as String?;
    if (cachedAt == null) return 'Never synced';
    final diff = DateTime.now().difference(DateTime.parse(cachedAt));
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  /// Returns the 7-day price history for [category] to compute trend direction.
  Future<List<PriceModel>> fetchPriceHistory(String category, {int days = 7}) async {
    try {
      final response = await DioClient.instance.get(
        '/prices/history',
        queryParameters: {'category': category, 'days': days},
      );
      final data = response.data as List<dynamic>;
      return data
          .map((e) => PriceModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      return [];
    }
  }
}
