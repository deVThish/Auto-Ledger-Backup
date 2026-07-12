import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/theme/app_theme.dart';
import 'login_screen.dart';

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({
    super.key,
    required this.nextScreen,
  });

  final Widget nextScreen;

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _localAuth = LocalAuthentication();
  late final AnimationController _pulseController;

  bool _isAuthenticating = true;
  String _statusText = 'Preparing secure authentication...';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _authenticate();
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Route _fadeRoute(Widget screen) {
    return PageRouteBuilder(
      pageBuilder: (_, animation, __) => screen,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        );
      },
    );
  }

  Future<void> _goToLogin() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _fadeRoute(const LoginScreen()),
    );
  }

  Future<void> _goToNextScreen() async {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _fadeRoute(widget.nextScreen),
    );
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _statusText = 'Checking device security...';
    });

    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      final availableBiometrics = await _localAuth.getAvailableBiometrics();

      if (!mounted) return;

      if (!isDeviceSupported || !canCheckBiometrics || availableBiometrics.isEmpty) {
        setState(() {
          _statusText = 'Fingerprint is not ready on this device.';
        });

        await Future.delayed(const Duration(milliseconds: 700));
        await _goToLogin();
        return;
      }

      setState(() {
        _statusText = 'Touch the fingerprint sensor to continue...';
      });

      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to continue to Auto-Ledger Police.',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;

      if (authenticated) {
        setState(() {
          _statusText = 'Authentication successful...';
        });

        await Future.delayed(const Duration(milliseconds: 300));
        await _goToNextScreen();
      } else {
        setState(() {
          _statusText = 'Authentication cancelled.';
        });

        await Future.delayed(const Duration(milliseconds: 500));
        await _goToLogin();
      }
    } on PlatformException catch (e) {
      if (!mounted) return;

      debugPrint('Biometric auth error -> code: ${e.code}');
      debugPrint('Biometric auth error -> message: ${e.message}');

      setState(() {
        _statusText = _messageForCode(e.code);
      });

      await Future.delayed(const Duration(milliseconds: 900));
      await _goToLogin();
    } catch (e) {
      if (!mounted) return;

      debugPrint('Biometric auth unexpected error: $e');

      setState(() {
        _statusText = 'Unable to start fingerprint authentication.';
      });

      await Future.delayed(const Duration(milliseconds: 900));
      await _goToLogin();
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  String _messageForCode(String code) {
    switch (code) {
      case 'NotAvailable':
        return 'Fingerprint is not available on this device.';
      case 'NotEnrolled':
        return 'No fingerprint is enrolled on this device.';
      case 'LockedOut':
        return 'Fingerprint is locked temporarily. Try again later.';
      case 'PermanentlyLockedOut':
        return 'Fingerprint is permanently locked. Use device PIN or password.';
      case 'PasscodeNotSet':
        return 'Please set a device PIN, password, or pattern first.';
      case 'no_fragment_activity':
        return 'Authentication requires a FragmentActivity setup.';
      default:
        return 'Unable to use fingerprint right now.';
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
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F8FF),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FBFF),
                  Color(0xFFF0F6FF),
                ],
              ),
            ),
            child: SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(34),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                      child: Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.56),
                          borderRadius: BorderRadius.circular(34),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.48),
                            width: 1.4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 40,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                color: AppTheme.policeBlue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: const Icon(
                                Icons.local_police_rounded,
                                color: AppTheme.policeBlue,
                                size: 34,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Auto-Ledger Police',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.policeBlue,
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Secure authentication portal',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textGray,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 22),
                            ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.96,
                                end: 1.04,
                              ).animate(
                                CurvedAnimation(
                                  parent: _pulseController,
                                  curve: Curves.easeInOut,
                                ),
                              ),
                              child: Container(
                                width: 88,
                                height: 88,
                                decoration: BoxDecoration(
                                  color: AppTheme.policeBlue.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.policeBlue.withValues(alpha: 0.16),
                                    width: 1.2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.fingerprint_rounded,
                                  color: AppTheme.policeBlue,
                                  size: 46,
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _statusText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.textGray,
                                fontSize: 13,
                                height: 1.45,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 18),
                            SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: AppTheme.policeBlue.withValues(alpha: 0.9),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Authenticating...',
                              style: TextStyle(
                                color: AppTheme.textGray,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}