import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import '../providers/recycler_dashboard_provider.dart';

class RecyclerHandoverConfirmScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> payload;

  const RecyclerHandoverConfirmScreen({super.key, required this.payload});

  @override
  ConsumerState<RecyclerHandoverConfirmScreen> createState() => _RecyclerHandoverConfirmScreenState();
}

class _RecyclerHandoverConfirmScreenState extends ConsumerState<RecyclerHandoverConfirmScreen> {
  bool _isLoading = false;
  final _weightController = TextEditingController();
  final _priceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Pre-fill with payload data if available
    if (widget.payload.containsKey('quantity_weight')) {
      _weightController.text = widget.payload['quantity_weight'].toString();
    }
    if (widget.payload.containsKey('final_price')) {
      _priceController.text = widget.payload['final_price'].toString();
    }
  }

  Future<void> _confirmHandover() async {
    final weightStr = _weightController.text.trim();
    final priceStr = _priceController.text.trim();
    if (weightStr.isEmpty || priceStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter weight and price')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'recycler_id': widget.payload['recycler_id'],
        'actual_weight': double.parse(weightStr),
        'final_price': double.parse(priceStr),
        'handover_gps': '19.0760,72.8777', // Mock GPS
      };

      await DioClient.instance.patch(
        '/transactions/${widget.payload['transaction_id']}/confirm',
        data: data,
      );

      ref.invalidate(recyclerDashboardProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Handover confirmed successfully!')));
        context.go('/recycler/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lotId = widget.payload['lot_id'] ?? 'Unknown';
    final shortLotId = lotId.length > 8 ? lotId.substring(0, 8) : lotId;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Confirm Handover', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFFAA00).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Lot Request Scanned', style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  Text('Lot ID: $shortLotId', style: const TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Transaction: ${widget.payload['transaction_id']}', style: const TextStyle(color: Colors.black38, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('Verify Details', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            // Weight Input
            const Text('Actual Weight (kg)', style: TextStyle(color: Colors.black87)),
            const SizedBox(height: 8),
            TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.black87, fontSize: 18),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.scale, color: Colors.black38),
              ),
            ),
            const SizedBox(height: 20),

            // Price Input
            const Text('Final Price (₹)', style: TextStyle(color: Colors.black87)),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.black87, fontSize: 18),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFFFFFFF),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                prefixText: '₹ ',
                prefixStyle: const TextStyle(color: Colors.black87, fontSize: 18),
              ),
            ),
            
            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _confirmHandover,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFAA00),
                  foregroundColor: const Color(0xFFFFFFFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2))
                    : const Text('Confirm Handover', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
