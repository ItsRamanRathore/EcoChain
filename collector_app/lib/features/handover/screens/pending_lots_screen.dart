import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/local_storage/hive_setup.dart';
import '../../../models/local/lot_local.dart';

class PendingLotsScreen extends ConsumerWidget {
  const PendingLotsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        title: const Text('Pending Handover', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box(HiveBoxes.pendingLots).listenable(),
        builder: (context, Box box, _) {
          final eligibleLots = box.values.map((lotData) {
            if (lotData is LotLocal) return lotData;
            if (lotData is Map) {
              return LotLocal(
                id: lotData['id'] ?? '',
                materialCategory: lotData['materialCategory'] ?? '',
                approximateWeight: lotData['approximateWeight'] ?? 0.0,
                imagePath: lotData['imagePath'] ?? '',
                timestamp: lotData['timestamp'] as DateTime? ?? DateTime.now(),
                isSynced: lotData['isSynced'] ?? false,
                serverId: lotData['serverId'],
                handoverCompleted: lotData['handoverCompleted'],
              );
            }
            return null;
          }).where((lot) => lot != null && !(lot.handoverCompleted ?? false))
          .cast<LotLocal>().toList();

          if (eligibleLots.isEmpty) {
            return const Center(
              child: Text(
                'No lots ready for handover.\n(Ensure they are synced first)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: eligibleLots.length,
            itemBuilder: (_, i) {
              final lot = eligibleLots[i];
              return _LotHandoverCard(lot: lot);
            },
          );
        },
      ),
    );
  }
}

class _LotHandoverCard extends StatelessWidget {
  final LotLocal lot;
  const _LotHandoverCard({required this.lot});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFFFFFFFF),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.inventory_2, color: Color(0xFF00C896), size: 40),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lot.materialCategory,
                        style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Weight: ${lot.approximateWeight} kg',
                        style: const TextStyle(color: Colors.black87, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => context.go('/collector/handover/confirm', extra: lot),
                child: const Text('Initiate Handover', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
