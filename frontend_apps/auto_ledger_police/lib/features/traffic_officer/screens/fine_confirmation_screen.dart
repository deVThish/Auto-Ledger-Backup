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

  bool _isLoading = false;

  String get _sessionId {
    final token = widget.qrToken.trim();
    if (token.isNotEmpty) return token;
    return widget.license.scanToken.trim();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

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

  Future<bool> _confirmIssueFine() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: AppTheme.policeBlue.withValues(alpha: 0.18),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.policeBlue.withValues(alpha: 0.12),
                      blurRadius: 36,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 68,
                      decoration: BoxDecoration(
                        color: AppTheme.policeBlue,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.policeBlue.withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fact_check_outlined,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Issue Fine?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.policeBlue,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will submit the selected offenses and update the driver license status if needed.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 18),
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
                              foregroundColor: AppTheme.policeBlue,
                              side: BorderSide(
                                color: AppTheme.policeBlue.withValues(alpha: 0.25),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              minimumSize: const Size.fromHeight(48),
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
                              backgroundColor: AppTheme.policeBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              minimumSize: const Size.fromHeight(48),
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
    if (widget.selectedOffenses.isEmpty) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please select at least one offense.',
      );
      return;
    }

    final confirmed = await _confirmIssueFine();
    if (!confirmed) return;

    setState(() => _isLoading = true);

    try {
      await _trafficFineService.issueFine(
        sessionId: _sessionId,
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
      AppErrorHandler.showPopup(
        context,
        message: error.message,
      );
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
                color: AppTheme.policeBlue.withValues(alpha: 0.05),
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
            Icons.fact_check_outlined,
            color: Colors.white,
            size: 32,
          ),
          const SizedBox(height: 14),
          Text(
            widget.license.licenseNumber.isEmpty
                ? 'Confirm Fine'
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
          Text(
            widget.license.driverName.isEmpty
                ? 'Review selected offenses.'
                : widget.license.driverName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
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

  Widget _summaryCard() {
    return _glassCard(
      radius: 25,
      child: Column(
        children: [
          _InfoRow(
            title: 'Offenses Count',
            value: '${widget.selectedOffenses.length}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Total Penalty Points',
            value: '$_totalPoints',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Total Fine Amount',
            value: 'LKR ${_totalAmount.toStringAsFixed(2)}',
            valueColor: AppTheme.policeBlue,
          ),
        ],
      ),
    );
  }

  Widget _notesCard() {
    return _glassCard(
      radius: 22,
      padding: EdgeInsets.zero,
      child: TextField(
        controller: _commentController,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        style: const TextStyle(
          fontSize: 13,
          color: AppTheme.policeBlue,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: 'Add an optional officer note here...',
          hintStyle: const TextStyle(
            color: AppTheme.textGray,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: const Icon(
            Icons.edit_note_rounded,
            color: AppTheme.policeBlue,
            size: 22,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
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
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FBFF),
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Fine Confirmation',
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
              const SizedBox(height: 16),
              const Text(
                'Review Fine Details',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _summaryCard(),
              const SizedBox(height: 16),
              const Text(
                'Officer Notes',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _notesCard(),
              const SizedBox(height: 16),
              const Text(
                'Selected Offenses',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              _selectedOffensesList(),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _issueFine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.policeBlue,
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
                      : const Icon(Icons.receipt_long_outlined, size: 18),
                  label: Text(
                    _isLoading ? 'Issuing Fine...' : 'Issue Fine',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.title,
    required this.value,
    this.valueColor,
  });

  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? AppTheme.policeBlue,
              fontSize: 13,
              fontWeight: FontWeight.w800,
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
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: AppTheme.policeBlue.withValues(alpha: 0.12),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.policeBlue.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                offense.name.isEmpty ? 'Traffic Offense' : offense.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (offense.description.trim().isNotEmpty) ...[
                const SizedBox(height: 5),
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
                  _Chip(
                    label: '${offense.points} pts',
                    icon: Icons.bolt_rounded,
                  ),
                  _Chip(
                    label: 'LKR ${offense.amount.toStringAsFixed(2)}',
                    icon: Icons.payments_outlined,
                  ),
                  if (offense.isCourtCase)
                    const _Chip(
                      label: 'Court Case',
                      icon: Icons.gavel_rounded,
                      color: AppTheme.errorRed,
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
    this.color,
  });

  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppTheme.policeBlue;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.18),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: chipColor,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}