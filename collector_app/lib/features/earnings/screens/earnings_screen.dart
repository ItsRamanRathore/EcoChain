import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/earnings_provider.dart';

class EarningsScreen extends ConsumerWidget {
  const EarningsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earningsAsync = ref.watch(earningsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        title: const Text('Earnings Ledger', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
      ),
      body: earningsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00C896))),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No earnings history yet.', style: TextStyle(color: Colors.black54)));
          }

          final total = transactions.fold<double>(0, (sum, t) => sum + t.finalPrice);

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                color: const Color(0xFFFFFFFF),
                child: Column(
                  children: [
                    const Text('Total Earnings', style: TextStyle(color: Colors.black54, fontSize: 16)),
                    const SizedBox(height: 8),
                    Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00C896), fontSize: 40, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    return Card(
                      color: const Color(0xFFFFFFFF),
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFF00C896),
                          child: Icon(Icons.currency_rupee, color: Colors.black),
                        ),
                        title: Text(t.materialCategory, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                        subtitle: Text('${t.quantityWeight} kg • ${t.paymentStatus}', style: const TextStyle(color: Colors.black54)),
                        trailing: Text('+₹${t.finalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00C896), fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
