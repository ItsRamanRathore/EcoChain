import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../models/api/handover_record.dart';
import '../../../core/local_storage/hive_setup.dart';
import '../../../models/local/lot_local.dart';

class HandoverCompleteScreen extends StatefulWidget {
  final HandoverRecord record;
  const HandoverCompleteScreen({super.key, required this.record});

  @override
  State<HandoverCompleteScreen> createState() => _HandoverCompleteScreenState();
}

class _HandoverCompleteScreenState extends State<HandoverCompleteScreen> {
  @override
  void initState() {
    super.initState();
    _markHandoverCompleted();
  }

  Future<void> _markHandoverCompleted() async {
    final box = Hive.box(HiveBoxes.pendingLots);
    for (var i = 0; i < box.length; i++) {
      final lot = box.getAt(i) as LotLocal;
      // In a real app we match by serverId if sync has occurred
      // For demo, if lot is unmatched we just mark the first one. 
      // Using lotId here which might be the mock serverId.
      if (lot.serverId == widget.record.lotId || lot.id == widget.record.lotId) {
        lot.handoverCompleted = true;
        await lot.save();
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified, color: Color(0xFF00C896), size: 120),
              const SizedBox(height: 32),
              const Text('Handover Complete', style: TextStyle(color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Recycler has received the materials.\nPayment is processing.', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54, fontSize: 16)),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C896),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.go('/collector/earnings'),
                  child: const Text('View Earnings', style: TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/collector/home'),
                child: const Text('Return to Home', style: TextStyle(color: Colors.black54, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
