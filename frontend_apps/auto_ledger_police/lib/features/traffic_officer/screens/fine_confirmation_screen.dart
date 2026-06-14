import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/license_model.dart';
import '../../../models/offense_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../services/traffic_fine_service.dart';
import 'fine_result_screen.dart';

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
  final _tokenStorage = const TokenStorage();

  bool _isLoading = false;

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
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          title: const Text(
            'Issue Fine?',
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'This will issue the selected offenses to this driver license.',
            style: TextStyle(
              color: AppTheme.textGray,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryBlack,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                'Issue Fine',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    return confirmed == true;
  }

  Future<void> _issueFine() async {
    final confirmed = await _confirmIssueFine();

    if (!confirmed) return;

    final session = await _tokenStorage.getSession();

    if (!mounted) return;

    if (session == null) {
      AppErrorHandler.showPopup(
        context,
        message: 'Session expired. Please login again.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await _trafficFineService.issueFine(
        qrToken: widget.qrToken,
        offenseCodes: widget.selectedOffenses
            .map((offense) => offense.code)
            .where((code) => code.trim().isNotEmpty)
            .toList(),
        officerId: session.officerId,
      );

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => FineResultScreen(
            result: result,
            licenseNumber: widget.license.licenseNumber,
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
        message: 'Unable to issue fine. Please try again.',
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
          'Fine Confirmation',
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
                    _HeaderCard(
                      licenseNumber: widget.license.licenseNumber,
                      driverName: widget.license.driverName,
                    ),
                    const SizedBox(height: 24),
                    _SummaryCard(
                      offenseCount: widget.selectedOffenses.length,
                      totalAmount: _totalAmount,
                      totalPoints: _totalPoints,
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Selected Offenses',
                      style: TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...widget.selectedOffenses.map(
                          (offense) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _SelectedOffenseCard(offense: offense),
                      ),
                    ),
                    const SizedBox(height: 10),
                    AppButton(
                      text: 'Issue Fine',
                      icon: Icons.receipt_long_outlined,
                      isLoading: _isLoading,
                      onPressed: _issueFine,
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.licenseNumber,
    required this.driverName,
  });

  final String licenseNumber;
  final String driverName;

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Icons.fact_check_outlined,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 18),
          Text(
            licenseNumber.isEmpty ? 'Confirm Fine' : licenseNumber,
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
            driverName.isEmpty ? 'Review selected offenses.' : driverName,
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.offenseCount,
    required this.totalAmount,
    required this.totalPoints,
  });

  final int offenseCount;
  final double totalAmount;
  final int totalPoints;

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
            title: 'Offenses',
            value: '$offenseCount',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            title: 'Total Points',
            value: '$totalPoints',
          ),
          const SizedBox(height: 12),
          _InfoRow(
            title: 'Total Amount',
            value: 'LKR ${totalAmount.toStringAsFixed(2)}',
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppTheme.primaryBlack,
              size: 25,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  offense.name.isEmpty ? 'Traffic Offense' : offense.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${offense.points} points • LKR ${offense.amount.toStringAsFixed(2)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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