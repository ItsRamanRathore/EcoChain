import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';

class RecyclerDashboardData {
  final int totalTransactions;
  final double totalWeightProcessed;
  final List<dynamic> recentTransactions;
  final List<dynamic> pendingTransactions;

  RecyclerDashboardData({
    required this.totalTransactions,
    required this.totalWeightProcessed,
    required this.recentTransactions,
    required this.pendingTransactions,
  });

  factory RecyclerDashboardData.fromJson(Map<String, dynamic> json) {
    return RecyclerDashboardData(
      totalTransactions: json['total_transactions'] ?? 0,
      totalWeightProcessed: (json['total_weight_processed'] ?? 0).toDouble(),
      recentTransactions: json['recent_transactions'] ?? [],
      pendingTransactions: json['pending_transactions'] ?? [],
    );
  }
}

final recyclerDashboardProvider = FutureProvider.autoDispose<RecyclerDashboardData>((ref) async {
  final response = await DioClient.instance.get('/recyclers/dashboard/metrics');
  return RecyclerDashboardData.fromJson(response.data);
});
