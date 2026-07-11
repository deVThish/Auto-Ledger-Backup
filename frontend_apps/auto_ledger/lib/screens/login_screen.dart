import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../utils/device_info.dart';
import '../utils/settings_util.dart';
import '../utils/secure_storage.dart';
import '../widgets/glass_container.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with WidgetsBindingObserver {
  final _nicController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();

  final _forgotNicController = TextEditingController();
  final _forgotEmailController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  final BiometricService _biometricService = BiometricService();
  bool _isBiometricAvailable = false;

  bool _isLoading = false;
  bool _isBiometricEnabled = false;
  bool _obscurePassword = true;
  bool _obscureResetPassword = true;
  bool _obscureConfirmResetPassword = true;

  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkBiometricStatus();
    _checkBiometricAvailability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlayEntry?.remove();
    _nicController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _forgotNicController.dispose();
    _forgotEmailController.dispose();
    _newPasswordController.dispose();
    _confirmNewPasswordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkBiometricStatus();
      _checkBiometricAvailability();
    }
  }

  Future<void> _checkBiometricStatus() async {
    final isEnabled = await SettingsUtil.isBiometricEnabled();
    if (mounted) {
      setState(() {
        _isBiometricEnabled = isEnabled;
      });
    }
  }

  Future<void> _checkBiometricAvailability() async {
    final available = await _biometricService.checkBiometricsAvailable();
    if (mounted) {
      setState(() {
        _isBiometricAvailable = available;
      });
    }
  }

  void _showToast(String message, {bool isError = false}) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final topPadding = MediaQuery.of(context).padding.top;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: topPadding + 20,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, -(1 - value) * 20),
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: isError
                        ? Colors.redAccent.withAlpha(100)
                        : Colors.black.withAlpha(80),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withAlpha(70),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 10,
                          spreadRadius: 1)
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(isError ? Icons.error_outline : Icons.info_outline,
                          color: Colors.white),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(message,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Navigator.of(context, rootNavigator: true).overlay?.insert(_overlayEntry!);

    Future.delayed(const Duration(seconds: 3), () {
      if (_overlayEntry != null && _overlayEntry!.mounted) {
        _overlayEntry!.remove();
        _overlayEntry = null;
      }
    });
  }

  void _showGlassySuccessToast(OverlayState overlay, String message) {
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 120.0,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Opacity(
                opacity: value.clamp(0.0, 1.0),
                child: Transform.translate(
                  offset: Offset(0, (1 - value) * 20),
                  child: child,
                ),
              );
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade600.withAlpha(40),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(100),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline_rounded,
                          color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          message,
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);

    Future.delayed(const Duration(seconds: 1), () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  //  Biometric Login
  Future<void> _handleBiometricLogin() async {
    if (!mounted) return;

    final isEnabled = await SettingsUtil.isBiometricEnabled();
    if (!isEnabled) {
      _showToast('Biometric login is not enabled in settings.', isError: true);
      return;
    }

    if (!_isBiometricAvailable) {
      _showToast('Biometric hardware not available.', isError: true);
      return;
    }

    final String? savedNic = await SecureStorage.getNic();
    final String nic = savedNic ?? _nicController.text.trim();

    if (nic.isEmpty) {
      _showToast('Please enter your NIC first to save for biometric login.',
          isError: true);
      return;
    }

    final authenticated = await _biometricService.authenticate();
    if (!authenticated) {
      _showToast('Authentication failed.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final result = await AuthService.biometricLogin(nic, deviceId);

      if (!mounted) return;

      if (result['success'] == true) {
        await SecureStorage.saveNic(nic);
        // ignore: use_build_context_synchronously
        final overlay = Navigator.of(context, rootNavigator: true).overlay;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        if (overlay != null) {
          _showGlassySuccessToast(overlay, 'Biometric Login Successful!');
        }
      } else if (result['isDeviceMismatch'] == true) {
        final String email = result['email'] ?? '';
        if (email.isNotEmpty) {
          if (!mounted) return;
          _showDeviceVerificationDialog(email, nic);
        } else {
          _showToast('Device verification required. Check your email.',
              isError: true);
        }
      } else {
        _showToast('Biometric login failed. Check NIC.', isError: true);
      }
    } catch (e) {
      if (mounted)
        // ignore: curly_braces_in_flow_control_structures
        _showToast('An error occurred during biometric login.', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  //  NORMAL LOGIN
  Future<void> _handleLogin() async {
    if (!mounted) return;

    FocusScope.of(context).unfocus();

    if (_nicController.text.trim().isEmpty) {
      _showToast('NIC Number is required', isError: true);
      return;
    }
    if (_passwordController.text.trim().isEmpty) {
      _showToast('Password is required', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final result = await AuthService.loginUser(
        _nicController.text.trim(),
        _passwordController.text.trim(),
        deviceId,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        await SecureStorage.saveNic(_nicController.text.trim());
        // ignore: use_build_context_synchronously
        final overlay = Navigator.of(context, rootNavigator: true).overlay;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        if (overlay != null) {
          _showGlassySuccessToast(overlay, 'Login Successful!');
        }
      } else if (result['isDeviceMismatch'] == true) {
        final String email = result['email'] ?? '';
        final String nic = _nicController.text.trim();
        if (email.isNotEmpty) {
          if (!mounted) return;
          _showDeviceVerificationDialog(email, nic);
        } else {
          _showToast('Device verification required. Check your email.',
              isError: true);
        }
        setState(() => _isLoading = false);
      } else {
        _showToast('Login Failed. Check credentials.', isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Login Failed. Check credentials or connection.',
            isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  //  DEVICE VERIFICATION DIALOG
  void _showDeviceVerificationDialog(String email, String nic) {
    _otpController.clear();
    bool isResending = false;

    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withAlpha(200),
        builder: (BuildContext dialogContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Dialog(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(25),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withAlpha(50), width: 1.5),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.phonelink_lock,
                            color: Colors.white, size: 40),
                        const SizedBox(height: 15),
                        const Text(
                          'Device Verification',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          'A new device is detected. Enter the OTP sent to your email:',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          email,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _otpController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              letterSpacing: 8),
                          textAlign: TextAlign.center,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white.withAlpha(20),
                            hintText: '••••••',
                            hintStyle: const TextStyle(
                                color: Colors.white54, letterSpacing: 8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: isResending
                              ? null
                              : () async {
                                  setModalState(() => isResending = true);
                                  try {
                                    final success =
                                        await AuthService.resendDeviceOtp(
                                            nic, email);
                                    if (success && mounted) {
                                      _showToast('OTP resent successfully!');
                                    } else {
                                      _showToast('Failed to resend OTP.',
                                          isError: true);
                                    }
                                  } catch (e) {
                                    _showToast('Failed to resend OTP.',
                                        isError: true);
                                  }
                                  if (mounted) {
                                    setModalState(() => isResending = false);
                                  }
                                },
                          child: Text(
                            isResending ? 'Sending...' : 'Resend OTP',
                            style: TextStyle(
                              color: isResending
                                  ? Colors.white54
                                  : Colors.cyanAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.white.withAlpha(100),
                                        width: 1.5),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  setState(() => _isLoading = false);
                                },
                                child: const Text('Cancel',
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white.withAlpha(50),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                        color: Colors.white.withAlpha(150),
                                        width: 1.5),
                                  ),
                                ),
                                onPressed: () => _verifyDeviceOTP(nic),
                                child: const Text('Verify Device',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      );
    });
  }

  Future<void> _verifyDeviceOTP(String nic) async {
    final String otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showToast('Please enter the OTP', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final deviceId = await DeviceInfoUtil.getDeviceId();
      final result = await AuthService.verifyNewDevice(nic, deviceId, otp);

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context, rootNavigator: true).pop();
        final overlay = Navigator.of(context, rootNavigator: true).overlay;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
        if (overlay != null) {
          _showGlassySuccessToast(overlay, 'Device verified successfully!');
        }
      } else {
        _showToast('Invalid OTP. Please try again.', isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Device verification failed. Please try again.',
            isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  //  FORGOT PASSWORD
  Future<void> _handleForgotPasswordCheck() async {
    if (!mounted) return;

    FocusScope.of(context).unfocus();

    final nic = _forgotNicController.text.trim();
    final email = _forgotEmailController.text.trim();

    if (nic.isEmpty) {
      _showToast('NIC Number is required', isError: true);
      return;
    }
    if (email.isEmpty || !email.contains('@') || !email.contains('.')) {
      _showToast('Please enter a valid email address.', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final isValid = await AuthService.forgotPasswordCheck(nic, email);
      if (!mounted) return;

      if (isValid) {
        if (mounted) Navigator.pop(context);
        _showForgotPasswordOTPDialog(email, nic);
        setState(() => _isLoading = false);
      } else {
        _showToast('Verification failed. Check NIC and Email.', isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Verification failed. Check NIC and Email.', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordOTPDialog(String email, String nic) {
    _otpController.clear();
    bool isResending = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(200),
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withAlpha(50), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.message, color: Colors.white, size: 40),
                      const SizedBox(height: 15),
                      const Text('Enter OTP',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 15),
                      Text(
                        'Enter the OTP sent to your email: $email',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            letterSpacing: 8),
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white.withAlpha(20),
                          hintText: '••••••',
                          hintStyle: const TextStyle(
                              color: Colors.white54, letterSpacing: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: isResending
                            ? null
                            : () async {
                                setModalState(() => isResending = true);
                                try {
                                  final success =
                                      await AuthService.resendResetOtp(
                                          nic, email);
                                  if (success && mounted) {
                                    _showToast('OTP resent successfully!');
                                  } else {
                                    _showToast('Failed to resend OTP.',
                                        isError: true);
                                  }
                                } catch (e) {
                                  _showToast('Failed to resend OTP.',
                                      isError: true);
                                }
                                if (mounted) {
                                  setModalState(() => isResending = false);
                                }
                              },
                        child: Text(
                          isResending ? 'Sending...' : 'Resend OTP',
                          style: TextStyle(
                            color: isResending
                                ? Colors.white54
                                : Colors.cyanAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: Colors.white.withAlpha(100),
                                      width: 1.5),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                setState(() => _isLoading = false);
                              },
                              child: const Text('Cancel',
                                  style: TextStyle(color: Colors.white)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withAlpha(50),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: Colors.white.withAlpha(150),
                                      width: 1.5),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(dialogContext);
                                _showResetPasswordDialog(nic, email);
                              },
                              child: const Text('Verify',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handlePasswordReset(String nic, String email) async {
    if (!mounted) return;

    FocusScope.of(context).unfocus();

    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmNewPasswordController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.isEmpty) {
      _showToast('OTP is required', isError: true);
      return;
    }
    if (newPassword.isEmpty) {
      _showToast('New Password is required', isError: true);
      return;
    }
    final passwordRegex = RegExp(
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$');
    if (!passwordRegex.hasMatch(newPassword)) {
      _showToast(
          'Password must be at least 8 characters, contain uppercase, lowercase, number, and special character.',
          isError: true);
      return;
    }
    if (confirmPassword.isEmpty) {
      _showToast('Please confirm your new password.', isError: true);
      return;
    }
    if (newPassword != confirmPassword) {
      _showToast('New password and confirm password do not match.',
          isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await AuthService.resetPassword(
        nic,
        email,
        otp,
        newPassword,
      );

      if (!mounted) return;

      if (success) {
        if (mounted) Navigator.pop(context);
        final overlay = Navigator.of(context, rootNavigator: true).overlay;
        if (overlay != null) {
          _showGlassySuccessToast(
              overlay, 'Password reset successfully! Please login.');
        }
        _forgotNicController.clear();
        _forgotEmailController.clear();
        _newPasswordController.clear();
        _confirmNewPasswordController.clear();
        setState(() => _isLoading = false);
      } else {
        _showToast('Invalid OTP. Please try again.', isError: true);
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        _showToast('Failed to reset password.', isError: true);
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordInitialDialog() {
    _forgotEmailController.clear();
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(200),
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(25),
                borderRadius: BorderRadius.circular(24),
                border:
                    Border.all(color: Colors.white.withAlpha(50), width: 1.5),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset, color: Colors.white, size: 40),
                  const SizedBox(height: 16),
                  const Text('Reset Password',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Enter your details to receive an OTP via email',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _forgotNicController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'NIC Number',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withAlpha(20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _forgotEmailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.white.withAlpha(20),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.cyanAccent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: Colors.white.withAlpha(100),
                                  width: 1.5),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(50),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: Colors.white.withAlpha(150),
                                  width: 1.5),
                            ),
                          ),
                          onPressed: _handleForgotPasswordCheck,
                          child: const Text('Next',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showResetPasswordDialog(String nic, String email) {
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withAlpha(200),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withAlpha(50), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.password, color: Colors.white, size: 40),
                      const SizedBox(height: 16),
                      const Text('New Password',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
                      TextField(
                        controller: _newPasswordController,
                        obscureText: _obscureResetPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withAlpha(20),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.cyanAccent),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureResetPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _obscureResetPassword = !_obscureResetPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _confirmNewPasswordController,
                        obscureText: _obscureConfirmResetPassword,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          labelStyle: const TextStyle(color: Colors.white54),
                          filled: true,
                          fillColor: Colors.white.withAlpha(20),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Colors.cyanAccent),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmResetPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setModalState(() {
                                _obscureConfirmResetPassword =
                                    !_obscureConfirmResetPassword;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withAlpha(50),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: Colors.white.withAlpha(150),
                                  width: 1.5),
                            ),
                          ),
                          onPressed: () => _handlePasswordReset(nic, email),
                          child: const Text('Save Password',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _LoginBackground(),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: GlassContainer(
                width: double.infinity,
                padding: const EdgeInsets.all(28.0),
                borderRadius: 24.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.directions_car,
                        size: 60, color: Colors.white),
                    const SizedBox(height: 16),
                    const Text(
                      'Auto-Ledger',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 40),
                    TextField(
                      controller: _nicController,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'NIC Number',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.badge, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withAlpha(20),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white.withAlpha(40)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Colors.cyanAccent, width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: Colors.white70),
                        prefixIcon:
                            const Icon(Icons.lock, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withAlpha(20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Colors.white.withAlpha(40)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(
                              color: Colors.cyanAccent, width: 1.5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _showForgotPasswordInitialDialog,
                        child: const Text(
                          'Forgot Password?',
                          style: TextStyle(
                              color: Colors.cyanAccent,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_isLoading)
                      const CircularProgressIndicator(color: Colors.cyanAccent)
                    else
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF0F2027),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _handleLogin,
                          child: const Text(
                            'LOGIN',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (_isBiometricEnabled && _isBiometricAvailable) ...[
                      IconButton(
                        icon: const Icon(Icons.fingerprint,
                            color: Colors.white, size: 45),
                        onPressed: _isLoading ? null : _handleBiometricLogin,
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: RichText(
                        text: const TextSpan(
                          text: 'New Driver? ',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          children: [
                            TextSpan(
                              text: 'Register Here',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginBackground extends StatelessWidget {
  const _LoginBackground();

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0F2027),
                  Color(0xFF203A43),
                  Color(0xFF2C5364)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          Positioned(
            top: 100,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withAlpha(40),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent.withAlpha(60),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: const SizedBox(),
            ),
          ),
        ],
      ),
    );
  }
}
