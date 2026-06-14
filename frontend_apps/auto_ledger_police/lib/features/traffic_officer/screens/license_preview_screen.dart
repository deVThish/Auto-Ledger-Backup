import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/fine_model.dart';
import '../../../models/license_model.dart';
import '../../../shared/widgets/app_button.dart';

class LicensePreviewScreen extends StatelessWidget {
  const LicensePreviewScreen({
    super.key,
    required this.qrToken,
    required this.license,
  });

  final String qrToken;
  final LicenseModel license;

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';

    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  Color _statusColor() {
    if (license.status == 'ACTIVE') {
      return AppTheme.successGreen;
    }

    if (license.status == 'REVOKED') {
      return AppTheme.errorRed;
    }

    return AppTheme.primaryBlack;
  }

  void _showNextStepMessage(BuildContext context) {
    AppErrorHandler.showPopup(
      context,
      message: 'Offense selection will be connected next.',
      isError: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'License Preview',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.credit_card_rounded,
                            color: Colors.white,
                            size: 34,
                          ),
                          const SizedBox(height: 18),
                          Text(
                            license.licenseNumber.isEmpty
                                ? 'License Verified'
                                : license.licenseNumber,
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
                            license.driverName.isEmpty
                                ? 'Driver details loaded from backend.'
                                : license.driverName,
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
                    ),
                    const SizedBox(height: 24),
                    _StatusCard(
                      status: license.status,
                      points: license.points,
                      statusColor: statusColor,
                    ),
                    const SizedBox(height: 14),
                    _LicenseInfoCard(
                      issueDate: _formatDate(license.issueDate),
                      expiryDate: _formatDate(license.expiryDate),
                      temporaryExpiry:
                      _formatDate(license.temporaryLicenseExpiry),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Recent Fine Activity',
                      style: TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (license.recentFines.isEmpty)
                      const _NoRecentFineCard()
                    else
                      ...license.recentFines.map(
                            (fine) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _RecentFineCard(fine: fine),
                        ),
                      ),
                    const SizedBox(height: 10),
                    AppButton(
                      text: 'Continue to Offenses',
                      icon: Icons.arrow_forward_rounded,
                      isLoading: false,
                      onPressed: () => _showNextStepMessage(context),
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.status,
    required this.points,
    required this.statusColor,
  });

  final String status;
  final int points;
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
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: statusColor),
            ),
            child: Icon(
              Icons.verified_user_outlined,
              color: statusColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status.isEmpty ? 'Unknown Status' : status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$points accumulated points',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LicenseInfoCard extends StatelessWidget {
  const _LicenseInfoCard({
    required this.issueDate,
    required this.expiryDate,
    required this.temporaryExpiry,
  });

  final String issueDate;
  final String expiryDate;
  final String temporaryExpiry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            title: 'Issue Date',
            value: issueDate,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.event_available_outlined,
            title: 'Expiry Date',
            value: expiryDate,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.timer_outlined,
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
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryBlack,
          size: 21,
        ),
        const SizedBox(width: 10),
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
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoRecentFineCard extends StatelessWidget {
  const _NoRecentFineCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
            size: 32,
          ),
          SizedBox(height: 10),
          Text(
            'No recent fines found',
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

class _RecentFineCard extends StatelessWidget {
  const _RecentFineCard({required this.fine});

  final FineModel fine;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fine.offenseName.isEmpty ? 'Traffic Offense' : fine.offenseName,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  fine.status,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                'LKR ${fine.amount.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppTheme.primaryBlack,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}