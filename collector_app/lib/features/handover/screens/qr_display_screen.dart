import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/local_storage/hive_setup.dart';
import '../../../models/api/handover_record.dart';
import '../repository/handover_repository.dart';

class QRDisplayScreen extends ConsumerStatefulWidget {
  final HandoverRecord record;

  const QRDisplayScreen({super.key, required this.record});

  @override
  ConsumerState<QRDisplayScreen> createState() => _QRDisplayScreenState();
}

class _QRDisplayScreenState extends ConsumerState<QRDisplayScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      try {
        final repo = ref.read(handoverRepositoryProvider);
        final status = await repo.verifyHandover(widget.record.refNumber);
        
        // When the recycler confirms, handover_timestamp will not be null
        if (status['handover_timestamp'] != null) {
          timer.cancel();
          
          // Remove from local active QR codes and mark lot as completed locally
          final lotId = widget.record.lotId;
          Hive.box(HiveBoxes.pendingTransactions).delete(lotId);
          
          // Also mark the lot locally as handoverCompleted so it vanishes from pending
          final lotsBox = Hive.box(HiveBoxes.pendingLots);
          for (var key in lotsBox.keys) {
            final l = lotsBox.get(key);
            if (l != null && (l.id == lotId || l.serverId == lotId)) {
              l.handoverCompleted = true;
              l.save();
              break;
            }
          }

          if (mounted) {
            context.go('/collector/handover/complete', extra: widget.record);
          }
        }
      } catch (e) {
        // ignore errors (e.g. network flakes) and keep polling
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('हैंडओवर रिकॉर्ड', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF00C896),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.record.refNumber,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.black87),
              ),
              const SizedBox(height: 32),
              Center(
                child: QrImageView(
                  data: widget.record.qrCodeData,
                  version: QrVersions.auto,
                  size: 280,
                  backgroundColor: Colors.white,
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
              const SizedBox(height: 32),
              
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    _SummaryRow('सामग्री', widget.record.materialCategory),
                    const Divider(),
                    _SummaryRow('वज़न', '${widget.record.weightAtCollection} kg'),
                    const Divider(),
                    _SummaryRow('रिसाइकलर', widget.record.recyclerName),
                    const Divider(),
                    _SummaryRow('स्थिति', widget.record.status),
                  ],
                ),
              ),
              
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Color(0xFF00C896)),
              const SizedBox(height: 16),
              const Text('Waiting for Recycler to scan...', style: TextStyle(color: Colors.black54, fontSize: 16, fontWeight: FontWeight.w500)),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF00C896),
                          side: const BorderSide(color: Color(0xFF00C896)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('शेयर किया जा रहा है...')));
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('शेयर करें', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          // Allow the collector to close the QR screen and do other things
                          // They can return to this from "Pending Lots"
                          context.go('/collector/home');
                        },
                        icon: const Icon(Icons.close),
                        label: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black54, fontSize: 16)),
          Text(value, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
