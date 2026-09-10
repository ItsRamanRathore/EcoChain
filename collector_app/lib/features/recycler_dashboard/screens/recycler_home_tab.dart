import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/recycler_dashboard_provider.dart';

class RecyclerHomeTab extends ConsumerWidget {
  const RecyclerHomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(recyclerDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Recycler Portal', style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(recyclerDashboardProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFAA00))),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (data) {
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(recyclerDashboardProvider),
            color: const Color(0xFFFFAA00),
            backgroundColor: const Color(0xFFFFFFFF),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildMetricsHeader(data),
                const SizedBox(height: 32),
                const Text(
                  'Pending Handovers',
                  style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (data.pendingTransactions.isEmpty)
                  const Text('No pending handovers.', style: TextStyle(color: Colors.black54))
                else
                  ...data.pendingTransactions.map((tx) => _buildTransactionCard(context, tx, isPending: true)),
                
                const SizedBox(height: 32),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (data.recentTransactions.isEmpty)
                  const Text('No recent transactions.', style: TextStyle(color: Colors.black54))
                else
                  ...data.recentTransactions.map((tx) => _buildTransactionCard(context, tx, isPending: false)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsHeader(RecyclerDashboardData data) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFFFFAA00).withValues(alpha: 0.15), const Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFFFAA00).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.monitor_weight, color: Color(0xFFFFAA00)),
                const SizedBox(height: 12),
                Text(
                  '${data.totalWeightProcessed.toStringAsFixed(1)} kg',
                  style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text('Processed', style: TextStyle(color: Colors.black87, fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF4D9FFF).withValues(alpha: 0.15), const Color(0xFFFFFFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF4D9FFF).withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.receipt_long, color: Color(0xFF4D9FFF)),
                const SizedBox(height: 12),
                Text(
                  '${data.totalTransactions}',
                  style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const Text('Transactions', style: TextStyle(color: Colors.black87, fontSize: 12)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, dynamic tx, {required bool isPending}) {
    final dateStr = isPending ? tx['created_at'] : tx['handover_datetime'];
    final date = dateStr != null ? DateTime.parse(dateStr).toLocal() : DateTime.now();
    final formatter = DateFormat('MMM d, yyyy • h:mm a');

    final lotId = tx['lot_id'] ?? 'Unknown Lot';
    final shortLotId = lotId.length > 8 ? lotId.substring(0, 8) : lotId;
    
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            title: Text('Lot Details: $shortLotId', style: const TextStyle(color: Colors.black87)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category: ${tx['material_category'] ?? "Unknown"}', style: const TextStyle(color: Colors.black87)),
                Text('Weight: ${tx['quantity_weight']} kg', style: const TextStyle(color: Colors.black87)),
                Text('Price: ₹${tx['final_price'] ?? 0}', style: const TextStyle(color: Colors.black87)),
                Text('Date: ${formatter.format(date)}', style: const TextStyle(color: Colors.black87)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))
            ],
          )
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isPending ? const Color(0xFFFFAA00).withValues(alpha: 0.1) : const Color(0xFF00C896).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPending ? Icons.pending_actions : Icons.check_circle,
              color: isPending ? const Color(0xFFFFAA00) : const Color(0xFF00C896),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lot $shortLotId',
                  style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  formatter.format(date),
                  style: const TextStyle(color: Colors.black87, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${tx['quantity_weight']} kg',
                style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                '₹${tx['final_price'] ?? 0}',
                style: const TextStyle(color: Color(0xFF00C896), fontWeight: FontWeight.w600, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}
