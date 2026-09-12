import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../repository/handover_repository.dart';
import '../../../models/local/lot_local.dart';
import '../../../models/api/recycler_model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/local_storage/hive_setup.dart';

class HandoverGenerateScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> args;
  const HandoverGenerateScreen({super.key, required this.args});

  @override
  ConsumerState<HandoverGenerateScreen> createState() => _HandoverGenerateScreenState();
}

class _HandoverGenerateScreenState extends ConsumerState<HandoverGenerateScreen> {
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _generate());
  }

  Future<void> _generate() async {
    setState(() => _error = null);
    try {
      final lot = widget.args['lot'] as LotLocal;
      final recycler = widget.args['recycler'] as RecyclerModel;
      
      final record = await ref.read(handoverRepositoryProvider).generateHandover(
        lotId: lot.serverId!,
        actualWeight: widget.args['actualWeight'],
        finalPrice: widget.args['finalPrice'],
        handoverGps: widget.args['position'],
        recyclerId: recycler.recyclerId,
        materialCategory: lot.materialCategory,
      );
      
      // Save record locally for pending lots access
      Hive.box(HiveBoxes.pendingTransactions).put(lot.serverId!, record.toJson());
      
      if (mounted) {
        context.go('/collector/handover/qr', extra: record);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
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
          child: _error == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF00C896)),
                    SizedBox(height: 24),
                    Text('Generating Secure Handover Record...', style: TextStyle(color: Colors.black87, fontSize: 16)),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red, size: 64),
                    const SizedBox(height: 16),
                    Text('Generation Failed', style: const TextStyle(color: Colors.black87, fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C896), foregroundColor: Colors.black),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: _generate,
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => context.pop(),
                      child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
