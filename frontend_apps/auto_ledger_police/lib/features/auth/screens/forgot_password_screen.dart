import 'package:flutter/material.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _badgeController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  LoginRole _selectedRole = LoginRole.trafficOfficer;
  bool _isStepOne = true;
  bool _isLoading = false;
  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  @override
  void dispose() {
    _badgeController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String get _loginLabel {
    return _selectedRole == LoginRole.divisionalHead
        ? 'Username'
        : 'Badge Number';
  }

  String get _loginHint {
    return _selectedRole == LoginRole.divisionalHead
        ? 'Enter your username'
        : 'Enter your badge number';
  }

  String get _loginIdRequiredMessage {
    return _selectedRole == LoginRole.divisionalHead
        ? 'Username is required'
        : 'Badge number is required';
  }

  String get _stepOneTitle {
    return _selectedRole == LoginRole.divisionalHead
        ? 'Forgot Password'
        : 'Forgot Password';
  }

  String get _stepOneSubtitle {
    return _selectedRole == LoginRole.divisionalHead
        ? 'Enter your username and email'
        : 'Enter your badge number and email';
  }

  Future<void> _handleRequestOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedRole == LoginRole.divisionalHead) {
        await _authService.requestHeadForgotPasswordOtp(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
        );
      } else {
        await _authService.requestForgotPasswordOtp(
          badgeNo: _badgeController.text.trim(),
          email: _emailController.text.trim(),
        );
      }

      if (!mounted) return;

      setState(() {
        _isStepOne = false;
        _isLoading = false;
      });

      AppErrorHandler.showPopup(
        context,
        message: 'OTP sent to your email. Please check your inbox.',
        isError: false,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppErrorHandler.showPopup(
        context,
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to send OTP. Please try again.',
      );
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_selectedRole == LoginRole.divisionalHead) {
        await _authService.resetHeadForgottenPassword(
          username: _usernameController.text.trim(),
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
        );
      } else {
        await _authService.resetForgottenPassword(
          badgeNo: _badgeController.text.trim(),
          email: _emailController.text.trim(),
          otp: _otpController.text.trim(),
          newPassword: _newPasswordController.text.trim(),
        );
      }

      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: 'Password reset successfully. Please login.',
        isError: false,
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRoutes.login,
            (route) => false,
          );
        }
      });
    } on ApiException catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppErrorHandler.showPopup(
        context,
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to reset password. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTrafficOfficer = _selectedRole == LoginRole.trafficOfficer;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppTheme.backgroundWhite,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          color: AppTheme.primaryBlack,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: 78,
                      height: 78,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlack,
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        _isStepOne ? Icons.lock_reset : Icons.verified_outlined,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      _isStepOne ? _stepOneTitle : 'Reset Password',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.primaryBlack,
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isStepOne
                          ? _stepOneSubtitle
                          : 'Enter the OTP and your new password',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textGray,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppTheme.borderGray),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _RoleSwitchChip(
                              label: 'Divisional Head',
                              selected: _selectedRole == LoginRole.divisionalHead,
                              onTap: () {
                                setState(() {
                                  _selectedRole = LoginRole.divisionalHead;
                                  _badgeController.clear();
                                  _usernameController.clear();
                                  _emailController.clear();
                                  _otpController.clear();
                                  _newPasswordController.clear();
                                  _confirmPasswordController.clear();
                                  _isStepOne = true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _RoleSwitchChip(
                              label: 'Traffic Officer',
                              selected: isTrafficOfficer,
                              onTap: () {
                                setState(() {
                                  _selectedRole = LoginRole.trafficOfficer;
                                  _badgeController.clear();
                                  _usernameController.clear();
                                  _emailController.clear();
                                  _otpController.clear();
                                  _newPasswordController.clear();
                                  _confirmPasswordController.clear();
                                  _isStepOne = true;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: AppTheme.borderGray),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 26,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          if (_isStepOne) ...[
                            if (_selectedRole == LoginRole.trafficOfficer)
                              AppTextField(
                                controller: _badgeController,
                                label: _loginLabel,
                                hint: _loginHint,
                                icon: Icons.badge_outlined,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return _loginIdRequiredMessage;
                                  }
                                  return null;
                                },
                              ),
                            if (_selectedRole == LoginRole.divisionalHead)
                              AppTextField(
                                controller: _usernameController,
                                label: _loginLabel,
                                hint: _loginHint,
                                icon: Icons.person_outline,
                                textInputAction: TextInputAction.next,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return _loginIdRequiredMessage;
                                  }
                                  return null;
                                },
                              ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'Enter your registered email',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!value.contains('@')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: 'Send OTP',
                              icon: Icons.send_rounded,
                              isLoading: _isLoading,
                              onPressed: _handleRequestOtp,
                            ),
                          ] else ...[
                            AppTextField(
                              controller: _otpController,
                              label: 'OTP Code',
                              hint: 'Enter 6-digit OTP',
                              icon: Icons.pin_outlined,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'OTP is required';
                                }
                                if (value.trim().length != 6) {
                                  return 'OTP must be 6 digits';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _newPasswordController,
                              label: 'New Password',
                              hint: 'Enter new password',
                              icon: Icons.lock_outline,
                              obscureText: _isPasswordHidden,
                              textInputAction: TextInputAction.next,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isPasswordHidden = !_isPasswordHidden;
                                  });
                                },
                                icon: Icon(
                                  _isPasswordHidden
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Password is required';
                                }
                                if (value.trim().length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _confirmPasswordController,
                              label: 'Confirm Password',
                              hint: 'Re-enter new password',
                              icon: Icons.lock_reset_outlined,
                              obscureText: _isConfirmPasswordHidden,
                              textInputAction: TextInputAction.done,
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _isConfirmPasswordHidden =
                                        !_isConfirmPasswordHidden;
                                  });
                                },
                                icon: Icon(
                                  _isConfirmPasswordHidden
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Confirm password is required';
                                }
                                if (value.trim() !=
                                    _newPasswordController.text.trim()) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  setState(() {
                                    _isStepOne = true;
                                    _otpController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                  });
                                },
                                child: const Text(
                                  'Back to request OTP',
                                  style: TextStyle(
                                    color: AppTheme.textGray,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppButton(
                              text: 'Reset Password',
                              icon: Icons.check_circle_rounded,
                              isLoading: _isLoading,
                              onPressed: _handleResetPassword,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleSwitchChip extends StatelessWidget {
  const _RoleSwitchChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryBlack : AppTheme.lightGray,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppTheme.primaryBlack : AppTheme.borderGray,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 14,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          alignment: Alignment.center,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              color: selected ? Colors.white : AppTheme.primaryBlack,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
