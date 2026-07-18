import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/license_model.dart';
import '../../../models/offense_model.dart';
import '../services/traffic_fine_service.dart';
import 'qr_scanner_screen.dart';
import 'to_dashboard_screen.dart';

class FineConfirmationScreen extends StatefulWidget {
  const FineConfirmationScreen({
    super.key,
    required this.qrToken,
    required this.license,
    required this.selectedOffenses,
  });

  final String qrToken;
  final LicenseModel license;
  final List<OffenseModel> selectedOffenses;

  @override
  State<FineConfirmationScreen> createState() => _FineConfirmationScreenState();
}

class _FineConfirmationScreenState extends State<FineConfirmationScreen> {
  final _trafficFineService = TrafficFineService();
  final _commentController = TextEditingController();

  Timer? _timer;
  late final DateTime _expiresAt;
  Duration _remaining = Duration.zero;
  bool _expiredDialogShown = false;
  bool _isLoading = false;

  String get _sessionToken {
    final token = widget.qrToken.trim();
    if (token.isNotEmpty) return token;
    return widget.license.scanToken.trim();
  }

  @override
  void initState() {
    super.initState();

    final expiresAt = widget.license.scanExpiresAt;

    if (expiresAt == null) {
      _expiresAt = DateTime.now();
      _remaining = Duration.zero;
      _expiredDialogShown = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showExpiredDialog();
        }
      });
    } else {
      _expiresAt = expiresAt;
      _remaining = _expiresAt.difference(DateTime.now());
      _updateRemaining();

      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateRemaining(),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _commentController.dispose();
    super.dispose();
  }

  void _updateRemaining() {
    if (!mounted) return;

    final remaining = _expiresAt.difference(DateTime.now());
    final safeRemaining =
        remaining.isNegative ? Duration.zero : remaining;

    setState(() {
      _remaining = safeRemaining;
    });

    if (safeRemaining == Duration.zero && !_expiredDialogShown) {
      _expiredDialogShown = true;
      _timer?.cancel();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showExpiredDialog();
        }
      });
    }
  }

  String _formatCountdown(Duration duration) {
    final seconds = duration.inSeconds.clamp(0, 99999);
    final minutes = seconds ~/ 60;
    final remSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remSeconds.toString().padLeft(2, '0')}';
  }

  Color _timerColor() {
    if (_remaining == Duration.zero) return AppTheme.errorRed;
    if (_remaining.inSeconds <= 30) return Colors.orange;
    return AppTheme.successGreen;
  }

  bool get _isExpired => _remaining == Duration.zero;

  String _offenseKey(OffenseModel offense) {
    if (offense.id.trim().isNotEmpty) return offense.id.trim();
    return offense.code.trim();
  }

  double get _totalAmount {
    return widget.selectedOffenses.fold<double>(
      0,
      (sum, offense) => sum + offense.amount,
    );
  }

  int get _totalPoints {
    return widget.selectedOffenses.fold<int>(
      0,
      (sum, offense) => sum + offense.points,
    );
  }

  Future<void> _showExpiredDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.38),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.60),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.timer_off_rounded,
                        color: AppTheme.errorRed,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Session Expired',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This QR verification window has expired. Scan the QR code again.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const QrScannerScreen(),
                            ),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlack,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          'Scan Again',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<bool> _confirmIssueFine() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.25),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.60),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 40,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlack.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(
                        Icons.fact_check_outlined,
                        color: Colors.white,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Issue Fine?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will submit the selected offenses and update the driver license status if needed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Chip(
                          label: '${widget.selectedOffenses.length} Offenses',
                          icon: Icons.receipt_long_outlined,
                        ),
                        _Chip(
                          label: '$_totalPoints Points',
                          icon: Icons.bolt_rounded,
                        ),
                        _Chip(
                          label: 'LKR ${_totalAmount.toStringAsFixed(2)}',
                          icon: Icons.payments_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryBlack,
                              side: const BorderSide(color: AppTheme.borderGray),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryBlack,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              minimumSize: const Size.fromHeight(50),
                            ),
                            child: const Text(
                              'Issue Fine',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _issueFine() async {
    if (_isExpired) {
      _showExpiredDialog();
      return;
    }

    if (widget.selectedOffenses.isEmpty) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please select at least one offense.',
      );
      return;
    }

    final confirmed = await _confirmIssueFine();
    if (!confirmed) return;

    if (_isExpired) {
      _showExpiredDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _trafficFineService.issueFine(
        scanToken: _sessionToken,
        licenseId: widget.license.id.trim().isEmpty
            ? null
            : widget.license.id.trim(),
        offenseIds: widget.selectedOffenses
            .map(_offenseKey)
            .where((id) => id.isNotEmpty)
            .toList(),
        comment: _commentController.text.trim(),
        license: widget.license,
        selectedOffenses: widget.selectedOffenses,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const ToDashboardScreen(),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      final message = error.message.toLowerCase();
      if (message.contains('expired') || message.contains('session')) {
        await _showExpiredDialog();
      } else {
        AppErrorHandler.showPopup(
          context,
          message: error.message,
        );
      }
    } catch (_) {
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to issue fine. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
    double radius = 28,
    Color? color,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withOpacity(0.38),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _scanTimerBanner() {
    final color = _timerColor();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _isExpired ? Icons.timer_off_rounded : Icons.timer_outlined,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isExpired ? 'Scan session expired' : 'Scan session active',
                  style: TextStyle(
                    color: color,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isExpired
                      ? 'Please scan the QR code again.'
                      : 'Time remaining: ${_formatCountdown(_remaining)}',
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return _glassCard(
      radius: 32,
      color: AppTheme.primaryBlack.withOpacity(0.96),
      borderColor: Colors.white.withOpacity(0.14),
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.fact_check_outlined,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 18),
          Text(
            widget.license.licenseNumber.isEmpty
                ? 'Confirm Fine'
                : widget.license.licenseNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.license.driverName.isEmpty
                ? 'Review selected offenses.'
                : widget.license.driverName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return _glassCard(
      radius: 30,
      child: Column(
        children: [
          _InfoRow(title: 'Offenses', value: '${widget.selectedOffenses.length}'),
          const SizedBox(height: 12),
          _InfoRow(title: 'Total Points', value: '$_totalPoints'),
          const SizedBox(height: 12),
          _InfoRow(
            title: 'Total Amount',
            value: 'LKR ${_totalAmount.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  Widget _notesCard() {
    return _glassCard(
      radius: 30,
      padding: EdgeInsets.zero,
      child: TextField(
        controller: _commentController,
        maxLines: 4,
        textInputAction: TextInputAction.newline,
        decoration: const InputDecoration(
          hintText: 'Optional note for this fine',
          prefixIcon: Icon(Icons.edit_note_rounded),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(18),
        ),
      ),
    );
  }

  Widget _selectedOffensesList() {
    return Column(
      children: widget.selectedOffenses
          .map(
            (offense) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _SelectedOffenseCard(offense: offense),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Fine Confirmation',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth < 380 ? 16.0 : 20.0;

            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF8FBFF),
                    Color(0xFFF1F6FF),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 18,
                  bottom: 24,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _headerCard(),
                      const SizedBox(height: 14),
                      _scanTimerBanner(),
                      const SizedBox(height: 14),
                      _summaryCard(),
                      const SizedBox(height: 18),
                      const Text(
                        'Officer Notes',
                        style: TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _notesCard(),
                      const SizedBox(height: 18),
                      const Text(
                        'Selected Offenses',
                        style: TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _selectedOffensesList(),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: (_isLoading || _isExpired)
                              ? (_isExpired ? _showExpiredDialog : null)
                              : _issueFine,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlack,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.receipt_long_outlined, size: 20),
                          label: Text(
                            _isLoading ? 'Issuing Fine...' : 'Issue Fine',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectedOffenseCard extends StatelessWidget {
  const _SelectedOffenseCard({required this.offense});

  final OffenseModel offense;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.88),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.40)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offense.name.isEmpty ? 'Traffic Offense' : offense.name,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.primaryBlack,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (offense.description.trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  offense.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _Chip(label: '${offense.points} pts', icon: Icons.bolt_rounded),
                  _Chip(
                    label: 'LKR ${offense.amount.toStringAsFixed(2)}',
                    icon: Icons.payments_outlined,
                  ),
                  if (offense.isCourtCase)
                    const _Chip(
                      label: 'Court Case',
                      icon: Icons.gavel_rounded,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryBlack),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}