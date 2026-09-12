import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/api/recycler_model.dart';
import '../providers/recycler_provider.dart';
import '../../../l10n/app_localizations.dart';

// ─── Category config (shared with Price Board) ───────────────────────────────

const _categories = [
  ('PCB',     Icons.developer_board,       Color(0xFF00C896)),
  ('Cable',   Icons.cable,                  Color(0xFFFFAA00)),
  ('Battery', Icons.battery_charging_full,  Color(0xFFFF4D6D)),
  ('LCD',     Icons.monitor,               Color(0xFF4D9FFF)),
  ('CRT',     Icons.tv,                    Color(0xFF9E9E9E)),
  ('Motor',   Icons.settings,              Color(0xFFBF8052)),
  ('Plastic', Icons.recycling,             Color(0xFFAB47BC)),
  ('Mixed',   Icons.category,              Color(0xFF26A69A)),
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class RecyclerMatchScreen extends ConsumerStatefulWidget {
  const RecyclerMatchScreen({super.key});

  @override
  ConsumerState<RecyclerMatchScreen> createState() => _RecyclerMatchScreenState();
}

class _RecyclerMatchScreenState extends ConsumerState<RecyclerMatchScreen> {
  String _selectedCategory = 'PCB';

  @override
  Widget build(BuildContext context) {
    final locationAsync = ref.watch(locationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        title: Text(
          AppLocalizations.of(context)!.recyclersList,
          style: const TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
        ),
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category chip selector
          _buildCategoryChips(),
          // GPS + recycler list
          Expanded(
            child: locationAsync.when(
              loading: () => const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00C896)),
                    SizedBox(height: 16),
                    Text('Getting your location…',
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              ),
              error: (e, _) => _buildLocationError(e),
              data: (position) => _buildRecyclerList(position.latitude, position.longitude),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return Container(
      color: const Color(0xFFFFFFFF),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              'Select Material Category',
              style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map(((String cat, IconData icon, Color color) record) {
                final isSelected = record.$1 == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCategory = record.$1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? record.$3 : record.$3.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: record.$3,
                          width: isSelected ? 0 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(record.$2, size: 16,
                              color: isSelected ? Colors.white : record.$3),
                          const SizedBox(width: 6),
                          Text(
                            record.$1,
                            style: TextStyle(
                              color: isSelected ? Colors.white : record.$3,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationError(Object e) {
    final isPermDenied = e.toString().contains('permanently denied');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.location_off, size: 64, color: Colors.black26),
            const SizedBox(height: 16),
            Text(
              isPermDenied
                  ? 'Location permission denied'
                  : 'Could not get your location',
              style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isPermDenied
                  ? 'Please enable location in Settings → App → Permissions'
                  : e.toString(),
              style: const TextStyle(color: Colors.black38, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            if (isPermDenied) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(locationProvider),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  foregroundColor: Colors.black,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRecyclerList(double lat, double lng) {
    final params = (lat: lat, lng: lng, category: _selectedCategory);
    final recyclersAsync = ref.watch(matchedRecyclersProvider(params));

    return recyclersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFF00C896)),
      ),
      error: (e, _) => Center(
        child: Text(e.toString(), style: const TextStyle(color: Colors.black54)),
      ),
      data: (recyclers) {
        if (recyclers.isEmpty) return _buildEmpty();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${recyclers.length} certified recycler${recyclers.length == 1 ? '' : 's'} found',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ),
            ...recyclers.asMap().entries.map(
              (e) => _buildRecyclerCard(e.key + 1, e.value, _selectedCategory),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: Colors.black26),
          const SizedBox(height: 16),
          const Text(
            'No recyclers found nearby',
            style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'No certified recycler accepts $_selectedCategory within 50 km',
            style: const TextStyle(color: Colors.black38, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecyclerCard(int rank, RecyclerModel r, String category) {
    final rate = r.rateFor(category);
    final score = r.matchScore ?? 0.0;
    final scorePercent = (score * 100).toInt();

    // Rank medal colors
    final medalColor = switch (rank) {
      1 => const Color(0xFFFFD700),
      2 => const Color(0xFFC0C0C0),
      _ => const Color(0xFFCD7F32),
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: rank == 1
              ? const Color(0xFFFFD700).withValues(alpha: 0.4)
              : Colors.white12,
          width: rank == 1 ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                // Rank badge
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: medalColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: medalColor, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      '#$rank',
                      style: TextStyle(
                        color: medalColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name + verified badge
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              r.name,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (r.verifiedByAdmin) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.verified, size: 15, color: Color(0xFF4D9FFF)),
                          ],
                        ],
                      ),
                      Text(
                        r.facilityAddress,
                        style: const TextStyle(color: Colors.black38, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Stats row
            Row(
              children: [
                _statChip(
                  icon: Icons.straighten,
                  label: '${r.distanceKm?.toStringAsFixed(1) ?? '—'} km',
                  color: Colors.black87,
                ),
                const SizedBox(width: 8),
                if (rate != null)
                  _statChip(
                    icon: Icons.currency_rupee,
                    label: '${rate.toStringAsFixed(0)} / kg',
                    color: const Color(0xFF00C896),
                  ),
                const SizedBox(width: 8),
                if (r.pickupAvailable)
                  _statChip(
                    icon: Icons.local_shipping,
                    label: 'Pickup',
                    color: const Color(0xFFFFAA00),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Match score bar
            Row(
              children: [
                const Text(
                  'Match Score',
                  style: TextStyle(color: Colors.black38, fontSize: 11),
                ),
                const Spacer(),
                Text(
                  '$scorePercent%',
                  style: TextStyle(
                    color: _scoreColor(score),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: score,
                backgroundColor: Colors.white12,
                valueColor: AlwaysStoppedAnimation<Color>(_scoreColor(score)),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 0.7) return const Color(0xFF00C896);
    if (score >= 0.45) return const Color(0xFFFFAA00);
    return const Color(0xFFFF4D6D);
  }
}
