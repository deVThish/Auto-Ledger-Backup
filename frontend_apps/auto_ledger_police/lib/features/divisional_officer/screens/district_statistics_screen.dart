import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/fine_model.dart';
import '../services/fine_service.dart';

class DistrictStatisticsScreen extends StatefulWidget {
  const DistrictStatisticsScreen({super.key});

  @override
  State<DistrictStatisticsScreen> createState() =>
      _DistrictStatisticsScreenState();
}

class _DistrictStatisticsScreenState extends State<DistrictStatisticsScreen> {
  final _fineService = FineService();

  late Future<DistrictStatisticsModel> _statisticsFuture;
  DistrictStatisticsModel? _cachedStatistics;

  @override
  void initState() {
    super.initState();
    _statisticsFuture = _loadStatistics();
  }

  Future<DistrictStatisticsModel> _loadStatistics() async {
    final statistics = await _fineService.getDistrictStatistics();
    _cachedStatistics = statistics;
    return statistics;
  }

  Future<void> _refreshStatistics() async {
    setState(() {
      _statisticsFuture = _loadStatistics();
    });
    await _statisticsFuture;
  }

  String _formatRevenue(double value) {
    return 'LKR ${value.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'District Statistics',
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
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: FutureBuilder<DistrictStatisticsModel>(
                  future: _statisticsFuture,
                  builder: (context, snapshot) {
                    final snapshotData = snapshot.data;
                    final statistics = snapshotData ?? _cachedStatistics;
                    final isFirstLoad = snapshot.connectionState ==
                            ConnectionState.waiting &&
                        _cachedStatistics == null &&
                        snapshotData == null;

                    if (snapshot.hasError && statistics == null) {
                      return Column(
                        children: [
                          const SizedBox(height: 18),
                          const _HeaderCard(),
                          const SizedBox(height: 24),
                          _ErrorCard(
                            onRetry: _refreshStatistics,
                            message: snapshot.error is ApiException
                                ? (snapshot.error as ApiException).message
                                : 'Unable to load district statistics.',
                          ),
                        ],
                      );
                    }

                    final resolvedStatistics = statistics ??
                        const DistrictStatisticsModel(
                          totalOfficers: 0,
                          activeOfficersOnDuty: 0,
                          totalFinesIssued: 0,
                          totalRevenue: 0,
                          pendingFinesCount: 0,
                          overdueCourtCases: 0,
                        );

                    final cards = [
                      _StatisticCardData(
                        title: 'Total Officers',
                        value: '${resolvedStatistics.totalOfficers}',
                        subtitle: 'Registered officers',
                        icon: Icons.groups_outlined,
                      ),
                      _StatisticCardData(
                        title: 'On Duty Officers',
                        value: '${resolvedStatistics.activeOfficersOnDuty}',
                        subtitle: 'Currently active',
                        icon: Icons.local_police_outlined,
                      ),
                      _StatisticCardData(
                        title: 'Total Fines',
                        value: '${resolvedStatistics.totalFinesIssued}',
                        subtitle: 'Issued fines',
                        icon: Icons.receipt_long_outlined,
                      ),
                      _StatisticCardData(
                        title: 'Revenue',
                        value: _formatRevenue(resolvedStatistics.totalRevenue),
                        subtitle: 'Collected revenue',
                        icon: Icons.payments_outlined,
                      ),
                      _StatisticCardData(
                        title: 'Pending Fines',
                        value: '${resolvedStatistics.pendingFinesCount}',
                        subtitle: 'Awaiting payment',
                        icon: Icons.pending_actions_outlined,
                      ),
                      _StatisticCardData(
                        title: 'Court Cases',
                        value: '${resolvedStatistics.overdueCourtCases}',
                        subtitle: 'Overdue cases',
                        icon: Icons.gavel_outlined,
                      ),
                    ];

                    if (isFirstLoad) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          const _HeaderCard(),
                          const SizedBox(height: 24),
                          const Text(
                            'Key Statistics',
                            style: TextStyle(
                              color: AppTheme.primaryBlack,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ...cards.map(
                            (card) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _StatisticCard(data: card),
                            ),
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),
                        const _HeaderCard(),
                        const SizedBox(height: 24),
                        const Text(
                          'Key Statistics',
                          style: TextStyle(
                            color: AppTheme.primaryBlack,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 14),
                        ...cards.map(
                          (card) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _StatisticCard(data: card),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _StatisticCardData {
  const _StatisticCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryBlack,
            AppTheme.primaryBlack.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlack.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.bar_chart_rounded,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'District Overview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Performance overview',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
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
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({required this.data});

  final _StatisticCardData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: AppTheme.primaryBlack.withValues(alpha: 0.12),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.4),
            blurRadius: 30,
            offset: const Offset(-4, -4),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(4, 4),
            spreadRadius: -1,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.6),
              ),
            ),
            child: Icon(
              data.icon,
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
                  data.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
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
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.errorRed.withValues(alpha: 0.3)),
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