import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../data/datasources/profile_remote_data_source.dart';

/// Screen allowing the user to change their password using backend OTP verification.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _otpSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final email = sl<ApiClient>().userEmail;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No authenticated user email found.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await sl<ProfileRemoteDataSource>().requestPasswordReset(email);
      if (mounted) {
        setState(() {
          _otpSent = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verification code sent to $email'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send code: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _submitReset() async {
    if (!_formKey.currentState!.validate()) return;

    final email = sl<ApiClient>().userEmail;
    if (email == null || email.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await sl<ProfileRemoteDataSource>().resetPassword(
        email: email,
        otpCode: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update password: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard?tab=4');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = sl<ApiClient>().userEmail ?? 'your email';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Change Password'),
          centerTitle: false,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _onBack,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppColors.primary, size: 24),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          _otpSent
                              ? 'Enter the 6-digit code sent to $email along with your new password.'
                              : 'To protect your account, tap the button below to receive a 6-digit verification code at $email.',
                          style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (!_otpSent) ...[
                  // Send OTP Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.supportingGreen],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.surface,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2),
                            )
                          : const Text(
                              'Send Verification Code',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ] else ...[
                  // OTP Code Field
                  const Text('Verification Code', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
                    validator: (val) {
                      if (val == null || val.trim().length < 6) return 'Enter the 6-digit code';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: '6-digit OTP code',
                      prefixIcon: const Icon(Icons.pin_outlined, color: AppColors.primary, size: 20),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // New Password Field
                  const Text('New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    validator: (val) {
                      if (val == null || val.length < 6) return 'Password must be at least 6 characters';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'At least 6 characters',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 20),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  const Text('Confirm New Password', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    validator: (val) {
                      if (val != _newPasswordController.text) return 'Passwords do not match';
                      return null;
                    },
                    decoration: InputDecoration(
                      hintText: 'Re-enter your new password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: AppColors.textSecondary, size: 20),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Update Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.0),
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.supportingGreen],
                      ),
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitReset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.surface,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2),
                            )
                          : const Text(
                              'Update Password',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
