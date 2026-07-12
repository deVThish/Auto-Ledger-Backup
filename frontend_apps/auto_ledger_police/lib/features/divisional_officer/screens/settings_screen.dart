import 'dart:ui';
import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  Future<void> _changePassword() async {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    await showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              final old = oldPasswordController.text.trim();
              final newP = newPasswordController.text.trim();
              final confirm = confirmPasswordController.text.trim();

              if (old.isEmpty || newP.isEmpty || confirm.isEmpty) {
                AppErrorHandler.showPopup(context, message: 'Please fill all fields');
                return;
              }
              if (newP.length < 8) {
                AppErrorHandler.showPopup(context, message: 'Password must be at least 8 characters');
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

              setState(() => _isLoading = true);

              try {
                await AuthService().changePassword(
                  oldPassword: old,
                  newPassword: newP,
                );
                if (!context.mounted) return;
                Navigator.pop(dialogContext);
                AppErrorHandler.showPopup(context, message: 'Password changed successfully', isError: false);
              } on ApiException catch (error) {
                AppErrorHandler.showPopup(context, message: error.message);
              } catch (_) {
                AppErrorHandler.showPopup(context, message: 'Unable to change password. Try again.');
              } finally {
                if (context.mounted) setState(() => _isLoading = false);
              }
            }

            InputDecoration glassDecoration(String label, String hint, IconData icon) {
              return InputDecoration(
                labelText: label,
                hintText: hint,
                prefixIcon: Icon(icon, color: AppTheme.textGray),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.18),
                labelStyle: const TextStyle(color: AppTheme.policeBlue, fontWeight: FontWeight.w700),
                hintStyle: const TextStyle(color: AppTheme.textGray, fontWeight: FontWeight.w600),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: AppTheme.policeBlue, width: 1.2),
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
                      border: Border.all(color: Colors.white.withValues(alpha: 0.68)),
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
                          child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 30),
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
                          obscureText: true,
                          decoration: glassDecoration('Current Password', 'Enter current password', Icons.lock_outline_rounded),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: newPasswordController,
                          obscureText: true,
                          decoration: glassDecoration('New Password', 'Enter new password', Icons.lock_reset_rounded),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: confirmPasswordController,
                          obscureText: true,
                          decoration: glassDecoration('Confirm New Password', 'Repeat new password', Icons.verified_user_outlined),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _isLoading ? null : () => Navigator.pop(dialogContext),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.policeBlue,
                                  side: const BorderSide(color: AppTheme.borderGray),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w800)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : submit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.policeBlue,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: _isLoading
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                                    : const Text('Update', style: TextStyle(fontWeight: FontWeight.w800)),
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

    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.policeBlue),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Change Password Card
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppTheme.policeBlue.withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.policeBlue.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      title: const Text(
                        'Change Password',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      subtitle: Text(
                        'Update your login password',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white30,
                        size: 16,
                      ),
                      onTap: _changePassword,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // Version / Footer
              const Spacer(),
              const Center(
                child: Text(
                  'Auto-Ledger Police v1.0.0',
                  style: TextStyle(
                    color: AppTheme.textGray,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}