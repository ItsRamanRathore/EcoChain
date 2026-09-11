import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/auth_provider.dart';

class CollectorSignupScreen extends ConsumerStatefulWidget {
  const CollectorSignupScreen({super.key});

  @override
  ConsumerState<CollectorSignupScreen> createState() => _CollectorSignupScreenState();
}

class _CollectorSignupScreenState extends ConsumerState<CollectorSignupScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _districtController = TextEditingController();
  final _stateController = TextEditingController();

  String _selectedLanguage = 'English';
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  bool _obscurePin = true;

  final List<String> _languages = ['English', 'Hindi', 'Marathi'];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _districtController.dispose();
    _stateController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('Location services are disabled.');

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) throw Exception('Location permission denied.');
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied.');
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
          SnackBar(content: Text('Location error: $e'), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final pin = _pinController.text.trim();
    final confirmPin = _confirmPinController.text.trim();
    final district = _districtController.text.trim();
    final state = _stateController.text.trim();

    if (name.isEmpty || phone.isEmpty || pin.isEmpty || district.isEmpty || state.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }
    if (pin.length != 4) {
      _showError('PIN must be exactly 4 digits.');
      return;
    }
    if (pin != confirmPin) {
      _showError('PINs do not match.');
      return;
    }

    final success = await ref.read(authProvider.notifier).registerCollector({
      'display_name': name,
      'phone_number': phone,
      'pin': pin,
      'preferred_language': _selectedLanguage,
      'operating_district': district,
      'operating_state': state,
      'latitude': _latitude,
      'longitude': _longitude,
    });

    if (success && mounted) {
      context.go('/collector/home');
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

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: const Text('Create Collector Account', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16)),
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
                  colors: [Color(0xFF00C896), Color(0xFF00A67C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                children: [
                  Icon(Icons.person_add, color: Colors.white, size: 32),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Join e-Mulya', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
                        Text('Sign up as a collector — no approval needed!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            _buildField(_nameController, 'Full Name', Icons.person_outline, hint: 'Your display name'),
            const SizedBox(height: 16),
            _buildField(_phoneController, 'Phone Number', Icons.phone_android, hint: '10-digit number', keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField(_pinController, '4-Digit PIN', Icons.lock_outline, obscure: _obscurePin, maxLength: 4, keyboardType: TextInputType.number,
              suffix: IconButton(
                icon: Icon(_obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: Colors.black38, size: 20),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
            ),
            const SizedBox(height: 16),
            _buildField(_confirmPinController, 'Confirm PIN', Icons.lock_clock_outlined, obscure: true, maxLength: 4, keyboardType: TextInputType.number),
            const SizedBox(height: 16),

            // Language dropdown
            DropdownButtonFormField<String>(
              value: _selectedLanguage,
              decoration: InputDecoration(
                labelText: 'Preferred Language',
                prefixIcon: const Icon(Icons.language, color: Colors.black38),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.white,
              ),
              items: _languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
              onChanged: (v) => setState(() => _selectedLanguage = v!),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildField(_districtController, 'District', Icons.location_city_outlined, hint: 'e.g. Mumbai')),
                const SizedBox(width: 12),
                Expanded(child: _buildField(_stateController, 'State', Icons.map_outlined, hint: 'e.g. Maharashtra')),
              ],
            ),
            const SizedBox(height: 16),

            // GPS Location
            GestureDetector(
              onTap: _locating ? null : _detectLocation,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _latitude != null ? const Color(0xFF00C896) : Colors.black12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _latitude != null ? Icons.location_on : Icons.my_location,
                      color: _latitude != null ? const Color(0xFF00C896) : Colors.black38,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _latitude != null
                            ? 'Location captured (${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)})'
                            : 'Tap to detect your location',
                        style: TextStyle(
                          color: _latitude != null ? const Color(0xFF00C896) : Colors.black54,
                          fontWeight: _latitude != null ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (_locating) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00C896))),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            if (authState.isLoading)
              const Center(child: CircularProgressIndicator(color: Color(0xFF00C896)))
            else
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C896),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Create Account & Login', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

            if (authState.error != null) ...[
              const SizedBox(height: 12),
              Text(authState.error!, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFFFF4D6D))),
            ],

            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an account? ', style: TextStyle(color: Colors.black54)),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: const Text('Login', style: TextStyle(color: Color(0xFF00C896), fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    String? hint,
    bool obscure = false,
    int? maxLength,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.black38),
        suffixIcon: suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
