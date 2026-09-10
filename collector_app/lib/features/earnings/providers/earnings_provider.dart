import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class TransactionModel {
  final String id;
  final String materialCategory;
  final double quantityWeight;
  final double finalPrice;
  final String paymentStatus;

  TransactionModel({
    required this.id,
    required this.materialCategory,
    required this.quantityWeight,
    required this.finalPrice,
    required this.paymentStatus,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['transaction_id'],
        materialCategory: json['material_category'] ?? '',
        quantityWeight: (json['quantity_weight'] ?? 0).toDouble(),
        finalPrice: (json['final_price'] ?? 0).toDouble(),
        paymentStatus: json['payment_status'] ?? 'Pending',
      );
}

final earningsProvider = FutureProvider.autoDispose<List<TransactionModel>>((ref) async {
  // In a real app we'd get the collector_id from auth state.
  // Using the mock UUID used in backend tests.
  final response = await DioClient.instance.get('/transactions/history/me');
  final List data = response.data;
  return data.map((e) => TransactionModel.fromJson(e)).toList();
});
