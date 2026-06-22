import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/fine_model.dart';
import '../../../shared/widgets/app_button.dart';
import 'qr_scanner_screen.dart';

class FineResultScreen extends StatelessWidget {
  const FineResultScreen({
    super.key,
    required this.result,
    required this.licenseNumber,
  });

  final FineIssueResultModel result;
  final String licenseNumber;

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  double get _totalAmount {
    return result.fineDetails.fold<double>(0, (sum, fine) => sum + fine.amount);
  }

  int get _totalPoints {
    return result.fineDetails.fold<int>(0, (sum, fine) => sum + fine.points);
  }

  void _goToDashboard(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.trafficOfficerDashboard,
      (route) => false,
    );
  }

  void _issueAnotherFine(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(),
      ),
    );
  }

  Color _statusColor() {
    final status = result.licenseStatus.toUpperCase();
    if (status == 'ACTIVE') return AppTheme.successGreen;
    if (status == 'SUSPENDED' || status == 'REVOKED') return AppTheme.errorRed;
    return AppTheme.primaryBlack;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Fine Result',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth < 380 ? 20.0 : 26.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 18),
                    _SuccessHeader(
                      licenseNumber: licenseNumber,
                    ),
                    const SizedBox(height: 24),
                    _ResultSummaryCard(
                      licenseStatus: result.licenseStatus,
                      accumulatedPoints: result.accumulatedPoints,
                      temporaryExpiry:
                          _formatDate(result.temporaryLicenseExpiry),
                      totalPoints: _totalPoints,
                      totalAmount: _totalAmount,
                      statusColor: statusColor,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Fine Details',
                      style: TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (result.fineDetails.isEmpty)
                      const _EmptyResultCard()
                    else
                      ...result.fineDetails.map(
                        (fine) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _FineDetailCard(fine: fine),
                        ),
                      ),
                    const SizedBox(height: 10),
                    AppButton(
                      text: 'Issue Another Fine',
                      icon: Icons.qr_code_scanner_rounded,
                      isLoading: false,
                      onPressed: () => _issueAnotherFine(context),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _goToDashboard(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlack,
                          side: const BorderSide(
                            color: AppTheme.primaryBlack,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: const Text(
                          'Back to Dashboard',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                          ),
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

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader({required this.licenseNumber});

  final String licenseNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlack,
            Color(0xFF31363F),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.check_circle_outline_rounded,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 18),
          const Text(
            'Fine Issued Successfully',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            licenseNumber.isEmpty ? 'The fine has been recorded.' : licenseNumber,
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
}

class _ResultSummaryCard extends StatelessWidget {
  const _ResultSummaryCard({
    required this.licenseStatus,
    required this.accumulatedPoints,
    required this.temporaryExpiry,
    required this.totalPoints,
    required this.totalAmount,
    required this.statusColor,
  });

  final String licenseStatus;
  final int accumulatedPoints;
  final String temporaryExpiry;
  final int totalPoints;
  final double totalAmount;
  final Color statusColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _InfoRow(
            title: 'License Status',
            value: licenseStatus.isEmpty ? '-' : licenseStatus,
            valueColor: statusColor,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            title: 'Accumulated Points',
            value: '$accumulatedPoints',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            title: 'Fine Points',
            value: '$totalPoints',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            title: 'Total Amount',
            value: 'LKR ${totalAmount.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            title: 'Temporary Expiry',
            value: temporaryExpiry,
          ),
        ],
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
            style: TextStyle(
              color: valueColor ?? AppTheme.primaryBlack,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _FineDetailCard extends StatelessWidget {
  const _FineDetailCard({required this.fine});

  final FineModel fine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.borderGray),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fine.offenseName.isEmpty ? 'Traffic Offense' : fine.offenseName,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            title: 'Status',
            value: fine.status,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Points',
            value: '${fine.points}',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            title: 'Amount',
            value: 'LKR ${fine.amount.toStringAsFixed(2)}',
          ),
        ],
      ),
    );
  }
}

class _EmptyResultCard extends StatelessWidget {
  const _EmptyResultCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppTheme.primaryBlack,
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'Fine issued, but no fine details returned',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}