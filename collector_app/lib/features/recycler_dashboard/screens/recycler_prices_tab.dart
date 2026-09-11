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

  Future<void> _updatePrice(String category, double newPrice) async {
    setState(() => _isSaving = true);
    try {
      await DioClient.instance.patch(
        '/recyclers/prices',
        data: {
          'category': category,
          'new_price': newPrice,
        },
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$category price updated!'), backgroundColor: const Color(0xFFFFAA00)));
      ref.invalidate(recyclerProfileProvider);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating price: $e'), backgroundColor: const Color(0xFFFF4D6D)));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showAddCategoryDialog() {
    final catController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Add New Category', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: catController,
              decoration: InputDecoration(
                labelText: 'Category Name',
                hintText: 'e.g. Copper Wire',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Price per Kg (₹)',
                hintText: 'e.g. 500',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            onPressed: () {
              final cat = catController.text.trim();
              final price = double.tryParse(priceController.text);
              if (cat.isNotEmpty && price != null) {
                Navigator.pop(ctx);
                _updatePrice(cat, price);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFAA00), foregroundColor: Colors.white),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(recyclerProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Update Offered Rates', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
      ),
      floatingActionButton: profileAsync.hasValue ? FloatingActionButton.extended(
        onPressed: _showAddCategoryDialog,
        backgroundColor: const Color(0xFFFFAA00),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Category', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ) : null,
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFFFAA00))),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (profile) {
          final offeredRates = Map<String, dynamic>.from(profile['offered_rates'] ?? {});

          if (offeredRates.isEmpty) {
            return const Center(child: Text('No categories added yet. Add one below.', style: TextStyle(color: Colors.black54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 80),
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
                      onPressed: _isSaving ? null : () {
                        final price = double.tryParse(_controllers[category]!.text);
                        if (price != null) _updatePrice(category, price);
                      },
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
