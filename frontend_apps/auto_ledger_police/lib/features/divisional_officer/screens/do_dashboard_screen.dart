import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../models/fine_model.dart';
import '../../auth/services/auth_service.dart';
import '../../divisional_officer/services/fine_service.dart';
import 'add_traffic_officer_screen.dart';
import 'assign_shift_screen.dart';
import 'court_cases_screen.dart';
import 'traffic_officer_list_screen.dart';
import 'settings_screen.dart';
import 'revoked_licenses_screen.dart';

class DoDashboardScreen extends StatefulWidget {
  const DoDashboardScreen({super.key});

  @override
  State<DoDashboardScreen> createState() => _DoDashboardScreenState();
}

class _DoDashboardScreenState extends State<DoDashboardScreen> {
  final FineService _fineService = FineService();
  DistrictStatisticsModel? _stats;
  bool _isLoading = true;

  final List<MenuItem> _menuItems = const [
    MenuItem(
      icon: Icons.person_add_alt_1_outlined,
      title: 'Add Traffic Officer',
      subtitle: 'Create a new traffic officer account',
      route: 'add_officer',
    ),
    MenuItem(
      icon: Icons.groups_2_outlined,
      title: 'Traffic Officer List',
      subtitle: 'View officers assigned to your district',
      route: 'officer_list',
    ),
    MenuItem(
      icon: Icons.schedule_outlined,
      title: 'Assign Shift',
      subtitle: 'Set active duty time for an officer',
      route: 'assign_shift',
    ),
    MenuItem(
      icon: Icons.gavel_outlined,
      title: 'Court Cases',
      subtitle: 'Review and resolve court pending fines',
      route: 'court_cases',
    ),
    MenuItem(
      icon: Icons.cancel_outlined,
      title: 'Revoked Licenses',
      subtitle: 'View and resolve revoked licenses',
      route: 'revoked_licenses',
    ),
    MenuItem(
      icon: Icons.settings_outlined,
      title: 'Settings',
      subtitle: 'App settings and preferences',
      route: 'settings',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final stats = await _fineService.getDistrictStatistics();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 22),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.78),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.65),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
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
                        color: AppTheme.policeBlue,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Log out?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.policeBlue,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'You will need to sign in again to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext, false),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.policeBlue,
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
                              backgroundColor: AppTheme.policeBlue,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(22),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text(
                              'Logout',
                              style: TextStyle(fontWeight: FontWeight.w800),
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
    await AuthService().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
      (route) => false,
    );
  }

  void _openScreen(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  String _formatRevenue(double value) {
    return 'LKR ${value.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    final isLoading = _isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundWhite,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Dashboard',
            style: TextStyle(
              color: AppTheme.policeBlue,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.menu_rounded,
                color: AppTheme.policeBlue,
                size: 28,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              offset: const Offset(0, 16),
              color: Colors.white,
              elevation: 4,
              onSelected: (value) {
                switch (value) {
                  case 'add_officer':
                    _openScreen(context, const AddTrafficOfficerScreen());
                    break;
                  case 'officer_list':
                    _openScreen(context, const TrafficOfficerListScreen());
                    break;
                  case 'assign_shift':
                    _openScreen(context, const AssignShiftScreen());
                    break;
                  case 'court_cases':
                    _openScreen(context, const CourtCasesScreen());
                    break;
                  case 'revoked_licenses':
                    _openScreen(context, const RevokedLicensesScreen());
                    break;
                  case 'settings':
                    _openScreen(context, const SettingsScreen());
                    break;
                  case 'logout':
                    _handleLogout(context);
                    break;
                }
              },
              itemBuilder: (context) {
                return [
                  ..._menuItems.map((item) {
                    return PopupMenuItem<String>(
                      value: item.route,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppTheme.policeBlue.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              item.icon,
                              color: AppTheme.policeBlue,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(
                                    color: AppTheme.policeBlue,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  item.subtitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppTheme.textGray,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<String>(
                    value: 'logout',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppTheme.errorRed.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppTheme.errorRed,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: AppTheme.errorRed,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const _WelcomeCard(),
                const SizedBox(height: 24),
                const Text(
                  'Quick Statistics',
                  style: TextStyle(
                    color: AppTheme.policeBlue,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (isLoading)
                  _buildShimmerStats()
                else if (stats != null)
                  _buildStatsGrid(stats)
                else
                  const SizedBox.shrink(),
                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(DistrictStatisticsModel stats) {
    final items = [
      _StatData(
        icon: Icons.groups_outlined,
        value: stats.totalOfficers.toString(),
        label: 'Total Officers',
        color: Colors.blue.shade700,
      ),
      _StatData(
        icon: Icons.local_police_outlined,
        value: stats.activeOfficersOnDuty.toString(),
        label: 'On Duty',
        color: Colors.green.shade700,
      ),
      _StatData(
        icon: Icons.receipt_long_outlined,
        value: stats.totalFinesIssued.toString(),
        label: 'Total Fines',
        color: Colors.orange.shade700,
      ),
      _StatData(
        icon: Icons.payments_outlined,
        value: _formatRevenue(stats.totalRevenue),
        label: 'Revenue',
        color: Colors.green.shade700,
      ),
      _StatData(
        icon: Icons.pending_actions_outlined,
        value: stats.pendingFinesCount.toString(),
        label: 'Pending',
        color: Colors.orange.shade700,
      ),
      _StatData(
        icon: Icons.gavel_outlined,
        value: stats.overdueCourtCases.toString(),
        label: 'Court Cases',
        color: Colors.red.shade700,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final data = items[index];
        return _QuickStatCard(data: data);
      },
    );
  }

  Widget _buildShimmerStats() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.policeBlue.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                width: 50,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.lightGray,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PoliceSession?>(
      future: const TokenStorage().getSession(),
      builder: (context, snapshot) {
        final session = snapshot.data;
        final officerName = session?.officerName.trim().isNotEmpty == true
            ? session!.officerName
            : 'Officer';
        final divisionLabel = session?.districtId.trim().isNotEmpty == true
            ? 'Divisional Head • ${session!.districtId}'
            : 'Divisional Head';

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0B1A30),
                    AppTheme.policeBlueDark,
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 25,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(-4, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: 'Welcome, $officerName ',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 23,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                            children: [
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: const Icon(
                                  Icons.verified_user_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    divisionLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Manage traffic officers, duty shifts, court cases, and district level statistics from one place.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _QuickStatCard extends StatelessWidget {
  const _QuickStatCard({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.policeBlue.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              data.icon,
              color: data.color,
              size: 18,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppTheme.policeBlue,
              fontSize: 16,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppTheme.textGray,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;
}

class MenuItem {
  const MenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}