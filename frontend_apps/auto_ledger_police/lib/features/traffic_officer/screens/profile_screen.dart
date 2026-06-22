import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/network/api_client.dart';
import '../../auth/services/auth_service.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _tokenStorage = const TokenStorage();
  final _authService = AuthService();

  bool _isLoading = true;
  bool _isChangingPassword = false;
  bool _isPasswordHidden = true;
  bool _isNewPasswordHidden = true;

  String _name = '';
  String _badgeNumber = '';
  String _email = '';
  String _role = '';

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);

    try {
      final session = await _tokenStorage.getSession();
      if (session != null) {
        setState(() {
          _name = session.officerName;
          _badgeNumber = session.officerBadgeNumber;
          _email = session.officerName; // Email not stored in session
          _role = session.role;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleChangePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      AppErrorHandler.showPopup(
        context,
        message: 'New passwords do not match.',
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      AppErrorHandler.showPopup(
        context,
        message: 'Password must be at least 6 characters.',
      );
      return;
    }

    setState(() => _isChangingPassword = true);

    try {
      await _authService.changePassword(
        oldPassword: _oldPasswordController.text,
        newPassword: _newPasswordController.text,
      );

      _oldPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      AppErrorHandler.showPopup(
        context,
        message: 'Password changed successfully.',
        isError: false,
      );

      if (mounted) {
        setState(() => _isChangingPassword = false);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message: e.message,
      );
      setState(() => _isChangingPassword = false);
    } catch (_) {
      if (!mounted) return;
      AppErrorHandler.showPopup(
        context,
        message: 'Unable to change password. Please try again.',
      );
      setState(() => _isChangingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'My Profile',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        elevation: 0,
        backgroundColor: AppTheme.backgroundWhite,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryBlack,
                  ),
                )
              else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: AppTheme.primaryBlack.withValues(alpha: 0.10),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.primaryBlack,
                              Color(0xFF32363F),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _name.isEmpty ? 'Traffic Officer' : _name,
                        style: const TextStyle(
                          color: AppTheme.primaryBlack,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _badgeNumber.isEmpty ? 'N/A' : _badgeNumber,
                        style: const TextStyle(
                          color: AppTheme.textGray,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlack.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _role.replaceAll('_', ' '),
                          style: const TextStyle(
                            color: AppTheme.primaryBlack,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Change Password',
                  style: TextStyle(
                    color: AppTheme.primaryBlack,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppTheme.primaryBlack.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _oldPasswordController,
                        label: 'Current Password',
                        hint: 'Enter current password',
                        icon: Icons.lock_outline,
                        obscureText: _isPasswordHidden,
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
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        hint: 'Enter new password',
                        icon: Icons.lock_reset_outlined,
                        obscureText: _isNewPasswordHidden,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() {
                              _isNewPasswordHidden = !_isNewPasswordHidden;
                            });
                          },
                          icon: Icon(
                            _isNewPasswordHidden
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter new password',
                        icon: Icons.lock_reset_outlined,
                        obscureText: _isNewPasswordHidden,
                      ),
                      const SizedBox(height: 18),
                      AppButton(
                        text: 'Update Password',
                        isLoading: _isChangingPassword,
                        onPressed: _handleChangePassword,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
              ],
            ],
          ),
        ),
      ),
    );
  }
}