import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/logger.dart';
import '../models/friend.dart';

class QRScannerWidget extends StatefulWidget {
  final Function(String qrData) onQRScanned;

  const QRScannerWidget({super.key, required this.onQRScanned});

  @override
  State<QRScannerWidget> createState() => _QRScannerWidgetState();
}

class _QRScannerWidgetState extends State<QRScannerWidget> {
  late MobileScannerController _controller;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      formats: [BarcodeFormat.qrCode],
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      returnImage: true,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleQRCodeDetected(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() => _isProcessing = true);

    try {
      final qrData = barcode.rawValue!;
      Logger.d('QRScanner', 'QR detected');

      Friend.fromQRString(qrData);
      Logger.success('QRScanner', 'QR validated');

      Navigator.of(context).pop();
      widget.onQRScanned(qrData);
    } catch (e) {
      Logger.e('QRScanner', 'Invalid QR code', e);
      setState(() {
        _error = 'Invalid QR code format';
        _isProcessing = false;
      });

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _error = null);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Scan Friend\'s QR Code',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: ValueListenableBuilder(
              valueListenable: _controller,
              builder: (context, value, child) {
                final icon =
                    value.torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off;
                return Icon(icon, color: Colors.white);
              },
            ),
            onPressed: () => _controller.toggleTorch(),
            tooltip: 'Toggle Flash',
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: _handleQRCodeDetected,
          ),
          if (_error != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          CustomPaint(
            size: Size.infinite,
            painter: ScannerOverlayPainter(
              scanAreaSize: MediaQuery.of(context).size.width * 0.70,
              borderColor: themeProvider.currentTheme.primary,
            ),
          ),
          Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.qr_code_scanner,
                      color: themeProvider.currentTheme.primary,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Position QR code in the frame',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ZXing Decoder (v7)',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: themeProvider.currentTheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Processing QR Code...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double scanAreaSize;
  final Color borderColor;

  ScannerOverlayPainter({
    required this.scanAreaSize,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: scanAreaSize,
      height: scanAreaSize,
    );

    final overlayPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill;

    final overlayPath =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRect(scanArea)
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(overlayPath, overlayPaint);

    final borderPaint =
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round;

    final cornerLength = 30.0;

    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + Offset(0, cornerLength),
      borderPaint,
    );

    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + Offset(0, cornerLength),
      borderPaint,
    );

    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + Offset(0, -cornerLength),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(-cornerLength, 0),
      borderPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + Offset(0, -cornerLength),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
