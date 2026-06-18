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
    _cachedFines = fines;
    return fines;
  }

  Future<void> _refresh() async {
    setState(() {
      _future = _load();
    });
    await _future;
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
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                itemCount: fines.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final fine = fines[index];
                  return _FineHistoryCard(fine: fine);
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
  const _FineHistoryCard({required this.fine});

  final FineModel fine;

  @override
  Widget build(BuildContext context) {
    final title = fine.offenseName.isEmpty ? 'Traffic Offense' : fine.offenseName;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
            title,
            style: const TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Status: ${fine.status}',
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Amount: LKR ${fine.amount.toStringAsFixed(2)}',
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Points: ${fine.points}',
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (fine.issuedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Issued: ${fine.issuedAt!.toLocal()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textGray,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
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