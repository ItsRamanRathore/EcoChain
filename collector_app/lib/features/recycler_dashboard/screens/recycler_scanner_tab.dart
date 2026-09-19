import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';

class RecyclerScannerTab extends StatefulWidget {
  const RecyclerScannerTab({super.key});

  @override
  State<RecyclerScannerTab> createState() => _RecyclerScannerTabState();
}

/// Uses [WidgetsBindingObserver] to handle app lifecycle (foreground/background)
/// and overrides [didChangeDependencies] to handle GoRouter ShellRoute tab switches,
/// since [initState] only fires once when the tab is first created inside a ShellRoute.
class _RecyclerScannerTabState extends State<RecyclerScannerTab>
    with WidgetsBindingObserver {
  late final MobileScannerController _scannerController;
  bool _isProcessing = false;
  bool _hasCameraPermission = false;
  bool _isScannerRunning = false;
  final TextEditingController _refController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // autoStart: false — we manage start/stop manually for full lifecycle control
    _scannerController = MobileScannerController(autoStart: false);
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  /// Request camera permission and start the scanner if granted.
  Future<void> _initCamera() async {
    final status = await Permission.camera.request();
    if (!mounted) return;
    final granted = status.isGranted;
    setState(() => _hasCameraPermission = granted);
    if (granted) _startScanner();
  }

  void _startScanner() {
    if (!_isScannerRunning && _hasCameraPermission) {
      _scannerController.start();
      if (mounted) setState(() => _isScannerRunning = true);
    }
  }

  void _stopScanner() {
    if (_isScannerRunning) {
      _scannerController.stop();
      if (mounted) setState(() => _isScannerRunning = false);
    }
  }

  /// [didChangeDependencies] is called every time the route context changes —
  /// including when the user switches tabs inside a [ShellRoute]. This is the
  /// correct hook to start/stop the scanner on tab visibility changes, since
  /// [initState] only fires once per widget instance lifetime.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final location = GoRouterState.of(context).matchedLocation;
    final isActive = location.startsWith('/recycler/scanner');
    if (isActive && _hasCameraPermission && !_isScannerRunning) {
      _startScanner();
    } else if (!isActive && _isScannerRunning) {
      _stopScanner();
    }
  }

  /// Handles app going to background / returning to foreground.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only act when this tab is currently visible
    final location = GoRouterState.of(context).matchedLocation;
    if (!location.startsWith('/recycler/scanner')) return;

    switch (state) {
      case AppLifecycleState.resumed:
        _startScanner();
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _stopScanner();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    _refController.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    for (final barcode in capture.barcodes) {
      if (barcode.rawValue != null) {
        _processScannedData(barcode.rawValue!);
        break;
      }
    }
  }

  void _processScannedData(String data) {
    setState(() => _isProcessing = true);

    try {
      final payload = jsonDecode(data);
      if (payload.containsKey('lot_id') && payload.containsKey('transaction_id')) {
        _stopScanner();

        context.push('/recycler/handover/confirm', extra: payload).then((_) {
          // Restart the scanner when the user pops back from the confirm screen
          if (mounted) {
            setState(() => _isProcessing = false);
            _startScanner();
          }
        });
        return;
      }
    } catch (e) {
      // Not valid JSON or not our QR format — fall through to reset
    }

    // Reset processing flag after a short delay if no valid QR was found
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _isProcessing = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Scan Handover QR', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFFFFFFF),
      ),
      body: !_hasCameraPermission
          ? _buildPermissionDeniedScreen()
          : Stack(
              children: [
                MobileScanner(
                  controller: _scannerController,
                  onDetect: _onDetect,
                ),

                // Viewfinder overlay
                Container(
                  decoration: ShapeDecoration(
                    shape: QrScannerOverlayShape(
                      borderColor: const Color(0xFFFFAA00),
                      borderRadius: 10,
                      borderLength: 30,
                      borderWidth: 10,
                      cutOutSize: 250,
                    ),
                  ),
                ),

                // Manual ref-number entry
                Positioned(
                  bottom: 40,
                  left: 24,
                  right: 24,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFFFF),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.black26),
                    ),
                    child: Column(
                      children: [
                        const Text('Or enter Ref Number manually', style: TextStyle(color: Colors.black87)),
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
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              child: const Icon(Icons.arrow_forward),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPermissionDeniedScreen() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 80, color: Color(0xFFFFAA00)),
            const SizedBox(height: 24),
            const Text(
              'Camera Access Required',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Please allow camera access to scan the QR code on the handover receipt.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () async {
                final status = await Permission.camera.request();
                if (!mounted) return;
                if (status.isGranted) {
                  setState(() => _hasCameraPermission = true);
                  _startScanner();
                } else {
                  openAppSettings();
                }
              },
              icon: const Icon(Icons.settings),
              label: const Text('Grant Permission'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFAA00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QrScannerOverlayShape extends ShapeBorder {
  final Color borderColor;
  final double borderWidth;
  final double overlayColor;
  final double borderRadius;
  final double borderLength;
  final double cutOutSize;

  QrScannerOverlayShape({
    this.borderColor = Colors.red,
    this.borderWidth = 3.0,
    this.overlayColor = 150,
    this.borderRadius = 0,
    this.borderLength = 40,
    this.cutOutSize = 250,
  });

  @override
  EdgeInsetsGeometry get dimensions => const EdgeInsets.all(10.0);

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    return Path()
      ..fillType = PathFillType.evenOdd
      ..addPath(getOuterPath(rect), Offset.zero);
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    Path getLeftTopPath(Rect rect) {
      return Path()
        ..moveTo(rect.left, rect.bottom)
        ..lineTo(rect.left, rect.top)
        ..lineTo(rect.right, rect.top);
    }
    return getLeftTopPath(rect)
      ..lineTo(rect.right, rect.bottom)
      ..lineTo(rect.left, rect.bottom)
      ..lineTo(rect.left, rect.top);
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    final width = rect.width;
    final borderWidthSize = width / 2;
    final height = rect.height;
    final borderOffset = borderWidth / 2;
    final effectiveBorderLength = borderLength > cutOutSize / 2 + borderWidthSize
        ? cutOutSize / 2 + borderOffset
        : borderLength;
    final effectiveCutOutSize = cutOutSize < width ? cutOutSize : width - borderOffset;

    final backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final cutOutRect = Rect.fromLTWH(
      rect.left + width / 2 - effectiveCutOutSize / 2 + borderOffset,
      rect.top + height / 2 - effectiveCutOutSize / 2 + borderOffset,
      effectiveCutOutSize - borderOffset * 2,
      effectiveCutOutSize - borderOffset * 2,
    );

    canvas.saveLayer(rect, backgroundPaint);
    canvas.drawRect(rect, backgroundPaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(cutOutRect, Radius.circular(borderRadius)),
      Paint()..blendMode = BlendMode.clear,
    );
    canvas.restore();

    // Draw corner markers
    final path = Path();
    // Top left
    path.moveTo(cutOutRect.left, cutOutRect.top + effectiveBorderLength);
    path.lineTo(cutOutRect.left, cutOutRect.top + borderRadius);
    path.arcToPoint(Offset(cutOutRect.left + borderRadius, cutOutRect.top),
        radius: Radius.circular(borderRadius));
    path.lineTo(cutOutRect.left + effectiveBorderLength, cutOutRect.top);
    // Top right
    path.moveTo(cutOutRect.right - effectiveBorderLength, cutOutRect.top);
    path.lineTo(cutOutRect.right - borderRadius, cutOutRect.top);
    path.arcToPoint(Offset(cutOutRect.right, cutOutRect.top + borderRadius),
        radius: Radius.circular(borderRadius));
    path.lineTo(cutOutRect.right, cutOutRect.top + effectiveBorderLength);
    // Bottom right
    path.moveTo(cutOutRect.right, cutOutRect.bottom - effectiveBorderLength);
    path.lineTo(cutOutRect.right, cutOutRect.bottom - borderRadius);
    path.arcToPoint(Offset(cutOutRect.right - borderRadius, cutOutRect.bottom),
        radius: Radius.circular(borderRadius));
    path.lineTo(cutOutRect.right - effectiveBorderLength, cutOutRect.bottom);
    // Bottom left
    path.moveTo(cutOutRect.left + effectiveBorderLength, cutOutRect.bottom);
    path.lineTo(cutOutRect.left + borderRadius, cutOutRect.bottom);
    path.arcToPoint(Offset(cutOutRect.left, cutOutRect.bottom - borderRadius),
        radius: Radius.circular(borderRadius));
    path.lineTo(cutOutRect.left, cutOutRect.bottom - effectiveBorderLength);

    canvas.drawPath(path, borderPaint);
  }

  @override
  ShapeBorder scale(double t) {
    return QrScannerOverlayShape(
      borderColor: borderColor,
      borderWidth: borderWidth * t,
      overlayColor: overlayColor,
      borderRadius: borderRadius * t,
      borderLength: borderLength * t,
      cutOutSize: cutOutSize * t,
    );
  }
}
