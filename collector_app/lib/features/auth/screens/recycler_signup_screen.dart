import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';

const _allCategories = ['PCB', 'Cable', 'Battery', 'LCD', 'CRT', 'Motor', 'Plastic', 'Mixed'];

class RecyclerSignupScreen extends ConsumerStatefulWidget {
  const RecyclerSignupScreen({super.key});

  @override
  ConsumerState<RecyclerSignupScreen> createState() => _RecyclerSignupScreenState();
}

class _RecyclerSignupScreenState extends ConsumerState<RecyclerSignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _addressController = TextEditingController();
  final _authNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  final _radiusController = TextEditingController(text: '20');

  Set<String> _selectedMaterials = {};
  bool _pickupAvailable = false;
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _obscurePass = true;
  bool _submitted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _addressController.dispose();
    _authNumberController.dispose();
    _phoneController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permission denied.');
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
            timeLimit: Duration(seconds: 5),
          ),
        );
      } catch (e) {
        pos = await Geolocator.getLastKnownPosition();
        if (pos == null) {
          // If all else fails (like on an emulator), use a mock location.
          setState(() {
            _latitude = 19.0760;
            _longitude = 72.8777;
          });
          throw Exception('Timeout fetching location. Using mock location for testing.');
        }
      }
      
      setState(() {
        _latitude = pos!.latitude;
        _longitude = pos.longitude;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location: $e'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _addressController.text.trim().isEmpty) {
      _showError('Please fill in all required fields.');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Passwords do not match.');
      return;
    }
    if (_selectedMaterials.isEmpty) {
      _showError('Please select at least one material category.');
      return;
    }
    if (_latitude == null || _longitude == null) {
      _showError('Please detect your facility location.');
      return;
    }

    final success = await ref.read(authProvider.notifier).registerRecycler({
      'name': _nameController.text.trim(),
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'facility_address': _addressController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'materials_accepted': _selectedMaterials.toList(),
      'auth_number': _authNumberController.text.trim(),
      'pickup_available': _pickupAvailable,
      'service_radius_km': int.tryParse(_radiusController.text) ?? 20,
      'contact_phone': _phoneController.text.trim(),
    });

    if (success && mounted) {
      setState(() => _submitted = true);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFFF4D6D)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    if (_submitted) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FFFE),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFAA00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hourglass_top, color: Colors.white, size: 48),
                  ),
                  const SizedBox(height: 24),
                  const Text('Application Submitted!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87)),
                  const SizedBox(height: 12),
                  const Text(
                    'Your recycling facility registration is under review. The admin will verify your details and approve your account.\n\nYou can login once approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54, height: 1.6),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFAA00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Back to Login', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text('Register Recycling Facility', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFAA00), Color(0xFFFF8800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.factory, color: Colors.white, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Facility Registration', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                        Text('Subject to admin verification & approval', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            _sectionLabel('Facility Details'),
            _buildField(_nameController, 'Facility / Company Name *', Icons.business),
            const SizedBox(height: 12),
            _buildField(_addressController, 'Full Address *', Icons.location_on_outlined, maxLines: 2),
            const SizedBox(height: 12),
            _buildField(_authNumberController, 'Authorization Number', Icons.verified_outlined, hint: 'e.g. MH-CPCB-2024-XXXX'),
            const SizedBox(height: 12),
            _buildField(_phoneController, 'Contact Phone', Icons.phone, keyboardType: TextInputType.phone),
            const SizedBox(height: 20),

            _sectionLabel('Account Credentials'),
            _buildField(_emailController, 'Email Address *', Icons.email_outlined, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _buildPasswordRow(),
            const SizedBox(height: 20),

            _sectionLabel('Location'),
            GestureDetector(
              onTap: _locating ? null : _detectLocation,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _latitude != null ? const Color(0xFFFFAA00) : Colors.black12),
                ),
                child: Row(
                  children: [
                    Icon(
                      _latitude != null ? Icons.location_on : Icons.my_location,
                      color: _latitude != null ? const Color(0xFFFFAA00) : Colors.black38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _latitude != null
                            ? 'Captured (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                            : 'Tap to detect facility location *',
                        style: TextStyle(
                          color: _latitude != null ? const Color(0xFFFFAA00) : Colors.black54,
                          fontWeight: _latitude != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_locating)
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFAA00))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Materials Accepted *'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _allCategories.map((cat) {
                final selected = _selectedMaterials.contains(cat);
                return FilterChip(
                  label: Text(cat),
                  selected: selected,
                  onSelected: (v) => setState(() {
                    if (v) _selectedMaterials.add(cat);
                    else _selectedMaterials.remove(cat);
                  }),
                  selectedColor: const Color(0xFFFFAA00).withValues(alpha: 0.2),
                  checkmarkColor: const Color(0xFFFFAA00),
                  labelStyle: TextStyle(
                    color: selected ? const Color(0xFFFF8800) : Colors.black54,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            _sectionLabel('Service Options'),
            Row(
              children: [
                Switch(
                  value: _pickupAvailable,
                  onChanged: (v) => setState(() => _pickupAvailable = v),
                  activeColor: const Color(0xFFFFAA00),
                ),
                const SizedBox(width: 8),
                const Text('Pickup Available', style: TextStyle(color: Colors.black87)),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildField(_radiusController, 'Radius (km)', Icons.radar, keyboardType: TextInputType.number),
                ),
              ],
            ),
            const SizedBox(height: 32),

            if (authState.isLoading)
              const Center(child: CircularProgressIndicator(color: Color(0xFFFFAA00)))
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFAA00),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Submit for Approval', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

            if (authState.error != null) ...[
              const SizedBox(height: 12),
              Text(authState.error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF4D6D))),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black54, letterSpacing: 0.5)),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black38),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _buildPasswordRow() {
    return Column(
      children: [
        TextField(
          controller: _passwordController,
          obscureText: _obscurePass,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'Password *',
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.black38),
            suffixIcon: IconButton(
              icon: Icon(_obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.black38),
              onPressed: () => setState(() => _obscurePass = !_obscurePass),
            ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPasswordController,
          obscureText: true,
          style: const TextStyle(color: Colors.black87),
          decoration: InputDecoration(
            labelText: 'Confirm Password *',
            prefixIcon: const Icon(Icons.lock_clock_outlined, color: Colors.black38),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
