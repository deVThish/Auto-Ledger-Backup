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

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _trafficFineService = TrafficFineService();
  final MobileScannerController _controller = MobileScannerController();

  bool _isLoading = false;
  bool _isScanning = false;

  String _lastQrToken = '';
  LicenseModel? _activeSessionLicense;

  bool get _hasActiveSession {
    final license = _activeSessionLicense;
    if (license == null) return false;
    return license.scanExpiresAt != null &&
        DateTime.now().isBefore(license.scanExpiresAt!);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.start();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScan(BarcodeCapture capture) {
    if (_isScanning || _isLoading) return;
    if (capture.barcodes.isEmpty) return;

    final qrToken = capture.barcodes.first.rawValue;
    if (qrToken == null || qrToken.trim().isEmpty) {
      AppErrorHandler.showPopup(
        context,
        message: 'Invalid QR code. Please try again.',
      );
      return;
    }

    final cleanedToken = qrToken.trim();

    if (_hasActiveSession &&
        _lastQrToken.isNotEmpty &&
        cleanedToken == _lastQrToken) {
      final activeLicense = _activeSessionLicense;
      if (activeLicense != null) {
        _isScanning = true;
        _openPreviewWithLicense(activeLicense, cleanedToken, reuseSession: true);
        return;
      }
    }

    _isScanning = true;
    _verifyLicense(cleanedToken);
  }

  Future<void> _verifyLicense(String qrToken) async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      final license = await _trafficFineService.scanQr(
        qrToken: qrToken,
        location: 'Current Location',
      );

      if (!mounted) return;

      await _controller.stop();

      final sessionToken = license.scanToken.trim().isNotEmpty
          ? license.scanToken.trim()
          : qrToken.trim();

      final now = license.scanVerifiedAt ?? DateTime.now();

      final sessionLicense = license.copyWith(
        scanToken: sessionToken,
        scanVerifiedAt: now,
        scanExpiresAt: _extractExpiryFromJwt(sessionToken) ?? now.add(const Duration(minutes: 10)),
      );

      _lastQrToken = qrToken;
      _activeSessionLicense = sessionLicense;

      await _openPreviewWithLicense(sessionLicense, sessionToken);

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
    }
  }

  DateTime? _extractExpiryFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = utf8.decode(base64Url.decode(normalized));
      final json = Map<String, dynamic>.from(jsonDecode(decoded) as Map);
      final exp = json['exp'];
      if (exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _openPreviewWithLicense(
    LicenseModel license,
    String qrToken, {
    bool reuseSession = false,
  }) async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LicensePreviewScreen(
          qrToken: qrToken,
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
                          MobileScanner(
                            controller: _controller,
                            onDetect: _handleScan,
                          ),
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
                                      'Verifying license...',
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
                          Positioned(
                            bottom: 20,
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