import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

final adminPendingRecyclersProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await DioClient.instance.get('/admin/recyclers/pending');
  return response.data as List<dynamic>;
});

final adminApprovedRecyclersProvider = FutureProvider<List<dynamic>>((ref) async {
  final response = await DioClient.instance.get('/admin/recyclers');
  return response.data as List<dynamic>;
});

class AdminRecyclersScreen extends ConsumerStatefulWidget {
  const AdminRecyclersScreen({super.key});

  @override
  ConsumerState<AdminRecyclersScreen> createState() => _AdminRecyclersScreenState();
}

class _AdminRecyclersScreenState extends ConsumerState<AdminRecyclersScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _approveRecycler(String id) async {
    try {
      await DioClient.instance.patch('/admin/recyclers/$id/approve');
      ref.invalidate(adminPendingRecyclersProvider);
      ref.invalidate(adminApprovedRecyclersProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recycler approved'), backgroundColor: Color(0xFF00C896)));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFFF4D6D)));
    }
  }

  Future<void> _rejectRecycler(String id) async {
    try {
      await DioClient.instance.post('/admin/recyclers/$id/reject');
      ref.invalidate(adminPendingRecyclersProvider);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Recycler rejected'), backgroundColor: Colors.orange));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: const Color(0xFFFF4D6D)));
    }
  }

  Future<void> _toggleStatus(String id, String currentStatus) async {
    final newStatus = currentStatus == 'Active' ? 'Suspended' : 'Active';
    try {
      await DioClient.instance.patch(
        '/admin/recyclers/$id/status',
        data: {'auth_status': newStatus},
      );
      ref.invalidate(adminApprovedRecyclersProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update status: $e'), backgroundColor: const Color(0xFFFF4D6D)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        title: const Text('Recycler Management', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFF4D9FFF),
          unselectedLabelColor: Colors.black54,
          indicatorColor: const Color(0xFF4D9FFF),
          tabs: const [
            Tab(text: 'Pending Approval'),
            Tab(text: 'Verified Recyclers'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingTab(),
          _buildVerifiedTab(),
        ],
      ),
    );
  }

  Widget _buildPendingTab() {
    final pendingAsync = ref.watch(adminPendingRecyclersProvider);
    return pendingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4D9FFF))),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (recyclers) {
        if (recyclers.isEmpty) {
          return const Center(child: Text('No pending approvals', style: TextStyle(color: Colors.black54)));
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(adminPendingRecyclersProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recyclers.length,
            itemBuilder: (context, index) {
              final r = recyclers[index];
              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 8),
                      Text('Email: ${r['email']}\nAddress: ${r['facility_address']}'),
                      Text('Auth Number: ${r['auth_number'] ?? 'N/A'}'),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _rejectRecycler(r['recycler_id']),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF4D6D)),
                            child: const Text('Reject'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _approveRecycler(r['recycler_id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C896),
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            child: const Text('Approve'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildVerifiedTab() {
    final verifiedAsync = ref.watch(adminApprovedRecyclersProvider);
    return verifiedAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF4D9FFF))),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (recyclers) {
        if (recyclers.isEmpty) {
          return const Center(child: Text('No verified recyclers', style: TextStyle(color: Colors.black54)));
        }
        return RefreshIndicator(
          onRefresh: () => ref.refresh(adminApprovedRecyclersProvider.future),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: recyclers.length,
            itemBuilder: (context, index) {
              final r = recyclers[index];
              final isActive = r['auth_status'] == 'Active';
              return Card(
                color: Colors.white,
                elevation: 0,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  title: Text(r['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('ID: ${r['recycler_id']}\nDistrict: ${r['district'] ?? r['facility_address']}'),
                  trailing: Switch(
                    value: isActive,
                    activeColor: const Color(0xFF00C896),
                    onChanged: (val) => _toggleStatus(r['recycler_id'], r['auth_status']),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
