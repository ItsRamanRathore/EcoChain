import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repository/price_repository.dart';
import '../../../models/api/price_model.dart';

/// Fetches current prices. Returns ([prices], isCached).
/// Call with an optional district filter.
final currentPricesProvider = FutureProvider.family<(List<PriceModel>, bool), String?>(
  (ref, district) async {
    final repo = ref.read(priceRepositoryProvider);
    return repo.fetchCurrentPrices(district: district);
  },
);

/// 7-day history for a single category — used to determine trend arrow direction.
final priceHistoryProvider = FutureProvider.family<List<PriceModel>, String>(
  (ref, category) async {
    final repo = ref.read(priceRepositoryProvider);
    return repo.fetchPriceHistory(category);
  },
);
