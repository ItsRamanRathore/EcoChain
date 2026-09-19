import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:image_picker/image_picker.dart';

class RecyclerScannerTab extends StatefulWidget {
  const RecyclerScannerTab({super.key});

  @override
  State<RecyclerScannerTab> createState() => _RecyclerScannerTabState();
}

class _RecyclerScannerTabState extends State<RecyclerScannerTab> {
  final TextEditingController _refController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final BarcodeScanner _barcodeScanner = BarcodeScanner(formats: [BarcodeFormat.qrCode]);

  bool _isProcessing = false;

  @override
  void dispose() {
    _barcodeScanner.close();
    _refController.dispose();
    super.dispose();
  }

  /// Opens phone camera (ImagePicker), captures image, and extracts QR code via ML Kit
  Future<void> _captureAndScanQr() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
      );

      if (photo == null) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      final inputImage = InputImage.fromFilePath(photo.path);
      final List<Barcode> barcodes = await _barcodeScanner.processImage(inputImage);

      if (barcodes.isNotEmpty) {
        for (final barcode in barcodes) {
          final String? rawValue = barcode.rawValue;
          if (rawValue != null && rawValue.isNotEmpty) {
            _processScannedData(rawValue);
            return;
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No QR code detected in the photo. Please take a clear picture of the QR code.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read QR: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _processScannedData(String data) {
    try {
      final payload = jsonDecode(data);
      if (payload.containsKey('lot_id') && payload.containsKey('transaction_id')) {
        context.push('/recycler/handover/confirm', extra: payload).then((_) {
          if (mounted) setState(() => _isProcessing = false);
        });
        return;
      }
      
      if (payload.containsKey('ref')) {
        context.push('/recycler/handover/confirm', extra: {
          'lot_id': payload['ref'],
          'transaction_id': 'manual-entry',
          'original_lot_id': payload['lot_id'],
        }).then((_) {
          if (mounted) setState(() => _isProcessing = false);
        });
        return;
      }
    } catch (e) {
      if (data.startsWith('HO-') || data.length > 5) {
        context.push('/recycler/handover/confirm', extra: {
          'lot_id': data,
          'transaction_id': 'manual-entry',
        }).then((_) {
          if (mounted) setState(() => _isProcessing = false);
        });
        return;
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid Handover QR code format.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Scan Handover QR', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFF8E1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, size: 72, color: Color(0xFFFFAA00)),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Capture Handover QR Photo',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Opens your phone camera to take a picture of the collector QR code.',
                    style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _captureAndScanQr,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt, size: 28),
                      label: Text(
                        _isProcessing ? 'Analyzing QR...' : 'Open Phone Camera',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFAA00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Manual Ref Entry Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFFFF),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Or Enter Ref Number Manually',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _refController,
                          style: const TextStyle(color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'e.g., HO-2026-MH-ABCD',
                            hintStyle: const TextStyle(color: Colors.black38),
                            filled: true,
                            fillColor: const Color(0xFFFAFAFA),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () {
                          if (_refController.text.isNotEmpty) {
                            _processScannedData(jsonEncode({
                              'lot_id': _refController.text,
                              'transaction_id': 'manual-entry',
                            }));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFAA00),
                          foregroundColor: const Color(0xFFFFFFFF),
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Icon(Icons.arrow_forward),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
