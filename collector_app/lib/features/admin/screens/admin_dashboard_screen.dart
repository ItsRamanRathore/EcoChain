import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

final adminMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final response = await DioClient.instance.get('/admin/metrics');
  return response.data as Map<String, dynamic>;
});

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(adminMetricsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).logout(),
            icon: const Icon(Icons.logout, color: Colors.black54),
          ),
        ],
      ),
      body: metricsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4D9FFF))),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (metrics) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminMetricsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildMetricCard('Total Transactions', metrics['total_transactions'].toString(), Icons.receipt_long, Colors.blue),
                const SizedBox(height: 16),
                _buildMetricCard('Active Recyclers', metrics['active_recyclers'].toString(), Icons.factory, Colors.orange),
                const SizedBox(height: 16),
                _buildMetricCard('Registered Collectors', metrics['collector_count'].toString(), Icons.people, Colors.green),
                const SizedBox(height: 16),
                _buildMetricCard('Weight Processed (kg)', metrics['total_weight_processed'].toString(), Icons.monitor_weight, Colors.purple),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: TextStyle(color: color.shade700, fontSize: 28, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
