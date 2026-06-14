import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/fine_model.dart';
import '../services/traffic_fine_service.dart';

class FineHistoryScreen extends StatefulWidget {
  const FineHistoryScreen({super.key});

  @override
  State<FineHistoryScreen> createState() => _FineHistoryScreenState();
}

class _FineHistoryScreenState extends State<FineHistoryScreen> {
  final _trafficFineService = TrafficFineService();

  late Future<List<FineModel>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = _loadHistory();
  }

  Future<List<FineModel>> _loadHistory() {
    return _trafficFineService.getFineHistory();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _historyFuture = _loadHistory();
    });

    await _historyFuture;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return '-';

    final date =
        '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';

    final hour = dateTime.hour > 12
        ? dateTime.hour - 12
        : dateTime.hour == 0
        ? 12
        : dateTime.hour;

    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';

    return '$date  $hour:$minute $period';
  }

  double _totalAmount(List<FineModel> fines) {
    return fines.fold<double>(
      0,
          (sum, fine) => sum + fine.amount,
    );
  }

  int _totalPoints(List<FineModel> fines) {
    return fines.fold<int>(
      0,
          (sum, fine) => sum + fine.points,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Fine History',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 20.0 : 26.0;

            return RefreshIndicator(
              color: AppTheme.primaryBlack,
              onRefresh: _refreshHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: FutureBuilder<List<FineModel>>(
                    future: _historyFuture,
                    builder: (context, snapshot) {
                      final isLoading =
                          snapshot.connectionState == ConnectionState.waiting;
                      final fines = snapshot.data ?? <FineModel>[];

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          const _HeaderCard(),
                          const SizedBox(height: 24),
                          _SummaryCard(
                            fineCount: fines.length,
                            totalPoints: _totalPoints(fines),
                            totalAmount: _totalAmount(fines),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Today Issued Fines',
                            style: TextStyle(
                              color: AppTheme.primaryBlack,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          if (isLoading)
                            const _LoadingCard()
                          else if (snapshot.hasError)
                            _ErrorCard(
                              onRetry: _refreshHistory,
                              message: snapshot.error is ApiException
                                  ? (snapshot.error as ApiException).message
                                  : 'Unable to load fine history.',
                            )
                          else if (fines.isEmpty)
                              const _EmptyCard()
                            else
                              ...fines.map(
                                    (fine) => Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _FineHistoryCard(
                                    fine: fine,
                                    issuedAt: _formatDateTime(fine.issuedAt),
                                  ),
                                ),
                              ),
                          const SizedBox(height: 18),
                        ],
                      );
                    },
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

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Icons.history_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(height: 18),
          Text(
            'Fine History',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'View fines issued by you today and review recent fine activity.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.fineCount,
    required this.totalPoints,
    required this.totalAmount,
  });

  final int fineCount;
  final int totalPoints;
  final double totalAmount;

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
      child: Row(
        children: [
          _SummaryItem(
            title: 'Fines',
            value: '$fineCount',
          ),
          const SizedBox(width: 10),
          _SummaryItem(
            title: 'Points',
            value: '$totalPoints',
          ),
          const SizedBox(width: 10),
          _SummaryItem(
            title: 'Amount',
            value: 'LKR ${totalAmount.toStringAsFixed(2)}',
          ),
        ],
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
              color: AppTheme.primaryBlack,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FineHistoryCard extends StatelessWidget {
  const _FineHistoryCard({
    required this.fine,
    required this.issuedAt,
  });

  final FineModel fine;
  final String issuedAt;

  Color _statusColor() {
    if (fine.status == 'PAID') {
      return AppTheme.successGreen;
    }

    if (fine.status == 'OVERDUE' ||
        fine.status == 'COURT_CASE' ||
        fine.status == 'RESOLVED') {
      return AppTheme.errorRed;
    }

    return AppTheme.primaryBlack;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor();
    final licenseNumber =
    fine.licenseNumber.isEmpty ? 'Unknown License' : fine.licenseNumber;
    final offenseName =
    fine.offenseName.isEmpty ? 'Traffic Offense' : fine.offenseName;

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
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color: AppTheme.primaryBlack,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      licenseNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      issuedAt,
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
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  fine.status.isEmpty ? '-' : fine.status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.lightGray,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                _InfoRow(
                  title: 'Offenses',
                  value: offenseName,
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
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value.isEmpty ? '-' : value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.borderGray),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppTheme.primaryBlack,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({
    required this.onRetry,
    required this.message,
  });

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.errorRed),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppTheme.errorRed,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.errorRed,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.errorRed,
              side: const BorderSide(color: AppTheme.errorRed),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Retry',
              style: TextStyle(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

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
            Icons.history_rounded,
            color: AppTheme.primaryBlack,
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'No fine history found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Fines issued by you today will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}