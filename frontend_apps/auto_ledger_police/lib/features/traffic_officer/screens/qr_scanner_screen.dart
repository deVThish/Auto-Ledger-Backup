import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/license_model.dart';
import '../services/traffic_fine_service.dart';
import 'license_preview_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen>
    with WidgetsBindingObserver {
  final _trafficFineService = TrafficFineService();
  final MobileScannerController _controller = MobileScannerController(
    autoStart: false,
  );

  bool _isLoading = false;
  bool _isScanning = false;
  bool _hasPermissionError = false;

  String _lastSessionId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initScanner();
  }

  Future<void> _initScanner() async {
    if (!mounted) return;
    try {
      await _controller.start();
      if (mounted) {
        setState(() => _hasPermissionError = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _hasPermissionError = true);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _initScanner();
    } else if (state == AppLifecycleState.paused) {
      _controller.stop();
    }
  }

  void _handleScan(BarcodeCapture capture) {
    if (_isScanning || _isLoading) return;
    if (capture.barcodes.isEmpty) return;

    final sessionId = capture.barcodes.first.rawValue;
    if (sessionId == null || sessionId.trim().isEmpty) {
      AppErrorHandler.showPopup(
        context,
        message: 'Invalid QR code. Please try again.',
      );
      return;
    }

    final cleanedSessionId = sessionId.trim();

    if (_lastSessionId.isNotEmpty && cleanedSessionId == _lastSessionId) {
      AppErrorHandler.showPopup(
        context,
        message: 'This QR session is already active. Please scan a new QR.',
      );
      return;
    }

    _isScanning = true;
    _verifySession(cleanedSessionId);
  }

  Future<void> _verifySession(String sessionId) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      await _controller.stop();

      final license = await _trafficFineService.scanQr(
        sessionId: sessionId,
        location: 'Current Location',
      );

      if (!mounted) return;

      _lastSessionId = sessionId;

      await _openPreviewWithLicense(license, sessionId);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _isScanning = false;
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

      if (error.message.toLowerCase().contains('expired')) {
        _initScanner();
      }
    } catch (_) {
      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: 'Unable to verify QR session. Please try again.',
      );

      setState(() {
        _isLoading = false;
        _isScanning = false;
      });

      _initScanner();
    }
  }

  Future<void> _openPreviewWithLicense(
    LicenseModel license,
    String sessionId, {
    bool reuseSession = false,
  }) async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LicensePreviewScreen(
          qrToken: sessionId,
          license: license,
        ),
      ),
    );

    if (!mounted) return;

    if (reuseSession) {
      setState(() {
        _isLoading = false;
        _isScanning = false;
      });
    }
  }

  void _toggleFlash() {
    _controller.toggleTorch();
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
            color: AppTheme.policeBlue,
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final screenHeight = constraints.maxHeight;
            final squareSize = screenWidth < screenHeight
                ? screenWidth - 32
                : screenHeight - 200;

            return Column(
              children: [
                Expanded(
                  flex: 6,
                  child: Center(
                    child: Container(
                      width: squareSize,
                      height: squareSize,
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
                      clipBehavior: Clip.hardEdge,
                      child: Stack(
                        children: [
                          if (_hasPermissionError)
                            Container(
                              color: Colors.black,
                              padding: const EdgeInsets.all(20),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.camera_alt_outlined,
                                      color: Colors.white54,
                                      size: 40,
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Camera permission is required.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 6),
                                    Text(
                                      'Please allow camera access in App Settings to scan QR codes.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            MobileScanner(
                              controller: _controller,
                              onDetect: _handleScan,
                              errorBuilder: (context, error, child) {
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  if (mounted && !_hasPermissionError) {
                                    setState(() => _hasPermissionError = true);
                                  }
                                });
                                return const SizedBox.shrink();
                              },
                            ),
                          if (!_hasPermissionError)
                            CustomPaint(
                              painter: _QrOverlayPainter(
                                cutOutSize: squareSize * 0.7,
                              ),
                              size: Size(squareSize, squareSize),
                            ),
                          if (_isLoading)
                            Container(
                              color: Colors.black.withValues(alpha: 0.6),
                              child: const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    SizedBox(height: 14),
                                    Text(
                                      'Verifying QR session...',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (!_hasPermissionError)
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                margin:
                                    const EdgeInsets.symmetric(horizontal: 24),
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
                                      size: 16,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Position QR code inside the frame',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
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
                ),
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.qr_code_2_rounded,
                            color: AppTheme.policeBlue,
                            size: 28,
                          ),
                          const SizedBox(height: 8),
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
                ),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _QrOverlayPainter extends CustomPainter {
  const _QrOverlayPainter({required this.cutOutSize});

  final double cutOutSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final left = (size.width - cutOutSize) / 2;
    final top = (size.height - cutOutSize) / 2;
    final right = left + cutOutSize;
    final bottom = top + cutOutSize;
    const cornerLength = 28.0;

    canvas.drawLine(Offset(left, top + cornerLength), Offset(left, top), paint);
    canvas.drawLine(
      Offset(left, top),
      Offset(left + cornerLength, top),
      paint,
    );

    canvas.drawLine(
      Offset(right, top + cornerLength),
      Offset(right, top),
      paint,
    );
    canvas.drawLine(
      Offset(right, top),
      Offset(right - cornerLength, top),
      paint,
    );

    canvas.drawLine(
      Offset(left, bottom - cornerLength),
      Offset(left, bottom),
      paint,
    );
    canvas.drawLine(
      Offset(left, bottom),
      Offset(left + cornerLength, bottom),
      paint,
    );

    canvas.drawLine(
      Offset(right, bottom - cornerLength),
      Offset(right, bottom),
      paint,
    );
    canvas.drawLine(
      Offset(right, bottom),
      Offset(right - cornerLength, bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}