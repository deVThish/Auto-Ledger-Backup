import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/license_model.dart';

class RevokedLicensesScreen extends StatefulWidget {
  const RevokedLicensesScreen({super.key});

  @override
  State<RevokedLicensesScreen> createState() => _RevokedLicensesScreenState();
}

class _RevokedLicensesScreenState extends State<RevokedLicensesScreen> {
  final ApiClient _apiClient = ApiClient();
  late Future<List<LicenseModel>> _revokedLicensesFuture;
  List<LicenseModel> _cachedLicenses = [];
  bool _isResolving = false;

  @override
  void initState() {
    super.initState();
    _revokedLicensesFuture = _loadRevokedLicenses();
  }

  Future<List<LicenseModel>> _loadRevokedLicenses() async {
    try {
      final response = await _apiClient.get(ApiConstants.revokedLicenses);
      return (response as List)
          .map((e) => LicenseModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _refreshLicenses() async {
    setState(() {
      _revokedLicensesFuture = _loadRevokedLicenses();
    });
    await _revokedLicensesFuture;
  }

  Future<void> _resolveLicense({
    required LicenseModel license,
    required String verdict,
  }) async {
    final isActive = verdict == 'ACTIVE';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 20),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.48),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 36,
                      offset: const Offset(0, 18),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 62,
                      height: 62,
                      decoration: BoxDecoration(
                        color: isActive
                            ? AppTheme.successGreen.withValues(alpha: 0.12)
                            : AppTheme.errorRed.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Icon(
                        isActive
                            ? Icons.check_circle_outline_rounded
                            : Icons.cancel_outlined,
                        color: isActive ? AppTheme.successGreen : AppTheme.errorRed,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isActive ? 'Activate License?' : 'Keep Revoked?',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isActive
                          ? 'This will reactivate the license and reset all points to 0.'
                          : 'This will keep the license revoked permanently.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryBlack,
                              side: const BorderSide(color: AppTheme.borderGray),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
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
                            onPressed: () => Navigator.pop(dialogContext, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isActive
                                  ? AppTheme.successGreen
                                  : AppTheme.errorRed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              isActive ? 'Activate' : 'Keep Revoked',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
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

    if (confirmed != true) return;

    setState(() => _isResolving = true);

    try {
      await _apiClient.patch(
        '${ApiConstants.resolveRevokedLicense}/$license.id/resolve-revoked',
        body: {'verdict': verdict},
      );

      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: isActive
            ? 'License activated successfully. Points reset to 0.'
            : 'License remains revoked.',
        isError: false,
      );

      await _refreshLicenses();
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
        message: 'Unable to resolve license. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isResolving = false);
      }
    }
  }

  String _formatDate(DateTime? dateTime) {
    if (dateTime == null) return '';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Revoked Licenses',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppTheme.primaryBlack,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshLicenses,
            icon: const Icon(
              Icons.refresh_rounded,
              color: AppTheme.primaryBlack,
            ),
          ),
        ],
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
                child: FutureBuilder<List<LicenseModel>>(
                  future: _revokedLicensesFuture,
                  builder: (context, snapshot) {
                    final snapshotData = snapshot.data;
                    final licenses = snapshotData ?? _cachedLicenses;
                    final isFirstLoad = snapshot.connectionState ==
                            ConnectionState.waiting &&
                        _cachedLicenses.isEmpty &&
                        snapshotData == null;

                    if (snapshot.hasError && licenses.isEmpty) {
                      return Column(
                        children: [
                          const SizedBox(height: 18),
                          _HeaderCard(),
                          const SizedBox(height: 24),
                          _ErrorCard(
                            onRetry: _refreshLicenses,
                            message: snapshot.error is ApiException
                                ? (snapshot.error as ApiException).message
                                : 'Unable to load revoked licenses.',
                          ),
                        ],
                      );
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 18),
                        _HeaderCard(),
                        const SizedBox(height: 24),
                        _HeaderStats(licenses: licenses),
                        const SizedBox(height: 14),
                        if (isFirstLoad)
                          const SizedBox.shrink()
                        else if (licenses.isEmpty)
                          const _EmptyCard()
                        else
                          ...licenses.map(
                            (license) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _RevokedLicenseCard(
                                license: license,
                                issuedDate: _formatDate(license.issueDate),
                                isResolving: _isResolving,
                                onActivate: () => _resolveLicense(
                                  license: license,
                                  verdict: 'ACTIVE',
                                ),
                                onRevoke: () => _resolveLicense(
                                  license: license,
                                  verdict: 'REVOKED',
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
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
          colors: const [
            Color(0xFF6B1A30),
            AppTheme.policeBlueDark,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppTheme.policeBlue.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(
            Icons.cancel_outlined,
            color: Colors.white,
            size: 34,
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Revoked Licenses',
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
                  'Review and resolve revoked licenses',
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

class _HeaderStats extends StatelessWidget {
  const _HeaderStats({required this.licenses});

  final List<LicenseModel> licenses;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Revoked List',
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.lightGray,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            '${licenses.length} Licenses',
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

class _RevokedLicenseCard extends StatelessWidget {
  const _RevokedLicenseCard({
    required this.license,
    required this.issuedDate,
    required this.isResolving,
    required this.onActivate,
    required this.onRevoke,
  });

  final LicenseModel license;
  final String issuedDate;
  final bool isResolving;
  final VoidCallback onActivate;
  final VoidCallback onRevoke;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppTheme.errorRed.withValues(alpha: 0.3),
                  ),
                ),
                child: const Icon(
                  Icons.cancel_outlined,
                  color: AppTheme.errorRed,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      license.licenseNumber.isEmpty
                          ? 'Unknown License'
                          : license.licenseNumber,
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
                      license.driverName.isEmpty
                          ? 'Unknown Driver'
                          : license.driverName,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.errorRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'REVOKED',
                  style: TextStyle(
                    color: AppTheme.errorRed,
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
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.scoreboard_outlined,
                  title: 'Points',
                  value: '${license.points} pts',
                  valueColor: AppTheme.errorRed,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  title: 'Issue Date',
                  value: issuedDate.isEmpty ? 'N/A' : issuedDate,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.info_outline,
                  title: 'Status',
                  value: license.status,
                  valueColor: AppTheme.errorRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isResolving ? null : onActivate,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successGreen,
                    disabledForegroundColor: AppTheme.textGray,
                    side: BorderSide(
                      color: isResolving
                          ? AppTheme.primaryBlack.withValues(alpha: 0.12)
                          : AppTheme.successGreen,
                    ),
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text(
                    'Activate',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isResolving ? null : onRevoke,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.errorRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primaryBlack.withValues(alpha: 0.12),
                    disabledForegroundColor: AppTheme.textGray,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text(
                    'Keep Revoked',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
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
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppTheme.primaryBlack,
          size: 20,
        ),
        const SizedBox(width: 10),
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: valueColor ?? AppTheme.primaryBlack,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
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

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppTheme.primaryBlack.withValues(alpha: 0.1)),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.check_circle_outline_rounded,
            color: AppTheme.primaryBlack,
            size: 34,
          ),
          SizedBox(height: 12),
          Text(
            'No revoked licenses',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.primaryBlack,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'All licenses are currently active.',
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