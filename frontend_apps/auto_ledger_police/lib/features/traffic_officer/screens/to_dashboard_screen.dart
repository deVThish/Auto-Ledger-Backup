import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/services/auth_service.dart';
import 'fine_history_screen.dart';
import 'qr_scanner_screen.dart';

class ToDashboardScreen extends StatelessWidget {
  const ToDashboardScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    await AuthService().logout();

    if (!context.mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRoutes.login,
          (route) => false,
    );
  }

  void _openScanner(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const QrScannerScreen(),
      ),
    );
  }

  void _openFineHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const FineHistoryScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
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
                    const SizedBox(height: 22),
                    _DashboardHeader(
                      onLogout: () => _handleLogout(context),
                    ),
                    const SizedBox(height: 26),
                    const _WelcomeCard(),
                    const SizedBox(height: 24),
                    const Text(
                      'Traffic Officer Actions',
                      style: TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _ToActionCard(
                      icon: Icons.qr_code_scanner_rounded,
                      title: 'Scan Driver QR',
                      subtitle: 'Verify driver license using QR token.',
                      onTap: () => _openScanner(context),
                    ),
                    const SizedBox(height: 14),
                    _ToActionCard(
                      icon: Icons.receipt_long_outlined,
                      title: 'Issue Fine',
                      subtitle: 'Start from driver QR verification.',
                      onTap: () => _openScanner(context),
                    ),
                    const SizedBox(height: 14),
                    _ToActionCard(
                      icon: Icons.history_rounded,
                      title: 'Fine History',
                      subtitle: 'View issued fines and recent activity.',
                      onTap: () => _openFineHistory(context),
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

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppTheme.primaryBlack,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(
            Icons.local_police_outlined,
            color: Colors.white,
            size: 28,
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Police Portal',
                style: TextStyle(
                  color: AppTheme.primaryBlack,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Traffic Officer Dashboard',
                style: TextStyle(
                  color: AppTheme.textGray,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onLogout,
          icon: const Icon(Icons.logout_rounded),
          color: AppTheme.primaryBlack,
        ),
      ],
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
        final badgeNumber =
        session?.officerBadgeNumber.trim().isNotEmpty == true
            ? session!.officerBadgeNumber
            : 'Traffic Officer';

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
                Icons.qr_code_scanner_rounded,
                color: Colors.white,
                size: 34,
              ),
              const SizedBox(height: 18),
              Text(
                'Welcome, $officerName',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                badgeNumber,
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
                'Verify driver licenses, select traffic offenses, issue fines, and review fine history.',
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
      },
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
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
                child: Icon(
                  icon,
                  color: AppTheme.primaryBlack,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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