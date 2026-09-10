import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final adminRecyclersProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await DioClient.instance.get('/admin/recyclers');
  return response.data as List<dynamic>;
});

class AdminRecyclersScreen extends ConsumerWidget {
  const AdminRecyclersScreen({super.key});

  Future<void> _toggleStatus(BuildContext context, WidgetRef ref, String id, String currentStatus) async {
    final newStatus = currentStatus == 'Active' ? 'Suspended' : 'Active';
    try {
      await DioClient.instance.patch(
        '/admin/recyclers/$id/status',
        data: {'auth_status': newStatus},
      );
      ref.invalidate(adminRecyclersProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e')));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recyclersAsync = ref.watch(adminRecyclersProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Recycler Management', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: recyclersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4D9FFF))),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (recyclers) {
          return RefreshIndicator(
            onRefresh: () => ref.refresh(adminRecyclersProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: recyclers.length,
              itemBuilder: (context, index) {
                final recycler = recyclers[index];
                final isActive = recycler['auth_status'] == 'Active';
                
                return Card(
                  color: Colors.black87,
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(recycler['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('ID: ${recycler['recycler_id']}\nDistrict: ${recycler['district']}'),
                    trailing: Switch(
                      value: isActive,
                      activeColor: Colors.green,
                      onChanged: (val) => _toggleStatus(context, ref, recycler['recycler_id'], recycler['auth_status']),
                    ),
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
