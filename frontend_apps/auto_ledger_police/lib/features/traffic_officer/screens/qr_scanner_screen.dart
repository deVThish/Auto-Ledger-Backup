import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../services/traffic_fine_service.dart';
import 'license_preview_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _trafficFineService = TrafficFineService();
  final MobileScannerController _controller = MobileScannerController();
  final TextEditingController _locationController = TextEditingController();

  bool _isLoading = false;
  bool _isScanning = false;

  @override
  void dispose() {
    _controller.dispose();
    _locationController.dispose();
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) {
    if (_isScanning || _isLoading) return;

    final qrToken = capture.barcodes.first.rawValue;
    if (qrToken == null || qrToken.isEmpty) {
      AppErrorHandler.showPopup(
        context,
        message: 'Invalid QR code. Please try again.',
      );
      return;
    }

    _isScanning = true;
    _verifyLicense(qrToken);
  }

  Future<void> _verifyLicense(String qrToken) async {
    setState(() => _isLoading = true);

    try {
      final location = _locationController.text.trim();
      final license = await _trafficFineService.scanQr(
        qrToken: qrToken,
        location: location.isEmpty ? 'Current Location' : location,
      );

      if (!mounted) return;

      await _controller.stop();

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LicensePreviewScreen(
            qrToken: qrToken,
            license: license,
          ),
        ),
      ).then((_) {
        if (mounted) {
          _controller.start();
          setState(() {
            _isLoading = false;
            _isScanning = false;
          });
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message: error.message,
      );
      setState(() {
        _isLoading = false;
        _isScanning = false;
      });
      _controller.start();
    } catch (_) {
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to verify license. Please try again.',
      );
      setState(() {
        _isLoading = false;
        _isScanning = false;
      });
      _controller.start();
    }
  }

  void _toggleFlash() {
    _controller.toggleTorch();
  }

  void _toggleCamera() {
    _controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Scan Driver QR',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: const Icon(Icons.flash_on_rounded),
          ),
          IconButton(
            onPressed: _toggleCamera,
            icon: const Icon(Icons.cameraswitch_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    margin: const EdgeInsets.all(16),
                    clipBehavior: Clip.hardEdge,
                    child: Stack(
                      children: [
                        MobileScanner(
                          controller: _controller,
                          onDetect: _handleScan,
                        ),
                        CustomPaint(
                          painter: _QrOverlayPainter(),
                          size: Size.infinite,
                        ),
                        if (_isLoading)
                          Container(
                            color: Colors.black.withValues(alpha: 0.6),
                            child: const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(
                                    color: Colors.white,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Verifying license...',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Positioned(
                          bottom: 24,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Position QR code inside the frame',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.lightGray,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.borderGray.withValues(alpha: 0.3),
                            ),
                          ),
                          child: TextField(
                            controller: _locationController,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              hintText: 'Enter location (optional)',
                              prefixIcon: Icon(
                                Icons.place_outlined,
                                color: AppTheme.textGray,
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Scan the QR code displayed on the driver\'s app',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textGray,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QrOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;

    final cutOutSize = size.width * 0.65;
    final left = (size.width - cutOutSize) / 2;
    final top = (size.height - cutOutSize) / 2;
    final right = left + cutOutSize;
    final bottom = top + cutOutSize;

    final cornerLength = 30.0;

    // Top-left corner
    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), paint);
    canvas.drawLine(Offset(left, top), Offset(left + cornerLength, top), paint);

    // Top-right corner
    canvas.drawLine(Offset(right, top + cornerLength), Offset(right, top), paint);
    canvas.drawLine(Offset(right, top), Offset(right - cornerLength, top), paint);

    // Bottom-left corner
    canvas.drawLine(Offset(left, bottom - cornerLength), Offset(left, bottom), paint);
    canvas.drawLine(Offset(left, bottom), Offset(left + cornerLength, bottom), paint);

    // Bottom-right corner
    canvas.drawLine(Offset(right, bottom - cornerLength), Offset(right, bottom), paint);
    canvas.drawLine(Offset(right, bottom), Offset(right - cornerLength, bottom), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}