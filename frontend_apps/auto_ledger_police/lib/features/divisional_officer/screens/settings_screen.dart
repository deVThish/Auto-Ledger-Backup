import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final TokenStorage _tokenStorage = const TokenStorage();
  final AuthService _authService = AuthService();

  bool _biometricSupported = false;
  bool _biometricEnabled = false;
  bool _isCheckingBiometric = true;
  bool _isUpdatingBiometric = false;
  bool _isChangingPassword = false;

  PoliceSession? _session;

  @override
  void initState() {
    super.initState();
    _loadSession();
    _initBiometrics();
  }

  Future<void> _loadSession() async {
    final session = await _tokenStorage.getSession();
    if (mounted) {
      setState(() {
        _session = session;
      });
    }
  }

  Future<void> _initBiometrics() async {
    bool isDeviceSupported = false;
    bool canCheckBiometrics = false;
    List<BiometricType> availableBiometrics = const [];

    try {
      isDeviceSupported = await _localAuth.isDeviceSupported();
      canCheckBiometrics = await _localAuth.canCheckBiometrics;
      availableBiometrics = await _localAuth.getAvailableBiometrics();
    } catch (_) {
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

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    bool isLoading = false;
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final old = oldPasswordController.text.trim();
              final newP = newPasswordController.text.trim();
              final confirm = confirmPasswordController.text.trim();

              if (old.isEmpty || newP.isEmpty || confirm.isEmpty) {
                AppErrorHandler.showPopup(context, message: 'Please fill all fields');
                return;
              }
              if (newP.length < 6) {
                AppErrorHandler.showPopup(context, message: 'Password must be at least 6 characters');
                return;
              }
              if (old == newP) {
                AppErrorHandler.showPopup(context, message: 'New password must be different');
                return;
              }
              if (newP != confirm) {
                AppErrorHandler.showPopup(context, message: 'Passwords do not match');
                return;
              }

              setDialogState(() => isLoading = true);

              try {
                await _authService.changePassword(
                  oldPassword: old,
                  newPassword: newP,
                );
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                AppErrorHandler.showPopup(
                  context,
                  message: 'Password changed successfully',
                  isError: false,
                );
              } on ApiException catch (error) {
                AppErrorHandler.showPopup(context, message: error.message);
              } catch (_) {
                AppErrorHandler.showPopup(
                  context,
                  message: 'Unable to change password. Try again.',
                );
              } finally {
                if (context.mounted) {
                  setDialogState(() => isLoading = false);
                }
              }
            }

            InputDecoration glassDecoration(String label, String hint, IconData icon) {
              return InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon: Icon(icon, color: AppTheme.textGray),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.18),
                labelStyle: const TextStyle(
                  color: AppTheme.policeBlue,
                  fontWeight: FontWeight.w700,
                ),
                hintStyle: const TextStyle(
                  color: AppTheme.textGray,
                  fontWeight: FontWeight.w600,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(
                    color: AppTheme.policeBlue,
                    width: 1.2,
                  ),
                ),
              );
            }

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.68),
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
                            Icons.lock_reset_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Change Password',
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
                          'Update the password for this session.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textGray,
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: oldPasswordController,
                          obscureText: obscureOld,
                          decoration: glassDecoration(
                            'Current Password',
                            'Enter current password',
                            Icons.lock_outline_rounded,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureOld ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: AppTheme.textGray,
                              ),
                              onPressed: () {
                                setDialogState(() => obscureOld = !obscureOld);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: newPasswordController,
                          obscureText: obscureNew,
                          decoration: glassDecoration(
                            'New Password',
                            'Enter new password',
                            Icons.lock_reset_rounded,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: AppTheme.textGray,
                              ),
                              onPressed: () {
                                setDialogState(() => obscureNew = !obscureNew);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: obscureConfirm,
                          decoration: glassDecoration(
                            'Confirm New Password',
                            'Repeat new password',
                            Icons.verified_user_outlined,
                          ).copyWith(
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                color: AppTheme.textGray,
                              ),
                              onPressed: () {
                                setDialogState(() => obscureConfirm = !obscureConfirm);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
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
                                onPressed: isLoading ? null : submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.policeBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Update',
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
      },
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
        message: 'This device does not currently support fingerprint login. Please add a fingerprint in device settings and try again.',
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

      String message = 'Unable to use fingerprint on this device right now.';
      switch (e.code) {
        case 'NotAvailable':
          message = 'Fingerprint is not available on this device.';
          break;
        case 'NotEnrolled':
          message = 'No fingerprint is enrolled. Please add one in device settings first.';
          break;
        case 'LockedOut':
          message = 'Fingerprint is locked temporarily. Please try again after a while.';
          break;
        case 'PermanentlyLockedOut':
          message = 'Fingerprint is permanently locked. Use device PIN or password, then try again.';
          break;
        case 'PasscodeNotSet':
          message = 'Please set a device PIN, password, or pattern before using fingerprint login.';
          break;
        case 'no_fragment_activity':
          message = 'Authentication requires a FragmentActivity setup.';
          break;
        default:
          message = 'Unable to use fingerprint on this device right now.';
      }
      AppErrorHandler.showPopup(
        context,
        message: message,
      );
    } catch (_) {
      if (!mounted) return;
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
    final session = _session;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            'Settings',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppTheme.policeBlue,
            ),
          ),
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth < 380 ? 14.0 : 18.0;
              final compact = constraints.maxHeight < 700;

              return SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  compact ? 12 : 16,
                  horizontalPadding,
                  compact ? 10 : 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ProfileHeader(session: session, compact: compact),
                    SizedBox(height: compact ? 12 : 16),
                    _BiometricCard(
                      supported: _biometricSupported,
                      enabled: _biometricEnabled,
                      busy: _isUpdatingBiometric,
                      checking: _isCheckingBiometric,
                      subtitle: _biometricSubtitle(),
                      onChanged: _toggleBiometric,
                    ),
                    SizedBox(height: compact ? 8 : 10),
                    _ActionCard(
                      icon: Icons.lock_reset_outlined,
                      title: 'Change Password',
                      subtitle: 'Update your login password securely',
                      onTap: _changePassword,
                      compact: compact,
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'Auto-Ledger v1.0.0',
                        style: TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.session,
    required this.compact,
  });

  final PoliceSession? session;
  final bool compact;

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
    final name = session?.officerName.trim().isNotEmpty == true
        ? session!.officerName
        : 'Divisional Head';
    final badge = session?.officerBadgeNumber.trim().isNotEmpty == true
        ? session!.officerBadgeNumber
        : 'N/A';
    final division = session?.districtId.trim().isNotEmpty == true
        ? session!.districtId
        : 'Not Assigned';

    return Container(
      padding: const EdgeInsets.all(16),
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 52 : 60,
            height: compact ? 52 : 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                _getInitials(name),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 22 : 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Badge: $badge',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Division: $division',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _BiometricCard extends StatelessWidget {
  const _BiometricCard({
    required this.supported,
    required this.enabled,
    required this.busy,
    required this.checking,
    required this.subtitle,
    required this.onChanged,
  });

  final bool supported;
  final bool enabled;
  final bool busy;
  final bool checking;
  final String subtitle;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.policeBlue.withValues(alpha: 0.94),
                AppTheme.policeBlueDark.withValues(alpha: 0.94),
              ],
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fingerprint Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
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
                      ),
                    ),
                  ],
                ),
              ),
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
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.compact,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        splashColor: AppTheme.policeBlue.withValues(alpha: 0.05),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 14 : 16,
            vertical: compact ? 14 : 16,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: AppTheme.policeBlue.withValues(alpha: 0.08),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
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
                  size: 20,
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