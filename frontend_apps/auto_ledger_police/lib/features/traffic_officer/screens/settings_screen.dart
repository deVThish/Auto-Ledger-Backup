import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../widgets/about_dialog.dart';
import '../widgets/change_password_dialog.dart';
import '../widgets/glass_card.dart';
import '../widgets/liquid_nav_bar.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TokenStorage _tokenStorage = const TokenStorage();

  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  bool _isCheckingBiometric = true;
  bool _isUpdatingBiometric = false;
  int _selectedNavIndex = 2;

  @override
  void initState() {
    super.initState();
    _initBiometrics();
  }

  Future<void> _initBiometrics() async {
    bool isDeviceSupported = false;
    bool canCheckBiometrics = false;
    List<BiometricType> availableBiometrics = const [];

    try {
      isDeviceSupported = await _localAuth.isDeviceSupported();
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      availableBiometrics = await _localAuth.getAvailableBiometrics();

      debugPrint('local_auth -> isDeviceSupported: $isDeviceSupported');
      debugPrint('local_auth -> canCheckBiometrics: $canCheckBiometrics');
      debugPrint('local_auth -> availableBiometrics: $availableBiometrics');
    } on PlatformException catch (e) {
      debugPrint('local_auth init error: ${e.code} / ${e.message}');
      isDeviceSupported = false;
      canCheckBiometrics = false;
      availableBiometrics = const [];
    } catch (e) {
      debugPrint('local_auth init unexpected error: $e');
      isDeviceSupported = false;
      canCheckBiometrics = false;
      availableBiometrics = const [];
    }

    if (!mounted) return;

    final supported = isDeviceSupported &&
        canCheckBiometrics &&
        availableBiometrics.isNotEmpty;

    final savedEnabled = supported ? await _tokenStorage.getBiometricEnabled() : false;

    if (!mounted) return;

    setState(() {
      _biometricSupported = supported;
      _biometricEnabled = savedEnabled && supported;
      _isCheckingBiometric = false;
      if (!_biometricSupported) {
        _biometricEnabled = false;
      }
    });
  }

  Future<void> _onNavTap(int index) async {
    if (index == 2) {
      return;
    }

    if (index == 1) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      return;
    }

    if (index == 0) {
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  Future<void> _openChangePassword() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (_) => const ChangePasswordDialog(),
    );

    if (changed == true && mounted) {
      AppErrorHandler.showPopup(
        context,
        message: 'Password changed successfully.',
        isError: false,
      );
    }
  }

  Future<void> _openAbout() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (_) => const AppAboutDialog(),
    );
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!value) {
      if (!mounted) return;
      setState(() {
        _biometricEnabled = false;
      });
      await _tokenStorage.saveBiometricEnabled(false);
      return;
    }

    if (_isUpdatingBiometric) return;

    if (_isCheckingBiometric) {
      AppErrorHandler.showPopup(
        context,
        message: 'Fingerprint support is still being checked.',
      );
      return;
    }

    if (!_biometricSupported) {
      AppErrorHandler.showPopup(
        context,
        message:
            'This device does not currently support fingerprint login. Please add a fingerprint in device settings and try again.',
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _isUpdatingBiometric = true;
    });

    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to enable fingerprint login.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _biometricEnabled = true;
        });
        await _tokenStorage.saveBiometricEnabled(true);
      } else {
        AppErrorHandler.showPopup(
          context,
          message: 'Fingerprint authentication was cancelled.',
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;

      debugPrint('Fingerprint auth error -> code: ${e.code}');
      debugPrint('Fingerprint auth error -> message: ${e.message}');

      String message = 'Unable to use fingerprint on this device right now.';

      switch (e.code) {
        case 'NotAvailable':
          message = 'Fingerprint is not available on this device.';
          break;
        case 'NotEnrolled':
          message =
              'No fingerprint is enrolled. Please add one in device settings first.';
          break;
        case 'LockedOut':
          message =
              'Fingerprint is locked temporarily. Please try again after a while.';
          break;
        case 'PermanentlyLockedOut':
          message =
              'Fingerprint is permanently locked. Use device PIN or password, then try again.';
          break;
        case 'PasscodeNotSet':
          message =
              'Please set a device PIN, password, or pattern before using fingerprint login.';
          break;
      }

      AppErrorHandler.showPopup(
        context,
        message: message,
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('Fingerprint auth unexpected error: $e');

      AppErrorHandler.showPopup(
        context,
        message: 'Unable to use fingerprint on this device right now.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingBiometric = false;
        });
      }
    }
  }

  String _biometricSubtitle() {
    if (_isCheckingBiometric) {
      return 'Checking device support...';
    }

    if (!_biometricSupported) {
      return 'Fingerprint login is blocked on this device.';
    }

    return _biometricEnabled
        ? 'Fingerprint login is enabled on this device.'
        : 'Fingerprint login is available but turned off.';
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

              final headerFlex = compact ? 1 : 1;
              final fingerprintFlex = compact ? 3 : 3;
              final cardsFlex = compact ? 5 : 5;
              final footerFlex = compact ? 1 : 1;

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
                    compact ? 12 : 16,
                    horizontalPadding,
                    compact ? 10 : 14,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(flex: headerFlex, child: const _PageHeader()),
                      SizedBox(height: compact ? 8 : 12),
                      Flexible(
                        flex: fingerprintFlex,
                        child: GlassCard(
                          borderRadius: 30,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            compact ? 16 : 18,
                            16,
                            compact ? 16 : 18,
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.policeBlue.withValues(alpha: 0.94),
                              AppTheme.policeBlueDark.withValues(alpha: 0.94),
                            ],
                          ),
                          borderColor: Colors.white.withValues(alpha: 0.16),
                          shadowColor: AppTheme.policeBlue,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: compact ? 46 : 52,
                                    height: compact ? 46 : 52,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    child: const Icon(
                                      Icons.fingerprint_rounded,
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
                                          'Fingerprint Login',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Use device biometrics to enable quick access.',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12.5,
                                            height: 1.35,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              _SecurityTile(
                                supported:
                                    !_isCheckingBiometric && _biometricSupported,
                                enabled: _biometricEnabled,
                                busy: _isUpdatingBiometric || _isCheckingBiometric,
                                subtitle: _biometricSubtitle(),
                                onChanged: _toggleBiometric,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: compact ? 10 : 12),
                      Expanded(
                        flex: cardsFlex,
                        child: Column(
                          children: [
                            GlassCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  _SettingsTile(
                                    icon: Icons.lock_reset_rounded,
                                    title: 'Change Password',
                                    subtitle: 'Update your login password',
                                    onTap: _openChangePassword,
                                  ),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey.shade200.withValues(alpha: 0.55),
                                    indent: 18,
                                    endIndent: 18,
                                  ),
                                  _SettingsTile(
                                    icon: Icons.info_outline_rounded,
                                    title: 'About',
                                    subtitle: 'App version and details',
                                    onTap: _openAbout,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: compact ? 10 : 12),
                            GlassCard(
                              padding: EdgeInsets.zero,
                              child: Column(
                                children: [
                                  const _SettingsTile(
                                    icon: Icons.privacy_tip_rounded,
                                    title: 'Privacy Policy',
                                    subtitle: 'Coming soon',
                                    showArrow: true,
                                  ),
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.grey.shade200.withValues(alpha: 0.55),
                                    indent: 18,
                                    endIndent: 18,
                                  ),
                                  const _SettingsTile(
                                    icon: Icons.description_rounded,
                                    title: 'Terms of Service',
                                    subtitle: 'Coming soon',
                                    showArrow: true,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      Flexible(
                        flex: footerFlex,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.policeBlue.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.local_police_rounded,
                                  color: AppTheme.policeBlue.withValues(alpha: 0.68),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Auto-Ledger v1.0.0',
                                style: TextStyle(
                                  color: AppTheme.textGray,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
            Icons.settings_rounded,
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
                'Settings',
                style: TextStyle(
                  color: AppTheme.policeBlue,
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Account and app preferences',
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

class _SecurityTile extends StatelessWidget {
  const _SecurityTile({
    required this.supported,
    required this.enabled,
    required this.busy,
    required this.subtitle,
    required this.onChanged,
  });

  final bool supported;
  final bool enabled;
  final bool busy;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
      borderRadius: 26,
      color: Colors.white.withValues(alpha: 0.18),
      borderColor: Colors.white.withValues(alpha: 0.16),
      shadowColor: Colors.black,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.fingerprint_rounded,
              color: supported ? Colors.white : Colors.white70,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fingerprint Login',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          if (busy)
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: Colors.white,
              ),
            )
          else
            Switch.adaptive(
              value: enabled,
              onChanged: supported ? onChanged : null,
              activeColor: Colors.white,
              activeTrackColor: Colors.white.withValues(alpha: 0.32),
              inactiveThumbColor: Colors.white70,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.16),
            ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showArrow = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showArrow;

  @override
  Widget build(BuildContext context) {
    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.policeBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: AppTheme.policeBlue,
              size: 21,
            ),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (showArrow)
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textGray,
              size: 16,
            ),
        ],
      ),
    );

    if (onTap == null) {
      return tile;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppTheme.policeBlue.withValues(alpha: 0.05),
        highlightColor: Colors.transparent,
        child: tile,
      ),
    );
  }
}