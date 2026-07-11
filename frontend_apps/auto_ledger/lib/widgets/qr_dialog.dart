import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class QRDialog extends StatefulWidget {
  final String qrToken;
  final DateTime initialExpiresAt;
  final VoidCallback onClose;
  final VoidCallback onExpired;

  const QRDialog({
    super.key,
    required this.qrToken,
    required this.initialExpiresAt,
    required this.onClose,
    required this.onExpired,
  });

  @override
  State<QRDialog> createState() => _QRDialogState();
}

class _QRDialogState extends State<QRDialog> {
  Timer? _pollingTimer;
  Timer? _countdownTimer;

  bool _isScanned = false;
  bool _isExpired = false;
  int _remainingSeconds = 600;
  DateTime? _currentExpiresAt;

  @override
  void initState() {
    super.initState();
    _currentExpiresAt = widget.initialExpiresAt;
    _startPolling();
  }

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isScanned || _isExpired) {
        timer.cancel();
        return;
      }
      try {
        final response = await ApiService.dio.get(
          '/license/check-scan-status',
          queryParameters: {'qrToken': widget.qrToken},
        );

        final scanned = response.data['scanned'] == true;
        final expiresAt = DateTime.parse(response.data['expiresAt']);

        if (mounted) {
          setState(() {
            _currentExpiresAt = expiresAt;
          });
        }

        if (scanned) {
          timer.cancel();
          _onQrScanned(expiresAt);
        }
      } catch (_) {}
    });
  }

  void _onQrScanned(DateTime newExpiresAt) {
    if (!mounted || _isScanned) return;

    final now = DateTime.now();
    int remaining = newExpiresAt.difference(now).inSeconds;
    if (remaining > 600) remaining = 600;
    if (remaining < 0) remaining = 0;

    setState(() {
      _isScanned = true;
      _remainingSeconds = remaining;
      _currentExpiresAt = newExpiresAt;
    });

    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _countdownTimer?.cancel();
        setState(() => _isExpired = true);
        widget.onExpired();
      }
    });
  }

  String get _formattedTime {
    int minutes = _remainingSeconds ~/ 60;
    int seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayExpiresAt = _currentExpiresAt ?? widget.initialExpiresAt;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.85,
            maxHeight: MediaQuery.of(context).size.height * 0.75,
          ),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withAlpha(60), Colors.white.withAlpha(30)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withAlpha(80), width: 1.0),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 25,
                  offset: const Offset(0, 10))
            ],
          ),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Show this to the Officer',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(140),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: Colors.white.withAlpha(80), width: 1.5),
                  ),
                  child: QrImageView(
                    data: widget.qrToken,
                    version: QrVersions.auto,
                    size: 200.0,
                  ),
                ),
                const SizedBox(height: 12),

                if (_isScanned && !_isExpired) ...[
                  Text(
                    'Valid for: $_formattedTime',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: _remainingSeconds < 30
                          ? Colors.redAccent
                          : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                ] else if (!_isScanned && !_isExpired) ...[

                  const Text(
                    'Valid for: 10:00',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],

                if (!_isExpired) ...[
                  Text(
                    'QR code will expire at ${_formatTime(displayExpiresAt)}',
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                ],

                // Scan නොවන තාක් "Waiting..." පෙන්වයි
                if (!_isScanned && !_isExpired) ...[
                  const Text(
                    'Waiting for officer to scan...',
                    style: TextStyle(
                      color: Colors.cyanAccent,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                // Scan වූ විට "Scanned" Status එක
                if (_isScanned && !_isExpired) ...[
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          color: Colors.greenAccent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'QR Code Scanned!',
                        style: TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],

                // Expired State
                if (_isExpired) ...[
                  const Icon(Icons.timer_off,
                      color: Colors.redAccent, size: 32),
                  const SizedBox(height: 4),
                  const Text(
                    'QR Code Expired',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Please generate a new QR code.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(25),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(color: Colors.white.withAlpha(40)),
                      ),
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      widget.onClose();
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Close',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
