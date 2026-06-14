import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../shared/widgets/app_button.dart';
import '../services/traffic_fine_service.dart';
import 'license_preview_screen.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _qrTokenController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _trafficFineService = TrafficFineService();

  bool _isLoading = false;

  @override
  void dispose() {
    _qrTokenController.dispose();
    _licenseNumberController.dispose();
    super.dispose();
  }

  String _extractLicenseNumber(String token) {
    try {
      final parts = token.trim().split('.');

      if (parts.length != 3) {
        return '';
      }

      final normalizedPayload = base64Url.normalize(parts[1]);
      final decodedPayload = utf8.decode(base64Url.decode(normalizedPayload));
      final payload = jsonDecode(decodedPayload);

      if (payload is! Map<String, dynamic>) {
        return '';
      }

      return payload['licenseNumber']?.toString() ?? '';
    } catch (_) {
      return '';
    }
  }

  Future<void> _handleVerify() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please enter the driver QR token.',
      );
      return;
    }

    final qrToken = _qrTokenController.text.trim();
    final extractedLicenseNumber = _extractLicenseNumber(qrToken);
    final fallbackLicenseNumber = _licenseNumberController.text.trim();
    final licenseNumber = extractedLicenseNumber.isNotEmpty
        ? extractedLicenseNumber
        : fallbackLicenseNumber;

    if (licenseNumber.isEmpty) {
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to read license number from QR token.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final license = await _trafficFineService.verifyLicense(licenseNumber);

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LicensePreviewScreen(
            qrToken: qrToken,
            license: license,
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: 'Unable to verify license. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Driver QR Verification',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 26.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlack,
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(height: 18),
                          Text(
                            'Verify Driver License',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Paste the driver QR token to verify the license before issuing a fine.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(color: AppTheme.borderGray),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 24,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextFormField(
                              controller: _qrTokenController,
                              minLines: 4,
                              maxLines: 6,
                              textInputAction: TextInputAction.newline,
                              decoration: const InputDecoration(
                                labelText: 'Driver QR Token',
                                hintText: 'Paste scanned QR token',
                                prefixIcon: Icon(Icons.qr_code_2_rounded),
                                alignLabelWithHint: true,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'QR token is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _licenseNumberController,
                              textInputAction: TextInputAction.done,
                              decoration: const InputDecoration(
                                labelText: 'License Number',
                                hintText: 'Optional if QR token contains it',
                                prefixIcon: Icon(Icons.credit_card_rounded),
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Use the license number field only when the QR token cannot be decoded on the device.',
                              style: TextStyle(
                                color: AppTheme.textGray,
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: 'Verify License',
                              icon: Icons.verified_user_outlined,
                              isLoading: _isLoading,
                              onPressed: _handleVerify,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}