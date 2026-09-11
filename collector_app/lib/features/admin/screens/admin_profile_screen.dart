import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';

class AdminProfileScreen extends ConsumerStatefulWidget {
  const AdminProfileScreen({super.key});

  @override
  ConsumerState<AdminProfileScreen> createState() => _AdminProfileScreenState();
}

class _AdminProfileScreenState extends ConsumerState<AdminProfileScreen> {
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
      _showSnack('Passwords do not match', Colors.orange);
      return;
    }
    if (_newPassController.text.length < 6) {
      _showSnack('New password must be at least 6 characters', Colors.orange);
      return;
    }
    setState(() => _saving = true);
    try {
      await DioClient.instance.patch('/admin/change-password', data: {
        'current_password': _currentPassController.text,
        'new_password': _newPassController.text,
      });
      _showSnack('Password changed successfully!', const Color(0xFF4D9FFF));
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
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Admin Profile', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar
            Center(
              child: Column(
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF4D9FFF).withValues(alpha: 0.15),
                    ),
                    child: const Icon(Icons.admin_panel_settings, color: Color(0xFF4D9FFF), size: 44),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    authState.displayName ?? 'System Admin',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87),
                  ),
                  const Text('Global Administrator', style: TextStyle(color: Colors.black38, fontSize: 13)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Info card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                children: [
                  _infoRow(Icons.shield_outlined, 'Role', 'System Administrator'),
                  _infoRow(Icons.app_settings_alt_outlined, 'Platform', 'e-Mulya'),
                  _infoRow(Icons.email_outlined, 'Email', 'admin@gmail.com'),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Change password section
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
                    const Icon(Icons.lock_outline, color: Color(0xFF4D9FFF)),
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
                const Center(child: CircularProgressIndicator(color: Color(0xFF4D9FFF)))
              else
                ElevatedButton(
                  onPressed: _changePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4D9FFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.black38, size: 18),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          const Spacer(),
          Text(value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
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
