import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final adminTransactionsProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await DioClient.instance.get('/admin/transactions?limit=50');
  return response.data as List<dynamic>;
});

class AdminTransactionsScreen extends ConsumerWidget {
  const AdminTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(adminTransactionsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Recent Transactions', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4D9FFF))),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(child: Text('No transactions found.'));
          }
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminTransactionsProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return Card(
                  color: Colors.black87,
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF4D9FFF),
                      child: Icon(Icons.receipt, color: Colors.black87),
                    ),
                    title: Text('Tx: ${tx['transaction_id'].toString().substring(0, 8)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Weight: ${tx['quantity_weight']} kg | Amount: ₹${tx['final_price']}\nDate: ${tx['handover_datetime'].toString().split('T')[0]}'),
                    trailing: Text(tx['transaction_status'], style: TextStyle(
                      color: tx['transaction_status'] == 'COMPLETED' ? Colors.green : Colors.orange,
                      fontWeight: FontWeight.bold,
                    )),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
