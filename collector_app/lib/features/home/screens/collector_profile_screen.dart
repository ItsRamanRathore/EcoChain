import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../l10n/app_localizations.dart';

class CollectorProfileScreen extends ConsumerWidget {
  const CollectorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final profileAsync = ref.watch(_collectorProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FFFE),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          AppLocalizations.of(context)!.myProfile, 
          style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            tooltip: 'Logout',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF00C896))),
        error: (e, _) => Center(child: Text('Error: $e', style: const TextStyle(color: Colors.red))),
        data: (profile) => SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C896).withValues(alpha: 0.15),
                ),
                child: const Icon(Icons.person, color: Color(0xFF00C896), size: 40),
              ),
              const SizedBox(height: 12),
              Text(
                profile['display_name'] ?? authState.displayName ?? 'Collector',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.black87),
              ),
              Text(
                '${profile['operating_district'] ?? ''}, ${profile['operating_state'] ?? ''}',
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 28),

              // Stats
              Row(
                children: [
                  _StatCard(
                    label: AppLocalizations.of(context)!.profileTransactions,
                    value: '${profile['total_transactions'] ?? 0}',
                    icon: Icons.receipt_long,
                    color: const Color(0xFF00C896),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: AppLocalizations.of(context)!.profileEarnings,
                    value: '₹${(profile['total_earnings'] ?? 0.0).toStringAsFixed(0)}',
                    icon: Icons.currency_rupee,
                    color: const Color(0xFF4D9FFF),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              _InfoCard(items: [
                _InfoItem(icon: Icons.language, label: AppLocalizations.of(context)!.profileLanguage, value: profile['preferred_language'] ?? '-'),
                _InfoItem(icon: Icons.calendar_today, label: AppLocalizations.of(context)!.profileJoined, value: profile['registration_date'] ?? '-'),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

final _collectorProfileProvider = FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final response = await DioClient.instance.get('/collectors/me');
  return response.data as Map<String, dynamic>;
});

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoItem> items;
  const _InfoCard({required this.items});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: items.map((item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(item.icon, color: Colors.black38, size: 20),
              const SizedBox(width: 12),
              Text(item.label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
              const Spacer(),
              Text(item.value, style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600)),
            ],
          ),
        )).toList(),
      ),
    );
  }
}

class _InfoItem {
  final IconData icon;
  final String label;
  final String value;
  const _InfoItem({required this.icon, required this.label, required this.value});
}
