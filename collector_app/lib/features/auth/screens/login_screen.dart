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
  bool _obscurePassword = true;

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
          SnackBar(
            content: Text(next.error!),
            backgroundColor: const Color(0xFFFF4D6D),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo & title
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C896).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.recycling, size: 56, color: Color(0xFF00C896)),
              ),
              const SizedBox(height: 16),
              const Text(
                'e-Mulya',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF00C896),
                  letterSpacing: -1.5,
                ),
              ),
              const Text(
                'E-Waste Management Platform',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black38, fontSize: 13, letterSpacing: 0.3),
              ),
              const SizedBox(height: 40),

              // Role selector
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.black12),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: ['collector', 'recycler', 'admin'].map((role) {
                    final isSelected = _selectedRole == role;
                    final color = role == 'collector'
                        ? const Color(0xFF00C896)
                        : role == 'recycler'
                            ? const Color(0xFFFFAA00)
                            : const Color(0xFF4D9FFF);
                    final label = role[0].toUpperCase() + role.substring(1);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _selectedRole = role;
                          _emailController.clear();
                          _passwordController.clear();
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: isSelected ? color : Colors.black38,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 32),

              if (_selectedRole == 'collector') _buildCollectorForm(authState)
              else if (_selectedRole == 'recycler') _buildRecyclerForm(authState)
              else _buildAdminForm(authState),
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
        _buildTextField(
          controller: _phoneController,
          label: 'Phone Number',
          hint: '10-digit mobile number',
          icon: Icons.phone_android,
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _pinController,
          label: '4-Digit PIN',
          hint: '••••',
          icon: Icons.lock_outline,
          obscureText: true,
          maxLength: 4,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 24),
        _buildLoginButton(
          label: 'Login',
          color: const Color(0xFF00C896),
          isLoading: authState.isLoading,
          onPressed: () {
            if (_phoneController.text.length >= 10 && _pinController.text.length == 4) {
              ref.read(authProvider.notifier).loginCollector(
                    _phoneController.text.trim(),
                    _pinController.text.trim(),
                  );
            }
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("New collector? ", style: TextStyle(color: Colors.black54)),
            GestureDetector(
              onTap: () => context.push('/signup/collector'),
              child: const Text(
                'Sign Up',
                style: TextStyle(
                  color: Color(0xFF00C896),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecyclerForm(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Email Address',
          hint: 'your@email.com',
          icon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: _passwordController,
          label: 'Password',
        ),
        const SizedBox(height: 24),
        _buildLoginButton(
          label: 'Login as Recycler',
          color: const Color(0xFFFFAA00),
          isLoading: authState.isLoading,
          onPressed: () {
            if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
              ref.read(authProvider.notifier).loginRecycler(
                    _emailController.text.trim(),
                    _passwordController.text,
                  );
            }
          },
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Register facility? ", style: TextStyle(color: Colors.black54)),
            GestureDetector(
              onTap: () => context.push('/signup/recycler'),
              child: const Text(
                'Apply Here',
                style: TextStyle(
                  color: Color(0xFFFFAA00),
                  fontWeight: FontWeight.bold,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminForm(AuthState authState) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTextField(
          controller: _emailController,
          label: 'Admin Email',
          hint: 'admin@gmail.com',
          icon: Icons.admin_panel_settings_outlined,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildPasswordField(
          controller: _passwordController,
          label: 'Password',
        ),
        const SizedBox(height: 24),
        _buildLoginButton(
          label: 'Login as Admin',
          color: const Color(0xFF4D9FFF),
          isLoading: authState.isLoading,
          onPressed: () {
            if (_emailController.text.isNotEmpty && _passwordController.text.isNotEmpty) {
              ref.read(authProvider.notifier).loginAdmin(
                    _emailController.text.trim(),
                    _passwordController.text,
                  );
            }
          },
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int? maxLength,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
  }) {
    return TextField(
      controller: controller,
      obscureText: _obscurePassword,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.lock_outline, color: Colors.black38),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            color: Colors.black38,
          ),
          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildLoginButton({
    required String label,
    required Color color,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator(color: color));
    }
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        elevation: 0,
      ),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }
}
