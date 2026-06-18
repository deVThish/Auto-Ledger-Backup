import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/license_model.dart';
import '../../../models/offense_model.dart';
import '../../../shared/widgets/app_button.dart';
import '../services/traffic_fine_service.dart';
import 'fine_confirmation_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _offensesFuture = _loadOffenses();
  }

  String _offenseKey(OffenseModel offense) {
    if (offense.id.trim().isNotEmpty) return offense.id.trim();
    return offense.code.trim();
  }

  Future<List<OffenseModel>> _loadOffenses() {
    return _trafficFineService.getOffenses();
  }

  Future<void> _refreshOffenses() async {
    setState(() {
      _offensesFuture = _loadOffenses();
    });

    await _offensesFuture;
  }

  void _toggleOffense(OffenseModel offense) {
    final key = _offenseKey(offense);
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
        .where((offense) => _selectedOffenseIds.contains(_offenseKey(offense)))
        .toList();
  }

  double _totalAmount(List<OffenseModel> offenses) {
    return offenses.fold<double>(0, (sum, offense) => sum + offense.amount);
  }

  int _totalPoints(List<OffenseModel> offenses) {
    return offenses.fold<int>(0, (sum, offense) => sum + offense.points);
  }

  void _openConfirmation(List<OffenseModel> offenses) {
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
          qrToken: widget.qrToken,
          license: widget.license,
          selectedOffenses: selectedOffenses,
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
          'Select Offenses',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshOffenses,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding =
                constraints.maxWidth < 380 ? 20.0 : 26.0;

            return RefreshIndicator(
              color: AppTheme.primaryBlack,
              onRefresh: _refreshOffenses,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: FutureBuilder<List<OffenseModel>>(
                    future: _offensesFuture,
                    builder: (context, snapshot) {
                      final isLoading =
                          snapshot.connectionState == ConnectionState.waiting;
                      final offenses = snapshot.data ?? <OffenseModel>[];
                      final selected = _selectedOffenses(offenses);

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 18),
                          _HeaderCard(license: widget.license),
                          const SizedBox(height: 24),
                          _SummaryCard(
                            selectedCount: selected.length,
                            totalAmount: _totalAmount(selected),
                            totalPoints: _totalPoints(selected),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Available Offenses',
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
                              onRetry: _refreshOffenses,
                              message: snapshot.error is ApiException
                                  ? (snapshot.error as ApiException).message
                                  : 'Unable to load offenses.',
                            )
                          else if (offenses.isEmpty)
                            const _EmptyCard()
                          else
                            ...offenses.map(
                              (offense) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _OffenseCard(
                                  offense: offense,
                                  isSelected: _selectedOffenseIds
                                      .contains(_offenseKey(offense)),
                                  onTap: () => _toggleOffense(offense),
                                ),
                              ),
                            ),
                          const SizedBox(height: 10),
                          AppButton(
                            text: 'Continue',
                            icon: Icons.arrow_forward_rounded,
                            isLoading: false,
                            onPressed: () => _openConfirmation(offenses),
                          ),
                          const SizedBox(height: 28),
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
  const _HeaderCard({required this.license});

  final LicenseModel license;

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
            Icons.receipt_long_outlined,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 18),
          Text(
            license.licenseNumber.isEmpty
                ? 'Select Traffic Offenses'
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
          const Text(
            'Choose one or more offenses before issuing the fine.',
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
    required this.selectedCount,
    required this.totalAmount,
    required this.totalPoints,
  });

  final int selectedCount;
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
      child: Row(
        children: [
          _SummaryItem(
            title: 'Selected',
            value: '$selectedCount',
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

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlack : AppTheme.borderGray,
              width: isSelected ? 1.5 : 1,
            ),
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
                  color:
                      isSelected ? AppTheme.primaryBlack : AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  isSelected
                      ? Icons.check_circle_outline
                      : Icons.warning_amber_rounded,
                  color: isSelected ? Colors.white : AppTheme.primaryBlack,
                  size: 25,
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
                        color: AppTheme.primaryBlack,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      code.isEmpty ? 'No code' : code,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MiniBadge(text: '${offense.points} pts'),
                        _MiniBadge(
                          text: 'LKR ${offense.amount.toStringAsFixed(2)}',
                        ),
                        if (offense.isCourtCase)
                          const _MiniBadge(text: 'Court Case'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppTheme.lightGray,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppTheme.primaryBlack,
          fontSize: 11,
          fontWeight: FontWeight.w800,
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
            Icons.warning_amber_rounded,
            color: AppTheme.primaryBlack,
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'No offenses found',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}