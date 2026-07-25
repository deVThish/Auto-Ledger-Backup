import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_client.dart';
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

class _AddTrafficOfficerScreenState extends State<AddTrafficOfficerScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _badgeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _emailController = TextEditingController();
  final _officerService = OfficerService();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;
  bool _isLoading = false;
  bool _showValidationErrors = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _badgeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleCreateOfficer() async {
    FocusScope.of(context).unfocus();

    setState(() {
      _showValidationErrors = true;
    });

    if (!_formKey.currentState!.validate()) {
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showValidationErrors = false;
          });
          _formKey.currentState!.validate();
        }
      });
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                iconTheme: const IconThemeData(
                  color: Color(0xFF0B1A30),
                ),
                title: const Text(
                  'Add Traffic Officer',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0B1A30),
                    fontSize: 22,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final horizontalPadding =
                        constraints.maxWidth < 380 ? 20.0 : 24.0;
                    return Theme(
                      data: Theme.of(context).copyWith(
                        inputDecorationTheme: InputDecorationTheme(
                          labelStyle: const TextStyle(
                            color: Color(0xFF0B1A30),
                            fontWeight: FontWeight.w600,
                          ),
                          hintStyle: TextStyle(
                            color: const Color(0xFF0B1A30).withValues(alpha: 0.35),
                            fontWeight: FontWeight.w400,
                          ),
                          suffixIconColor: const Color(0xFF0B1A30),
                          prefixIconColor: const Color(0xFF0B1A30),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                              width: 1.2,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(25),
                            borderSide: const BorderSide(
                              color: Color(0xFF0B1A30),
                              width: 1.8,
                            ),
                          ),
                        ),
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(22),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF0B1A30),
                                        Color(0xFF162A4A),
                                        Color(0xFF0F213C),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      width: 1.2,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF0B1A30)
                                            .withValues(alpha: 0.28),
                                        blurRadius: 24,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(18),
                                          border: Border.all(
                                            color: Colors.white
                                                .withValues(alpha: 0.15),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person_add_alt_1_rounded,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Register New Officer',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 21,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -0.4,
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
                                    padding: const EdgeInsets.all(22),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(28),
                                      border: Border.all(
                                        color: const Color(0xFFE2E8F0),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0B1A30)
                                              .withValues(alpha: 0.04),
                                          blurRadius: 20,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      children: [
                                        AppTextField(
                                          controller: _nameController,
                                          label: 'Officer Name',
                                          hint: 'Nimal Perera',
                                          icon: Icons.person_outline_rounded,
                                          textInputAction: TextInputAction.next,
                                          validator: (value) {
                                            if (!_showValidationErrors) return null;
                                            if (value == null ||
                                                value.trim().isEmpty) {
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
                                          hint: 'officer@police.lk',
                                          icon: Icons.email_outlined,
                                          keyboardType:
                                              TextInputType.emailAddress,
                                          textInputAction: TextInputAction.next,
                                          validator: (value) {
                                            if (!_showValidationErrors) return null;
                                            if (value == null ||
                                                value.trim().isEmpty) {
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
                                          hint: 'TRF-GALLE-100',
                                          icon: Icons.badge_outlined,
                                          textInputAction: TextInputAction.next,
                                          validator: (value) {
                                            if (!_showValidationErrors) return null;
                                            if (value == null ||
                                                value.trim().isEmpty) {
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
                                          hint: 'Enter secure password',
                                          icon: Icons.lock_outline_rounded,
                                          obscureText: _isPasswordHidden,
                                          textInputAction: TextInputAction.next,
                                          suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _isPasswordHidden =
                                                    !_isPasswordHidden;
                                              });
                                            },
                                            icon: Icon(
                                              _isPasswordHidden
                                                  ? Icons.visibility_off_rounded
                                                  : Icons.visibility_rounded,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (!_showValidationErrors) return null;
                                            if (value == null ||
                                                value.trim().isEmpty) {
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
                                                  ? Icons.visibility_off_rounded
                                                  : Icons.visibility_rounded,
                                            ),
                                          ),
                                          validator: (value) {
                                            if (!_showValidationErrors) return null;
                                            if (value == null ||
                                                value.trim().isEmpty) {
                                              return 'Confirm password is required';
                                            }
                                            if (value.trim() !=
                                                _passwordController.text.trim()) {
                                              return 'Passwords do not match';
                                            }
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 26),
                                        AppButton(
                                          text: 'Create Officer',
                                          isLoading: _isLoading,
                                          onPressed: _handleCreateOfficer,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}