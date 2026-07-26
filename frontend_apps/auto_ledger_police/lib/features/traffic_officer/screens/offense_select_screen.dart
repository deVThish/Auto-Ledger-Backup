import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/license_model.dart';
import '../../../models/offense_model.dart';
import '../services/traffic_fine_service.dart';
import 'fine_confirmation_screen.dart';
import 'qr_scanner_screen.dart';

class OffenseSelectScreen extends StatefulWidget {
  const OffenseSelectScreen({
    super.key,
    required this.qrToken,
    required this.license,
  });

  final String qrToken;
  final LicenseModel license;

  @override
  State<OffenseSelectScreen> createState() => _OffenseSelectScreenState();
}

class _OffenseSelectScreenState extends State<OffenseSelectScreen> {
  final _trafficFineService = TrafficFineService();
  final Set<String> _selectedOffenseIds = <String>{};

  late Future<List<OffenseModel>> _offensesFuture;
  Timer? _timer;
  late final DateTime _expiresAt;
  Duration _remaining = Duration.zero;
  bool _expiredDialogShown = false;

  String get _sessionToken {
    final token = widget.qrToken.trim();
    if (token.isNotEmpty) return token;
    return widget.license.scanToken.trim();
  }

  @override
  void initState() {
    super.initState();

    _offensesFuture = _loadOffenses();

    final expiresAt = widget.license.scanExpiresAt;

    if (expiresAt == null) {
      _expiresAt = DateTime.now().add(const Duration(minutes: 5));
      _remaining = const Duration(minutes: 5);
      _expiredDialogShown = false;

      _timer = Timer.periodic(
        const Duration(seconds: 1),
        (_) => _updateRemaining(),
      );
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

  Future<void> _showExpiredDialog() async {
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.38),
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
                  color: Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(34),
                  border: Border.all(
                    color: AppTheme.policeBlue.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.policeBlue.withValues(alpha: 0.12),
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
                        color: AppTheme.errorRed.withValues(alpha: 0.12),
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
                        color: AppTheme.policeBlue,
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
                          backgroundColor: AppTheme.policeBlue,
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

  Future<List<OffenseModel>> _loadOffenses() async {
    final offenses = await _trafficFineService.getOffenses();
    offenses.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return offenses;
  }

  void _toggleOffense(OffenseModel offense) {
    final key = offense.id.trim().isNotEmpty ? offense.id.trim() : offense.code.trim();
    if (key.isEmpty) return;

    setState(() {
      if (_selectedOffenseIds.contains(key)) {
        _selectedOffenseIds.remove(key);
      } else {
        _selectedOffenseIds.add(key);
      }
    });
  }

  List<OffenseModel> _selectedOffenses(List<OffenseModel> offenses) {
    return offenses
        .where((offense) {
          final key =
              offense.id.trim().isNotEmpty ? offense.id.trim() : offense.code.trim();
          return _selectedOffenseIds.contains(key);
        })
        .toList();
  }

  double _totalAmount(List<OffenseModel> offenses) {
    return offenses.fold<double>(0, (sum, offense) => sum + offense.amount);
  }

  int _totalPoints(List<OffenseModel> offenses) {
    return offenses.fold<int>(0, (sum, offense) => sum + offense.points);
  }

  void _openConfirmation(List<OffenseModel> offenses) {
    if (_remaining == Duration.zero) {
      _showExpiredDialog();
      return;
    }

    final criticalStatus = widget.license.status.toUpperCase();
    if (criticalStatus == 'SUSPENDED' || criticalStatus == 'REVOKED') {
      AppErrorHandler.showPopup(
        context,
        message: 'Suspended and revoked licenses cannot proceed to fines.',
      );
      return;
    }

    final selectedOffenses = _selectedOffenses(offenses);

    if (selectedOffenses.isEmpty) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please select at least one offense.',
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FineConfirmationScreen(
          qrToken: _sessionToken,
          license: widget.license,
          selectedOffenses: selectedOffenses,
        ),
      ),
    );
  }

  Widget _glassCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = 25,
    Color? color,
    Color? borderColor,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: padding,
          decoration: BoxDecoration(
            color: color ?? Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? AppTheme.policeBlue.withValues(alpha: 0.12),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.policeBlue.withValues(alpha: 0.04),
                blurRadius: 14,
                offset: const Offset(0, 5),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _remaining == Duration.zero
                  ? Icons.timer_off_rounded
                  : Icons.timer_outlined,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _remaining == Duration.zero
                      ? 'Scan session expired'
                      : 'Scan session active',
                  style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _remaining == Duration.zero
                      ? 'Please scan the QR code again.'
                      : 'Time remaining: ${_formatCountdown(_remaining)}',
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 11.5,
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.policeBlue,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: AppTheme.policeBlue.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 14),
          Text(
            widget.license.licenseNumber.isEmpty
                ? 'Select Traffic Offenses'
                : widget.license.licenseNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Choose one or more offenses before issuing the fine.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(List<OffenseModel> selected) {
    return _glassCard(
      radius: 25,
      child: Row(
        children: [
          _SummaryItem(
            title: 'Selected',
            value: '${selected.length}',
          ),
          const SizedBox(width: 10),
          _SummaryItem(
            title: 'Points',
            value: '${_totalPoints(selected)}',
          ),
          const SizedBox(width: 10),
          _SummaryItem(
            title: 'Amount',
            value: 'LKR ${_totalAmount(selected).toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }

  List<Widget> _buildOffenseCards(List<OffenseModel> offenses) {
    return offenses.map((offense) {
      final offenseId = offense.id.trim().isNotEmpty
          ? offense.id.trim()
          : offense.code.trim();
      final isSelected = _selectedOffenseIds.contains(offenseId);
      return _OffenseCard(
        offense: offense,
        isSelected: isSelected,
        onTap: () => _toggleOffense(offense),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FBFF),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Select Offenses',
          style: TextStyle(
            color: AppTheme.policeBlue,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Container(
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              _headerCard(),
              const SizedBox(height: 12),
              _scanTimerBanner(),
              const SizedBox(height: 12),
              FutureBuilder<List<OffenseModel>>(
                future: _offensesFuture,
                builder: (context, snapshot) {
                  final isLoading =
                      snapshot.connectionState == ConnectionState.waiting;
                  final offenses = snapshot.data ?? <OffenseModel>[];
                  final selected = _selectedOffenses(offenses);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _summaryCard(selected),
                      const SizedBox(height: 18),
                      const Text(
                        'Available Offenses',
                        style: TextStyle(
                          color: AppTheme.policeBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (isLoading)
                        const _LoadingCard()
                      else if (snapshot.hasError)
                        _glassCard(
                          radius: 25,
                          color: Colors.white.withValues(alpha: 0.88),
                          borderColor: AppTheme.errorRed.withValues(alpha: 0.35),
                          child: _ErrorCard(
                            message: snapshot.error is ApiException
                                ? (snapshot.error as ApiException).message
                                : 'Unable to load offenses.',
                          ),
                        )
                      else if (offenses.isEmpty)
                        _glassCard(
                          radius: 25,
                          child: const _EmptyCard(),
                        )
                      else
                        ..._buildOffenseCards(offenses),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: _remaining == Duration.zero
                              ? _showExpiredDialog
                              : () => _openConfirmation(offenses),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.policeBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: const Text(
                            'Continue',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.policeBlue,
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OffenseCard extends StatelessWidget {
  const _OffenseCard({
    required this.offense,
    required this.isSelected,
    required this.onTap,
  });

  final OffenseModel offense;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = offense.name.isEmpty ? 'Traffic Offense' : offense.name;
    final code = offense.code.isEmpty ? offense.id : offense.code;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.policeBlue.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.policeBlue
                        : AppTheme.policeBlue.withValues(alpha: 0.12),
                    width: isSelected ? 1.8 : 1.1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.policeBlue.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.policeBlue
                            : AppTheme.policeBlue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.warning_amber_rounded,
                        color: isSelected ? Colors.white : AppTheme.policeBlue,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppTheme.policeBlue,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            code.isEmpty ? 'No code' : 'Code: $code',
                            style: const TextStyle(
                              color: AppTheme.textGray,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
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
                                fontSize: 11.5,
                                height: 1.3,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              _MiniBadge(text: '${offense.points} pts'),
                              _MiniBadge(
                                text: 'LKR ${offense.amount.toStringAsFixed(2)}',
                              ),
                              if (offense.isCourtCase)
                                const _MiniBadge(
                                  text: 'Court Case',
                                  color: AppTheme.errorRed,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({
    required this.text,
    this.color,
  });

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppTheme.policeBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: badgeColor,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppTheme.policeBlue.withValues(alpha: 0.12),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.policeBlue,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(
          Icons.error_outline_rounded,
          color: AppTheme.errorRed,
          size: 32,
        ),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.errorRed,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          color: AppTheme.policeBlue,
          size: 32,
        ),
        SizedBox(height: 10),
        Text(
          'No offenses found',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppTheme.policeBlue,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}