import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

final recyclerProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await DioClient.instance.get('/recyclers/me');
  return response.data;
});

class RecyclerPricesTab extends ConsumerStatefulWidget {
  const RecyclerPricesTab({super.key});

  @override
  ConsumerState<RecyclerPricesTab> createState() => _RecyclerPricesTabState();
}

class _RecyclerPricesTabState extends ConsumerState<RecyclerPricesTab> {
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _updatePrice(String category) async {
    final text = _controllers[category]?.text.trim();
    if (text == null || text.isEmpty) return;

    final newPrice = double.tryParse(text);
    if (newPrice == null) return;

    setState(() => _isSaving = true);

    try {
      await DioClient.instance.patch(
        '/recyclers/prices',
        data: {
          'category': category,
          'new_price': newPrice,
        },
      );
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$category price updated!')));
      ref.invalidate(recyclerProfileProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating price: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(recyclerProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Update Offered Rates', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFAA00))),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (profile) {
          final offeredRates = Map<String, dynamic>.from(profile['offered_rates'] ?? {});

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: offeredRates.length,
            itemBuilder: (context, index) {
              final category = offeredRates.keys.elementAt(index);
              final currentPrice = offeredRates[category];
              
              if (!_controllers.containsKey(category)) {
                _controllers[category] = TextEditingController(text: currentPrice.toString());
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        category,
                        style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _controllers[category],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(color: Colors.black87),
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: const Color(0xFFFAFAFA),
                          prefixText: '₹ ',
                          prefixStyle: const TextStyle(color: Colors.black87),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : () => _updatePrice(category),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFAA00),
                        foregroundColor: const Color(0xFFFFFFFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
