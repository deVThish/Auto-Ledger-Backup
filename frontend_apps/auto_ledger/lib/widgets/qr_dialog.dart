import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/api_service.dart';

class QRDialog extends StatefulWidget {
  final String qrToken;
  final DateTime expiresAt;
  final VoidCallback onClose;
  final VoidCallback onExpired;

  const QRDialog({
    super.key,
    required this.qrToken,
    required this.expiresAt,
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

  @override
  void initState() {
    super.initState();

    // QR Generate වෙලා කීයක් ගියත්, Open වෙනකොට ඉතුරු කාලය හොයාගන්න
    _remainingSeconds = widget.expiresAt.difference(DateTime.now()).inSeconds;
    if (_remainingSeconds > 600) _remainingSeconds = 600;
    if (_remainingSeconds < 0) {
      _isExpired = true;
      _remainingSeconds = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => widget.onExpired());
    } else {
      // Open වෙන ගමන් Countdown එක පටන් ගන්න
      _startCountdown();
      _startPolling();
    }
  }

  void _startCountdown() {
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

  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_isExpired || _isScanned) {
        timer.cancel();
        return;
      }
      try {
        final response = await ApiService.dio.get(
          '/license/check-scan-status',
          queryParameters: {'qrToken': widget.qrToken},
        );
        if (response.data['scanned'] == true) {
          timer.cancel();
          setState(() => _isScanned = true);
        }
      } catch (_) {}
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
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withAlpha(60), Colors.white.withAlpha(30)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withAlpha(80), width: 1.0),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withAlpha(30),
                  blurRadius: 25,
                  offset: const Offset(0, 10))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Show this to the Officer',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (_isExpired) ...[
                const Icon(Icons.timer_off, color: Colors.redAccent, size: 60),
                const SizedBox(height: 10),
                const Text('QR Code Expired',
                    style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                const Text('Please close and generate a new QR code.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center),
              ] else if (_isScanned) ...[
                const Icon(Icons.check_circle,
                    color: Colors.greenAccent, size: 60),
                const SizedBox(height: 10),
                const Text('QR Code Scanned!',
                    style: TextStyle(
                        color: Colors.greenAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(
                  'Officer has scanned your QR code.\nRemaining time: $_formattedTime',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ] else ...[
                // QR Code - ලොකු Size එක
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(140),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withAlpha(80), width: 1.5),
                  ),
                  child: QrImageView(
                    data: widget.qrToken,
                    version: QrVersions.auto,
                    size: 280.0,
                  ),
                ),
                const SizedBox(height: 20),
                // Timer - 10:00 ඉඳන් අඩු වෙනවා
                Text(
                  'Valid for: $_formattedTime',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: _remainingSeconds < 30
                        ? Colors.redAccent
                        : Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                // Expire Time - QR Generate වෙලා Fix වෙලා (Scan උනාට වෙනස් වෙන්නේ නැහැ)
                Text(
                  'QR code will expire at ${_formatTime(widget.expiresAt)}',
                  style: const TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Waiting for officer to scan...',
                  style: TextStyle(color: Colors.cyanAccent, fontSize: 13),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withAlpha(30),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                      side: BorderSide(color: Colors.white.withAlpha(40)),
                    ),
                  ),
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.onClose();
                    Navigator.pop(context);
                  },
                  child: const Text('Close',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
