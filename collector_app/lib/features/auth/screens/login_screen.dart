import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  String _selectedRole = 'collector';

  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    _pinController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    ref.listen(authProvider, (previous, next) {
      if (next.isAuthenticated) {
        if (next.role == 'recycler') {
          context.go('/recycler/home');
        } else if (next.role == 'admin') {
          context.go('/admin/home');
        } else {
          context.go('/collector/home');
        }
      } else if (next.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.error!), backgroundColor: Colors.red),
        );
      }
    });

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.eco, size: 80, color: Color(0xFF00C896)),
              const SizedBox(height: 16),
              const Text(
                'EcoChain',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: Colors.black87,
                  letterSpacing: -1,
                ),
              ),
              const SizedBox(height: 48),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'collector',
                    icon: Icon(Icons.smartphone),
                    label: Text('Collector', overflow: TextOverflow.ellipsis),
                  ),
                  ButtonSegment(
                    value: 'recycler',
                    icon: Icon(Icons.factory),
                    label: Text('Recycler', overflow: TextOverflow.ellipsis),
                  ),
                  ButtonSegment(
                    value: 'admin',
                    icon: Icon(Icons.admin_panel_settings),
                    label: Text('Admin', overflow: TextOverflow.ellipsis),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedRole = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.resolveWith<Color>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF00C896).withValues(alpha: 0.2);
                      }
                      return Colors.white;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),
              if (_selectedRole == 'collector')
                _buildCollectorForm(authState)
              else
                _buildMockForm(_selectedRole, authState),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectorForm(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone Number (फ़ोन नंबर)',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          decoration: const InputDecoration(
            labelText: '4-Digit PIN (पिन)',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        if (authState.isLoading)
          const Center(child: CircularProgressIndicator(color: Color(0xFF00C896)))
        else
          ElevatedButton(
            onPressed: () {
              if (_phoneController.text.isNotEmpty && _pinController.text.length == 4) {
                ref.read(authProvider.notifier).loginCollector(
                      _phoneController.text,
                      _pinController.text,
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C896),
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('लॉगिन करें', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  Widget _buildMockForm(String role, AuthState authState) {
    final color = role == 'recycler' ? const Color(0xFFFFAA00) : const Color(0xFF4D9FFF);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email Address',
            prefixIcon: Icon(Icons.email),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
            border: OutlineInputBorder(),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        if (authState.isLoading)
          Center(child: CircularProgressIndicator(color: color))
        else
          ElevatedButton(
            onPressed: () {
              // Ignore actual email/pass input for now, just mock login for demo
              ref.read(authProvider.notifier).loginMock(role);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Login as ${role[0].toUpperCase()}${role.substring(1)}', 
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        const SizedBox(height: 16),
        const Text('Note: Any email/password will work for this demo mode.', 
          textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}

