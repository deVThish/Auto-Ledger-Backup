import 'dart:ui';

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
  final _service = TrafficFineService();
  late Future<List<FineModel>> _future;
  List<FineModel> _cachedFines = [];

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<FineModel>> _load() async {
    final fines = await _service.getFineHistory();
    fines.sort((a, b) {
      final aDate = a.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.issuedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    _cachedFines = fines;
    return fines;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '-';
    final local = dateTime.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    return '${local.year}-$month-$day $displayHour:$minute $ampm';
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PAID':
        return AppTheme.successGreen;
      case 'PENDING':
        return Colors.orange;
      case 'OVERDUE':
        return AppTheme.errorRed;
      case 'COURT_CASE':
      case 'COURT':
      case 'REVOKED':
      case 'SUSPENDED':
        return AppTheme.errorRed;
      default:
        return AppTheme.textGray;
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
            color: color ?? Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.40),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Fine History',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppTheme.primaryBlack,
          onRefresh: _refresh,
          child: FutureBuilder<List<FineModel>>(
            future: _future,
            builder: (context, snapshot) {
              final fines = snapshot.data ?? _cachedFines;
              final isLoading =
                  snapshot.connectionState == ConnectionState.waiting &&
                      fines.isEmpty;

              if (isLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryBlack,
                  ),
                );
              }

              if (snapshot.hasError && fines.isEmpty) {
                final message = snapshot.error is ApiException
                    ? (snapshot.error as ApiException).message
                    : 'Unable to load fine history.';
                return _ErrorState(message: message, onRetry: _refresh);
              }

              if (fines.isEmpty) {
                return const _EmptyState();
              }

              return ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                itemCount: fines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final fine = fines[index];
                  return _FineHistoryCard(
                    fine: fine,
                    formatDate: _formatDate,
                    statusColor: _statusColor,
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _FineHistoryCard extends StatelessWidget {
  const _FineHistoryCard({
    required this.fine,
    required this.formatDate,
    required this.statusColor,
  });

  final FineModel fine;
  final String Function(DateTime? dateTime) formatDate;
  final Color Function(String status) statusColor;

  @override
  Widget build(BuildContext context) {
    final title = fine.offenseName.isEmpty ? 'Traffic Offense' : fine.offenseName;
    final color = statusColor(fine.status);
    final status = fine.status.isEmpty ? 'PENDING' : fine.status;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.40)),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.withValues(alpha: 0.20)),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Chip(label: 'License: ${fine.licenseNumber.isEmpty ? '-' : fine.licenseNumber}'),
              if (fine.officerName.trim().isNotEmpty)
                _Chip(label: 'Officer: ${fine.officerName}'),
              _Chip(label: 'Points: ${fine.points}'),
              _Chip(label: 'Amount: LKR ${fine.amount.toStringAsFixed(2)}'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetaRow(
                  title: 'Issued',
                  value: formatDate(fine.issuedAt),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetaRow(
                  title: 'Due Date',
                  value: formatDate(fine.dueDate),
                ),
              ),
            ],
          ),
          if (fine.officerBadgeNumber.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            _MetaRow(
              title: 'Badge Number',
              value: fine.officerBadgeNumber,
            ),
          ],
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? '-' : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppTheme.primaryBlack,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 120),
        Icon(
          Icons.receipt_long_outlined,
          size: 54,
          color: AppTheme.textGray,
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
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        const SizedBox(height: 120),
        const Icon(
          Icons.error_outline,
          size: 54,
          color: AppTheme.errorRed,
        ),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.errorRed,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: OutlinedButton.icon(
            onPressed: onRetry,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primaryBlack,
              side: const BorderSide(color: AppTheme.borderGray),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text(
              'Retry',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }
}