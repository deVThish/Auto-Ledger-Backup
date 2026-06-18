import 'package:flutter/material.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  LoginRole _selectedRole = LoginRole.trafficOfficer;
  bool _isPasswordHidden = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _loginIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _screenTitle {
    return _selectedRole == LoginRole.divisionalHead
        ? 'Divisional Head Portal'
        : 'Traffic Officer Portal';
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

  String get _helperText {
    return _selectedRole == LoginRole.divisionalHead
        ? 'Use your username and password to enter the Divisional Head portal.'
        : 'Use your badge number and password to enter the Traffic Officer portal.';
  }

  String get _buttonText {
    return _selectedRole == LoginRole.divisionalHead
        ? 'Login as Divisional Head'
        : 'Login as Traffic Officer';
  }

  String get _loginIdRequiredMessage {
    return _selectedRole == LoginRole.divisionalHead
        ? 'Username is required'
        : 'Badge number is required';
  }

  String get _switchHint {
    return _selectedRole == LoginRole.divisionalHead
        ? 'Head login active'
        : 'Officer login active';
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please complete the required fields.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        loginId: _loginIdController.text,
        password: _passwordController.text,
        loginRole: _selectedRole,
      );

      if (!mounted) return;

      final role = response.officer.role.toUpperCase();

      if (role == 'DIVISIONAL_HEAD') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.divisionalDashboard,
          (route) => false,
        );
        return;
      }

      if (role == 'TRAFFIC_OFFICER') {
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRoutes.trafficOfficerDashboard,
          (route) => false,
        );
        return;
      }

      AppErrorHandler.showPopup(
        context,
        message: 'Unsupported officer role: $role',
      );
    } on ApiException catch (error) {
      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: error.message,
      );
    } catch (_) {
      if (!mounted) return;

      AppErrorHandler.showPopup(
        context,
        message: 'Unable to login. Please check your connection.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTrafficOfficer = _selectedRole == LoginRole.trafficOfficer;

    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxHeight < 680;
            final horizontalPadding =
                constraints.maxWidth < 380 ? 22.0 : 28.0;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: isSmallScreen ? 22 : 34),
                          Container(
                            width: 84,
                            height: 84,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  AppTheme.primaryBlack,
                                  Color(0xFF31363F),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.14),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_police_outlined,
                              color: Colors.white,
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 22),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Text(
                              _screenTitle,
                              key: ValueKey<String>(_screenTitle),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppTheme.primaryBlack,
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Secure access for authorized personnel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.textGray,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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
                                    selected:
                                        _selectedRole ==
                                        LoginRole.divisionalHead,
                                    onTap: () {
                                      setState(() {
                                        _selectedRole =
                                            LoginRole.divisionalHead;
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
                                        _selectedRole =
                                            LoginRole.trafficOfficer;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _switchHint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppTheme.textGray,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 22 : 34),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: AppTheme.borderGray,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 26,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Sign in',
                                  style: TextStyle(
                                    color: AppTheme.primaryBlack,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _helperText,
                                  style: const TextStyle(
                                    color: AppTheme.textGray,
                                    fontSize: 13,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                AppTextField(
                                  controller: _loginIdController,
                                  label: _loginLabel,
                                  hint: _loginHint,
                                  icon: Icons.badge_outlined,
                                  textInputAction: TextInputAction.next,
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return _loginIdRequiredMessage;
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                AppTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  hint: 'Enter your password',
                                  icon: Icons.lock_outline,
                                  obscureText: _isPasswordHidden,
                                  textInputAction: TextInputAction.done,
                                  suffixIcon: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordHidden =
                                            !_isPasswordHidden;
                                      });
                                    },
                                    icon: Icon(
                                      _isPasswordHidden
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null ||
                                        value.trim().isEmpty) {
                                      return 'Password is required';
                                    }
                                    if (value.trim().length < 4) {
                                      return 'Password is too short';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                        context,
                                        AppRoutes.forgotPassword,
                                      );
                                    },
                                    child: const Text(
                                      'Forgot Password?',
                                      style: TextStyle(
                                        color: AppTheme.primaryBlack,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                AppButton(
                                  text: _buttonText,
                                  icon: Icons.login_rounded,
                                  isLoading: _isLoading,
                                  onPressed: _handleLogin,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.verified_user_outlined,
                                color: AppTheme.textGray,
                                size: 17,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Authorized police personnel only',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: AppTheme.textGray,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: isSmallScreen ? 24 : 36),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
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