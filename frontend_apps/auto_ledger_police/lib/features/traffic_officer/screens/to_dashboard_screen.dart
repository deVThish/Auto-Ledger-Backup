import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/dashboard_stats_card.dart';
import '../widgets/recent_fine_card.dart';
import '../widgets/liquid_nav_bar.dart';
import 'qr_scanner_screen.dart';
import 'fine_history_screen.dart';
import 'profile_screen.dart';
import '../services/traffic_fine_service.dart';

class ToDashboardScreen extends StatefulWidget {
  const ToDashboardScreen({super.key});

  @override
  State<ToDashboardScreen> createState() => _ToDashboardScreenState();
}

class _ToDashboardScreenState extends State<ToDashboardScreen> {
  final _fineService = TrafficFineService();
  final _tokenStorage = const TokenStorage();

  bool _isLoading = true;
  String _officerName = 'Officer';
  String _badgeNumber = 'Traffic Officer';
  int _todayFines = 0;
  int _totalFines = 0;
  List<dynamic> _recentFines = [];
  int _selectedNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final session = await _tokenStorage.getSession();
      if (session != null) {
        _officerName = session.officerName;
        _badgeNumber = session.officerBadgeNumber;
      }

      final allFines = await _fineService.getFineHistory();
      _totalFines = allFines.length;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      _todayFines = allFines.where((fine) {
        final issuedAt = fine.issuedAt;
        if (issuedAt == null) return false;
        final fineDate = DateTime(issuedAt.year, issuedAt.month, issuedAt.day);
        return fineDate == today;
      }).length;

      _recentFines = allFines.take(2).toList();
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
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onNavTap(int index) {
    setState(() => _selectedNavIndex = index);

    switch (index) {
      case 0:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProfileScreen()),
        ).then((_) {
          if (mounted) setState(() => _selectedNavIndex = 1);
        });
        break;
      case 1:
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const FineHistoryScreen()),
        ).then((_) {
          if (mounted) setState(() => _selectedNavIndex = 1);
        });
        break;
    }
  }

  void _openScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
  }

  void _openHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FineHistoryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F6FF),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = constraints.maxWidth < 380 ? 16.0 : 20.0;

            return RefreshIndicator(
              color: AppTheme.policeBlue,
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  top: 26,
                  bottom: 12,
                  left: horizontalPadding,
                  right: horizontalPadding,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight - 80,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DashboardHeader(),
                      const SizedBox(height: 12),
                      _WelcomeCard(
                        officerName: _officerName,
                        badgeNumber: _badgeNumber,
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Today\'s Overview',
                        style: TextStyle(
                          color: AppTheme.policeBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: DashboardStatsCard(
                          todayFines: _todayFines,
                          totalFines: _totalFines,
                          isLoading: _isLoading,
                        ),
                      ),
                      const SizedBox(height: 15),
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          color: AppTheme.policeBlue,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ToActionCard(
                        icon: Icons.qr_code_scanner_rounded,
                        title: 'Scan Driver QR',
                        subtitle: 'Scan and verify license',
                        onTap: () => _openScanner(context),
                      ),
                      const SizedBox(height: 10),
                      _ToActionCard(
                        icon: Icons.history_rounded,
                        title: 'Fine History',
                        subtitle: 'View issued fines',
                        onTap: () => _openHistory(context),
                      ),
                      const SizedBox(height: 14),
                      _ShiftStatusCard(),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: LiquidNavBar(
        selectedIndex: _selectedNavIndex,
        onTap: _onNavTap,
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
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: AppTheme.policeBlue,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppTheme.policeBlue.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.local_police_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Traffic Officer',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 1),
              Text(
                'Secure field operations',
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.policeBlue, AppTheme.policeBlueDark],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.policeBlue.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
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
          const SizedBox(height: 4),
          Text(
            '🕐 08:00 AM - 04:00 PM',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Badge: $badgeNumber',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w400,
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
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.policeBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: AppTheme.policeBlue, size: 26),
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
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
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.grey.shade200,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: Colors.green.shade700,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shift Status',
                  style: TextStyle(
                    color: AppTheme.policeBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
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
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
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