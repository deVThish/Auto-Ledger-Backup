import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/glass_dialog.dart';
import '../widgets/liquid_nav_bar.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _tokenStorage = const TokenStorage();
  final _authService = AuthService();

  bool _isLoading = true;
  String _name = '';
  String _badgeNumber = '';
  String _email = '';
  String _role = '';
  String _divisionName = '';
  String _divisionalHeadName = '';
  String _shiftTime = '08:00 AM - 04:00 PM';
  int _selectedNavIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    if (mounted) {
      setState(() => _isLoading = true);
    }

    try {
      final session = await _tokenStorage.getSession();
      if (!mounted) return;

      setState(() {
        if (session != null) {
          _name = session.officerName;
          _badgeNumber = session.officerBadgeNumber;
          _email = session.email;
          _role = session.role.replaceAll('_', ' ');
          _divisionName = session.divisionName;
          _divisionalHeadName = session.divisionalHeadName;
        } else {
          _name = '';
          _badgeNumber = '';
          _email = '';
          _role = '';
          _divisionName = '';
          _divisionalHeadName = '';
        }
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onNavTap(int index) async {
    if (index == 0) {
      return;
    }

    if (index == 1) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (index == 2) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SettingsScreen()),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (dialogContext) {
        return GlassDialogShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GlassDialogIcon(
                icon: Icons.logout_rounded,
                backgroundColor: Color(0x1A142C5C),
                iconColor: AppTheme.policeBlue,
              ),
              const SizedBox(height: 14),
              const Text(
                'Log out?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You will need to sign in again to continue using the Traffic Officer portal.',
                textAlign: TextAlign.center,
                style: TextStyle(
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
                    child: GlassDialogAction(
                      text: 'Cancel',
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GlassDialogAction(
                      text: 'Logout',
                      isPrimary: true,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed == true) {
      await _authService.logout();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.login,
          (route) => false,
        );
      }
    }
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'O';

    final parts = trimmed.split(' ').where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'O';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 380 ? 14.0 : 18.0;
              final compact = constraints.maxHeight < 700;

              final avatarSize = compact ? 64.0 : 70.0;
              final titleFontSize = compact ? 19.0 : 20.0;
              final badgeFontSize = compact ? 13.0 : 13.5;

              return Container(
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
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    compact ? 20 : 28,
                    horizontalPadding,
                    12,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: AppTheme.policeBlue,
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _PageHeader(),
                                SizedBox(height: compact ? 10 : 12),
                                GlassCard(
                                  borderRadius: 28,
                                  padding: EdgeInsets.fromLTRB(
                                    16,
                                    compact ? 14 : 16,
                                    16,
                                    compact ? 14 : 16,
                                  ),
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.policeBlue.withValues(alpha: 0.88),
                                      AppTheme.policeBlueDark.withValues(alpha: 0.94),
                                    ],
                                  ),
                                  borderColor: Colors.white.withValues(alpha: 0.14),
                                  shadowColor: AppTheme.policeBlue,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: avatarSize,
                                        height: avatarSize,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.14),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.24),
                                            width: 2,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            _getInitials(_name),
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: compact ? 27 : 29,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: compact ? 8 : 10),
                                      Text(
                                        _name.isEmpty ? 'Traffic Officer' : _name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        _badgeNumber.isEmpty ? 'N/A' : _badgeNumber,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: badgeFontSize,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 7),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.10),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: Colors.white.withValues(alpha: 0.14),
                                          ),
                                        ),
                                        child: Text(
                                          _role.isEmpty ? 'Traffic Officer' : _role,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(height: compact ? 8 : 10),
                                _InfoCard(
                                  icon: Icons.email_outlined,
                                  title: 'Email',
                                  value: _email.isEmpty ? 'Not available' : _email,
                                  compact: compact,
                                ),
                                const SizedBox(height: 8),
                                _InfoCard(
                                  icon: Icons.badge_outlined,
                                  title: 'Badge Number',
                                  value: _badgeNumber.isEmpty ? 'N/A' : _badgeNumber,
                                  compact: compact,
                                ),
                                const SizedBox(height: 8),
                                _InfoCard(
                                  icon: Icons.schedule_outlined,
                                  title: 'Shift Time',
                                  value: _shiftTime,
                                  compact: compact,
                                ),
                                const SizedBox(height: 8),
                                _InfoCard(
                                  icon: Icons.place_outlined,
                                  title: 'Division',
                                  value: _divisionName.isEmpty ? 'Not assigned' : _divisionName,
                                  compact: compact,
                                ),
                                const SizedBox(height: 8),
                                _InfoCard(
                                  icon: Icons.people_outlined,
                                  title: 'Divisional Head',
                                  value: _divisionalHeadName.isEmpty ? 'Not assigned' : _divisionalHeadName,
                                  compact: compact,
                                ),
                                SizedBox(height: compact ? 10 : 12),
                                Center(
                                  child: FractionallySizedBox(
                                    widthFactor: 0.6,
                                    child: GlassCard(
                                      borderRadius: 18,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      color: Colors.white.withValues(alpha: 0.88),
                                      borderColor:
                                          AppTheme.errorRed.withValues(alpha: 0.05),
                                      shadowColor: Colors.black,
                                      onTap: _handleLogout,
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.logout_rounded,
                                            color: AppTheme.errorRed,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Logout',
                                            style: TextStyle(
                                              color: AppTheme.errorRed,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Center(
                                  child: Text(
                                    'Auto-Ledger Traffic Officer',
                                    style: TextStyle(
                                      color: AppTheme.textGray,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      ),
    );
  }
}

class _PageHeader extends StatelessWidget {
  const _PageHeader();

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
            Icons.person_rounded,
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
                'My Profile',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Traffic Officer account details',
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.compact,
  });

  final IconData icon;
  final String title;
  final String value;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 12 : 14,
        vertical: compact ? 9 : 11,
      ),
      borderRadius: 22,
      color: Colors.white.withValues(alpha: 0.78),
      borderColor: Colors.white.withValues(alpha: 0.22),
      shadowColor: Colors.black,
      child: Row(
        children: [
          Container(
            width: compact ? 36 : 38,
            height: compact ? 36 : 38,
            decoration: BoxDecoration(
              color: AppTheme.policeBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppTheme.policeBlue,
              size: compact ? 19 : 20,
            ),
          ),
          SizedBox(width: compact ? 10 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.policeBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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