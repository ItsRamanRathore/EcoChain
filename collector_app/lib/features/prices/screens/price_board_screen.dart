import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/api/price_model.dart';
import '../providers/price_provider.dart';
import '../repository/price_repository.dart';

// ─── Category display config ────────────────────────────────────────────────

const _categoryConfig = <String, _CatMeta>{
  'PCB':     _CatMeta(icon: Icons.developer_board,    color: Color(0xFF00C896), label: 'Circuit Boards'),
  'Cable':   _CatMeta(icon: Icons.cable,               color: Color(0xFFFFAA00), label: 'Cables'),
  'Battery': _CatMeta(icon: Icons.battery_charging_full, color: Color(0xFFFF4D6D), label: 'Batteries'),
  'LCD':     _CatMeta(icon: Icons.monitor,             color: Color(0xFF4D9FFF), label: 'LCD / Monitors'),
  'CRT':     _CatMeta(icon: Icons.tv,                  color: Color(0xFF9E9E9E), label: 'CRT / Old TVs'),
  'Motor':   _CatMeta(icon: Icons.settings,            color: Color(0xFFBF8052), label: 'Motors'),
  'Plastic': _CatMeta(icon: Icons.recycling,           color: Color(0xFFAB47BC), label: 'Plastic Casings'),
  'Mixed':   _CatMeta(icon: Icons.category,            color: Color(0xFF26A69A), label: 'Mixed E-Waste'),
};

class _CatMeta {
  final IconData icon;
  final Color color;
  final String label;
  const _CatMeta({required this.icon, required this.color, required this.label});
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class PriceBoardScreen extends ConsumerStatefulWidget {
  const PriceBoardScreen({super.key});

  @override
  ConsumerState<PriceBoardScreen> createState() => _PriceBoardScreenState();
}

class _PriceBoardScreenState extends ConsumerState<PriceBoardScreen> {
  String _selectedDistrict = 'Mumbai';
  final List<String> _districts = ['Mumbai', 'Delhi', 'Bangalore', 'Pune'];
  int _refreshKey = 0; // bumped on pull-to-refresh to invalidate provider

  void _refresh() {
    setState(() => _refreshKey++);
    ref.invalidate(currentPricesProvider(_selectedDistrict));
    ref.invalidate(priceHistoryProvider);
  }

  @override
  Widget build(BuildContext context) {
    final pricesAsync = ref.watch(currentPricesProvider(_selectedDistrict));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(context, pricesAsync),
      body: RefreshIndicator(
        onRefresh: () async => _refresh(),
        color: const Color(0xFF00C896),
        backgroundColor: const Color(0xFFFFFFFF),
        child: pricesAsync.when(
          loading: () => _buildLoading(),
          error: (e, _) => _buildError(e),
          data: (result) {
            final (prices, isCached) = result;
            return _buildContent(prices, isCached);
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, AsyncValue<(List<PriceModel>, bool)> pricesAsync) {
    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF),
      title: const Text(
        'Price Board',
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 22,
          letterSpacing: 0.5,
        ),
      ),
      actions: [
        // District filter pill
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedDistrict,
              dropdownColor: const Color(0xFFFFFFFF),
              icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF00C896)),
              style: const TextStyle(color: Colors.black87, fontSize: 14),
              items: _districts
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedDistrict = v);
                  ref.invalidate(currentPricesProvider(v));
                }
              },
            ),
          ),
        ),
      ],
      elevation: 0,
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Color(0xFF00C896)),
          SizedBox(height: 16),
          Text(
            'Fetching latest prices…',
            style: TextStyle(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object e) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.black26),
          const SizedBox(height: 16),
          const Text('Could not load prices', style: TextStyle(color: Colors.black54, fontSize: 16)),
          const SizedBox(height: 8),
          Text(e.toString(), style: const TextStyle(color: Colors.black26, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildContent(List<PriceModel> prices, bool isCached) {
    final repo = ref.read(priceRepositoryProvider);
    final lastUpdated = repo.getLastUpdatedLabel();

    // Group prices by category (take the first match per category)
    final Map<String, PriceModel> byCategory = {};
    for (final p in prices) {
      byCategory.putIfAbsent(p.materialCategory, () => p);
    }

    return Column(
      children: [
        // Status bar
        _buildStatusBar(isCached, lastUpdated),
        // Price cards
        Expanded(
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: _categoryConfig.length,
            itemBuilder: (context, i) {
              final cat = _categoryConfig.keys.elementAt(i);
              final price = byCategory[cat];
              final meta = _categoryConfig[cat]!;
              return _buildPriceCard(cat, meta, price);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBar(bool isCached, String lastUpdated) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isCached
          ? const Color(0xFF7C3A00)
          : const Color(0xFF00381F),
      child: Row(
        children: [
          Icon(
            isCached ? Icons.wifi_off : Icons.cloud_done,
            size: 14,
            color: isCached ? const Color(0xFFFFAA00) : const Color(0xFF00C896),
          ),
          const SizedBox(width: 6),
          Text(
            isCached
                ? 'Offline — showing cached data · $lastUpdated'
                : 'Live data · Updated $lastUpdated',
            style: TextStyle(
              color: isCached ? const Color(0xFFFFAA00) : const Color(0xFF00C896),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceCard(String category, _CatMeta meta, PriceModel? price) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            meta.color.withValues(alpha: 0.15),
            const Color(0xFFFFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: meta.color.withValues(alpha: 0.35), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon circle
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: meta.color.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(meta.icon, color: meta.color, size: 24),
            ),
            const SizedBox(width: 14),
            // Category name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    meta.label,
                    style: const TextStyle(color: Colors.black38, fontSize: 12),
                  ),
                ],
              ),
            ),
            // Price column
            if (price != null) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _TrendArrow(category: category, currentPrice: price.buyingPrice),
                      const SizedBox(width: 4),
                      Text(
                        '₹${price.buyingPrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: meta.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '₹${price.marketPriceLow.toStringAsFixed(0)}–${price.marketPriceHigh.toStringAsFixed(0)} / ${price.unit}',
                    style: const TextStyle(color: Colors.black38, fontSize: 11),
                  ),
                ],
              ),
            ] else ...[
              const Text(
                'N/A',
                style: TextStyle(color: Colors.black26, fontSize: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Trend Arrow Widget ───────────────────────────────────────────────────────

class _TrendArrow extends ConsumerWidget {
  final String category;
  final double currentPrice;
  const _TrendArrow({required this.category, required this.currentPrice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(priceHistoryProvider(category));
    return historyAsync.when(
      loading: () => const SizedBox(width: 16),
      error: (_, __) => const SizedBox(width: 16),
      data: (history) {
        if (history.isEmpty) return const SizedBox(width: 16);
        // Find yesterday's price (most recent in history)
        final sorted = [...history]
          ..sort((a, b) => b.dateRecorded.compareTo(a.dateRecorded));
        final yesterdayPrice = sorted.first.buyingPrice;
        final delta = currentPrice - yesterdayPrice;

        if (delta > 0.5) {
          return const Icon(Icons.arrow_upward, color: Color(0xFF00C896), size: 16);
        } else if (delta < -0.5) {
          return const Icon(Icons.arrow_downward, color: Color(0xFFFF4D6D), size: 16);
        } else {
          return const Icon(Icons.remove, color: Colors.black38, size: 16);
        }
      },
    );
  }
}
