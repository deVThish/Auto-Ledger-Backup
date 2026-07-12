import 'package:auto_ledger_police/core/network/api_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../services/traffic_fine_service.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/liquid_nav_bar.dart';
import 'fine_history_screen.dart';
import 'profile_screen.dart';
import 'qr_scanner_screen.dart';
import 'settings_screen.dart';

class ToDashboardScreen extends StatefulWidget {
  const ToDashboardScreen({super.key});

  @override
  State<ToDashboardScreen> createState() => _ToDashboardScreenState();
}

class _ToDashboardScreenState extends State<ToDashboardScreen>
    with WidgetsBindingObserver {
  final _fineService = TrafficFineService();
  final _tokenStorage = const TokenStorage();

  bool _isLoading = true;
  bool _isFetching = false;
  String _officerName = 'Officer';
  String _badgeNumber = 'Traffic Officer';
  int _todayFines = 0;
  int _totalFines = 0;
  int _selectedNavIndex = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadDashboardData(showLoading: true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadDashboardData(showLoading: false);
    }
  }

  Future<void> _loadDashboardData({required bool showLoading}) async {
    if (_isFetching) return;
    _isFetching = true;

    if (showLoading && mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final session = await _tokenStorage.getSession();

      final allFines = await _fineService.getFineHistory();
      final sortedFines = List<dynamic>.from(allFines);

      sortedFines.sort((a, b) {
        final DateTime? aDate = a.issuedAt as DateTime?;
        final DateTime? bDate = b.issuedAt as DateTime?;

        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final todayCount = sortedFines.where((fine) {
        final issuedAt = fine.issuedAt;
        if (issuedAt == null) return false;
        final fineDate = DateTime(issuedAt.year, issuedAt.month, issuedAt.day);
        return fineDate == today;
      }).length;

      if (!mounted) return;

      setState(() {
        _officerName = session?.officerName ?? 'Officer';
        _badgeNumber = session?.officerBadgeNumber ?? 'Traffic Officer';
        _totalFines = sortedFines.length;
        _todayFines = todayCount;
      });
    } on ApiException catch (e) {
      if (mounted) {
        AppErrorHandler.showPopup(context, message: e.message);
      }
    } catch (_) {
      if (mounted) {
        AppErrorHandler.showPopup(
          context,
          message: 'Unable to load dashboard data. Please try again.',
        );
      }
    } finally {
      _isFetching = false;
      if (showLoading && mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openScanner() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (!mounted) return;
    await _loadDashboardData(showLoading: false);
  }

  Future<void> _openHistory() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FineHistoryScreen()),
    );
    if (!mounted) return;
    await _loadDashboardData(showLoading: false);
  }

  Future<void> _openProfile() async {
    if (!mounted) return;
    setState(() => _selectedNavIndex = 0);

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );

    if (!mounted) return;
    setState(() => _selectedNavIndex = 1);
    await _loadDashboardData(showLoading: false);
  }

  Future<void> _openSettings() async {
    if (!mounted) return;
    setState(() => _selectedNavIndex = 2);

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );

    if (!mounted) return;
    setState(() => _selectedNavIndex = 1);
    await _loadDashboardData(showLoading: false);
  }

  Future<void> _onNavTap(int index) async {
    if (index == 1) {
      if (mounted) {
        setState(() => _selectedNavIndex = 1);
      }
      return;
    }

    if (index == 0) {
      await _openProfile();
      return;
    }

    if (index == 2) {
      await _openSettings();
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F8FF),
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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final horizontalPadding = constraints.maxWidth < 380 ? 16.0 : 20.0;

                return SingleChildScrollView(
                  padding: EdgeInsets.only(
                    top: 20,
                    bottom: 14,
                    left: horizontalPadding,
                    right: horizontalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 34,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _DashboardHeader(),
                        const SizedBox(height: 14),
                        _WelcomeCard(
                          officerName: _officerName,
                          badgeNumber: _badgeNumber,
                        ),
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'Today\'s Overview'),
                        const SizedBox(height: 10),
                        DashboardStatsCard(
                          todayFines: _todayFines,
                          totalFines: _totalFines,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 18),
                        const _SectionTitle(title: 'Quick Actions'),
                        const SizedBox(height: 10),
                        _ToActionCard(
                          icon: Icons.qr_code_scanner_rounded,
                          title: 'Scan Driver QR',
                          subtitle: 'Scan and verify license',
                          onTap: _openScanner,
                        ),
                        const SizedBox(height: 12),
                        _ToActionCard(
                          icon: Icons.history_rounded,
                          title: 'Fine History',
                          subtitle: 'View issued fines',
                          onTap: _openHistory,
                        ),
                        const SizedBox(height: 18),
                        const _ShiftStatusCard(),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: LiquidNavBar(
          selectedIndex: _selectedNavIndex,
          onTap: (index) async {
            await _onNavTap(index);
          },
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppTheme.policeBlue,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: AppTheme.policeBlue.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_police_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Traffic Officer',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Secure field operations',
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.policeBlue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: AppTheme.policeBlue.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified_rounded,
                color: AppTheme.policeBlue,
                size: 16,
              ),
              SizedBox(width: 6),
              Text(
                'LIVE',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.policeBlue,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.1,
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard({
    required this.officerName,
    required this.badgeNumber,
  });

  final String officerName;
  final String badgeNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.policeBlue, AppTheme.policeBlueDark],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppTheme.policeBlue.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Welcome, $officerName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Keep the road safe with fast, secure operations.',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _InfoChip(
                icon: Icons.schedule_rounded,
                label: '08:00 AM - 04:00 PM',
                foreground: Colors.white,
                background: Colors.white.withValues(alpha: 0.12),
                border: Colors.white.withValues(alpha: 0.16),
              ),
              _InfoChip(
                icon: Icons.badge_rounded,
                label: 'Badge: $badgeNumber',
                foreground: Colors.white,
                background: Colors.white.withValues(alpha: 0.12),
                border: Colors.white.withValues(alpha: 0.16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: foreground, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToActionCard extends StatelessWidget {
  const _ToActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        splashColor: AppTheme.policeBlue.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFFE4EBF5),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.policeBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Icon(icon, color: AppTheme.policeBlue, size: 27),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.policeBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppTheme.textGray,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShiftStatusCard extends StatelessWidget {
  const _ShiftStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: const Color(0xFFE4EBF5),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: Colors.green.shade700,
              size: 27,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shift Status',
                  style: const TextStyle(
                    color: AppTheme.policeBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.circle_rounded,
                      color: Colors.green.shade500,
                      size: 10,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Active • On Duty',
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: Colors.green.shade200,
                width: 1,
              ),
            ),
            child: Text(
              'LIVE',
              style: TextStyle(
                color: Colors.green.shade700,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}