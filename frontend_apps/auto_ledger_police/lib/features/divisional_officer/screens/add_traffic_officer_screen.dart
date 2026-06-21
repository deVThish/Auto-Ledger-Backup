import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_error_handler.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../services/officer_service.dart';

class AddTrafficOfficerScreen extends StatefulWidget {
  const AddTrafficOfficerScreen({super.key});

  @override
  State<AddTrafficOfficerScreen> createState() =>
      _AddTrafficOfficerScreenState();
}

class _AddTrafficOfficerScreenState extends State<AddTrafficOfficerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _badgeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _officerService = OfficerService();
  final _emailController = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _badgeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateOfficer() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      AppErrorHandler.showPopup(
        context,
        message: 'Please complete the officer details.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _officerService.registerTrafficOfficer(
        name: _nameController.text,
        email: _emailController.text,
        badgeNumber: _badgeController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      _nameController.clear();
      _badgeController.clear();
      _passwordController.clear();
      _confirmPasswordController.clear();
      _emailController.clear();

      AppErrorHandler.showPopup(
        context,
        message: 'Traffic officer created successfully.',
        isError: false,
      );

      if (mounted) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) Navigator.of(context).pop(true);
        });
      }
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
        message: 'Unable to create traffic officer. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Add Traffic Officer',
          style: TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
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
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryBlack,
                            AppTheme.primaryBlack.withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlack.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.person_add_alt_1_outlined,
                            color: Colors.white,
                            size: 34,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Register New Officer',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Create a traffic officer account',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: AppTheme.primaryBlack.withValues(alpha: 0.12),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(-4, -4),
                              spreadRadius: -2,
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.2),
                              blurRadius: 15,
                              offset: const Offset(4, 4),
                              spreadRadius: -1,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            AppTextField(
                              controller: _nameController,
                              label: 'Officer Name',
                              hint: 'Example: Nimal Perera',
                              icon: Icons.person_outline,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Officer name is required';
                                }
                                if (value.trim().length < 3) {
                                  return 'Officer name is too short';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'Example: officer@police.lk',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
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
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _badgeController,
                              label: 'Badge Number',
                              hint: 'Example: TRF-GALLE-100',
                              icon: Icons.badge_outlined,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Badge number is required';
                                }
                                if (value.trim().length < 4) {
                                  return 'Badge number is too short';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Password',
                              hint: 'Create officer password',
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
                              hint: 'Re-enter password',
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
                                    _passwordController.text.trim()) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            AppButton(
                              text: 'Create Officer',
                              isLoading: _isLoading,
                              onPressed: _handleCreateOfficer,
                            ),
                          ],
                        ),
                      ),
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