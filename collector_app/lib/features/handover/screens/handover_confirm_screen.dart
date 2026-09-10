import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:geolocator/geolocator.dart';
import '../../../models/local/lot_local.dart';
import '../../../models/api/recycler_model.dart';
import '../../recyclers/providers/recycler_provider.dart';

class HandoverConfirmScreen extends ConsumerStatefulWidget {
  final LotLocal lot;
  const HandoverConfirmScreen({super.key, required this.lot});

  @override
  ConsumerState<HandoverConfirmScreen> createState() => _HandoverConfirmScreenState();
}

class _HandoverConfirmScreenState extends ConsumerState<HandoverConfirmScreen> {
  late double _actualWeight;
  RecyclerModel? _selectedRecycler;
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _actualWeight = widget.lot.approximateWeight;
  }

  @override
  Widget build(BuildContext context) {
    // For simplicity, using a hardcoded default location for demo if locationProvider fails.
    // Ideally we'd await the location inside the future.
    // In our matchedRecyclersProvider it requires lat/lng.
    final locationAsync = ref.watch(locationProvider);
    final position = locationAsync.valueOrNull;
    final lat = position?.latitude ?? 19.0728;
    final lng = position?.longitude ?? 73.0183;

    final params = (lat: lat, lng: lng, category: widget.lot.materialCategory);
    final recyclersAsync = ref.watch(matchedRecyclersProvider(params));

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFFFF),
        title: const Text('Confirm Handover', style: TextStyle(color: Colors.black87)),
      ),
      body: recyclersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00C896))),
        error: (e, _) => Center(child: Text('Error loading recyclers: $e', style: const TextStyle(color: Colors.red))),
        data: (recyclers) {
          if (recyclers.isEmpty) {
            return const Center(child: Text('No recyclers accept this material nearby.', style: TextStyle(color: Colors.black87)));
          }
          _selectedRecycler ??= recyclers.first;
          final rate = _selectedRecycler!.rateFor(widget.lot.materialCategory) ?? 0;
          final finalPrice = rate * _actualWeight;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Recycler', style: TextStyle(color: Colors.black87, fontSize: 14)),
                const SizedBox(height: 8),
                DropdownButtonFormField<RecyclerModel>(
                  value: _selectedRecycler,
                  dropdownColor: const Color(0xFFFFFFFF),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFFFFFFF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  items: recyclers.map((r) {
                    final rRate = r.rateFor(widget.lot.materialCategory) ?? 0;
                    final rPrice = rRate * _actualWeight;
                    return DropdownMenuItem(
                      value: r,
                      child: Text('${r.name} (Offers ₹${rPrice.toStringAsFixed(2)})', style: const TextStyle(color: Colors.black87)),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedRecycler = val),
                ),
                const SizedBox(height: 24),
                
                const Text('Confirm Actual Weight (kg)', style: TextStyle(color: Colors.black87, fontSize: 14)),
                const SizedBox(height: 8),
                // Simple numeric input instead of full numpad for brevity
                TextFormField(
                  initialValue: _actualWeight.toString(),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFFFFFFF),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  onChanged: (val) => setState(() => _actualWeight = double.tryParse(val) ?? _actualWeight),
                ),
                
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C896).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF00C896).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Final Price', style: TextStyle(color: Colors.black87, fontSize: 16)),
                      Text('₹${finalPrice.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFF00C896), fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00C896),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _isLoadingGps ? null : () => _generateHandover(finalPrice),
                    child: _isLoadingGps
                        ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black))
                        : const Text('Confirm & Capture Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _generateHandover(double finalPrice) async {
    setState(() => _isLoadingGps = true);
    Position? position;
    try {
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
    } on TimeoutException {
      position = await Geolocator.getLastKnownPosition();
    } catch (e) {
      // Ignored
    }
    
    // Fallback coordinates for demo if everything fails
    final lat = position?.latitude ?? 19.0728;
    final lng = position?.longitude ?? 73.0183;
    
    setState(() => _isLoadingGps = false);
    
    if (mounted) {
      context.go('/collector/handover/generating', extra: {
        'lot': widget.lot,
        'recycler': _selectedRecycler!,
        'actualWeight': _actualWeight,
        'finalPrice': finalPrice,
        'position': {'lat': lat, 'lng': lng},
      });
    }
  }
}
