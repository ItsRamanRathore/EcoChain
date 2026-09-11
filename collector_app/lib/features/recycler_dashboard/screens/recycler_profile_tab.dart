import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

class RecyclerProfileTab extends ConsumerStatefulWidget {
  const RecyclerProfileTab({super.key});

  @override
  ConsumerState<RecyclerProfileTab> createState() => _RecyclerProfileTabState();
}

class _RecyclerProfileTabState extends ConsumerState<RecyclerProfileTab> {
  final _currentPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();
  bool _changingPass = false;
  bool _saving = false;

  @override
  void dispose() {
    _currentPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_newPassController.text != _confirmPassController.text) {
      _showSnack('New passwords do not match', Colors.orange);
      return;
    }
    setState(() => _saving = true);
    try {
      await DioClient.instance.patch('/recyclers/change-password', data: {
        'current_password': _currentPassController.text,
        'new_password': _newPassController.text,
      });
      _showSnack('Password changed successfully!', const Color(0xFF00C896));
      _currentPassController.clear();
      _newPassController.clear();
      _confirmPassController.clear();
      setState(() => _changingPass = false);
    } catch (e) {
      _showSnack('Error: ${e.toString()}', const Color(0xFFFF4D6D));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(_recyclerProfileForProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFAA00))),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Avatar + name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFFAA00).withValues(alpha: 0.15),
                      ),
                      child: const Icon(Icons.factory, color: Color(0xFFFFAA00), size: 40),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      profile['name'] ?? '',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          profile['approval_status'] == 'approved' ? Icons.verified : Icons.pending,
                          color: profile['approval_status'] == 'approved' ? const Color(0xFF00C896) : Colors.orange,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (profile['approval_status'] ?? 'pending').toUpperCase(),
                          style: TextStyle(
                            color: profile['approval_status'] == 'approved' ? const Color(0xFF00C896) : Colors.orange,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Info card
              _card(children: [
                _row(Icons.email_outlined, 'Email', profile['contact_email'] ?? profile['email'] ?? '-'),
                _row(Icons.location_on_outlined, 'Address', profile['facility_address'] ?? '-'),
                _row(Icons.verified_outlined, 'Auth Number', profile['auth_number'] ?? '-'),
                _row(Icons.local_shipping_outlined, 'Pickup', profile['pickup_available'] == true ? 'Available' : 'Not available'),
                _row(Icons.radar, 'Service Radius', '${profile['service_radius_km'] ?? 0} km'),
              ]),
              const SizedBox(height: 16),

              // Materials
              _card(children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text('Materials Accepted', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black54)),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ((profile['materials_accepted'] ?? []) as List)
                      .map((m) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFAA00).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(m.toString(), style: const TextStyle(color: Color(0xFFFF8800), fontWeight: FontWeight.bold, fontSize: 12)),
                          ))
                      .toList(),
                ),
              ]),
              const SizedBox(height: 16),

              // Change password
              GestureDetector(
                onTap: () => setState(() => _changingPass = !_changingPass),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.lock_outline, color: Colors.black38),
                      const SizedBox(width: 12),
                      const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                      const Spacer(),
                      Icon(_changingPass ? Icons.expand_less : Icons.expand_more, color: Colors.black38),
                    ],
                  ),
                ),
              ),
              if (_changingPass) ...[
                const SizedBox(height: 12),
                _passField(_currentPassController, 'Current Password'),
                const SizedBox(height: 10),
                _passField(_newPassController, 'New Password'),
                const SizedBox(height: 10),
                _passField(_confirmPassController, 'Confirm New Password'),
                const SizedBox(height: 12),
                if (_saving)
                  const Center(child: CircularProgressIndicator(color: Color(0xFFFFAA00)))
                else
                  ElevatedButton(
                    onPressed: _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFAA00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Update Password'),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.black38, size: 18),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const Spacer(),
          Flexible(child: Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _passField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

final _recyclerProfileForProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await DioClient.instance.get('/recyclers/me');
  return response.data as Map<String, dynamic>;
});
