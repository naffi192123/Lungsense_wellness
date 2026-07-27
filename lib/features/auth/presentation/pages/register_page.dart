import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../onboarding/domain/usecases/check_profile_completed_usecase.dart';

/// The user registration interface matching reference design mockups.
class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;

  // Real-time password validation indicators
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordController.removeListener(_validatePassword);
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final val = _passwordController.text;
    setState(() {
      _hasMinLength = val.length >= 8;
      _hasUppercase = val.contains(RegExp(r'[A-Z]'));
      _hasNumber = val.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = val.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  void _submitForm() {
    if (_formKey.currentState?.validate() ?? false) {
      if (!_agreeToTerms) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please accept the Terms of Service & Privacy Policy.'),
            backgroundColor: AppColors.warning,
          ),
        );
        return;
      }
      
      context.read<AuthBloc>().add(
            AuthRegisterEvent(
              email: _emailController.text.trim(),
              password: _passwordController.text,
              name: _nameController.text.trim(),
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background abstract curves
          Positioned.fill(
            child: CustomPaint(
              painter: _RegisterBackgroundPainter(),
            ),
          ),

          // Scrollable layout
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Horizontal Logo
                    Image.asset(
                      'assets/images/horizontal_logo.png',
                      height: 70,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),

                    // Card container
                    BlocConsumer<AuthBloc, AuthState>(
                      listener: (context, state) {
                        if (state is AuthAuthenticated) {
                          if (!state.user.isEmailVerified) {
                            context.go('/email-verification');
                            return;
                          }
                          sl<CheckProfileCompletedUseCase>().call(const NoParams()).then((result) {
                            result.fold(
                              (failure) => context.go('/onboarding'),
                              (isCompleted) {
                                if (isCompleted) {
                                  context.go('/dashboard');
                                } else {
                                  context.go('/onboarding');
                                }
                              },
                            );
                          });
                        } else if (state is AuthError) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(state.message),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;

                        return Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24.0),
                            border: Border.all(color: AppColors.border, width: 1.0),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.text.withOpacity(0.04),
                                blurRadius: 20.0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(24.0),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Tab header selector (Login / Register)
                                _buildTabHeader(context),
                                // Name Input Field
                                _buildLabel(context, 'Name'),
                                const SizedBox(height: 6),
                                _buildNameField(),
                                const SizedBox(height: 16),

                                // Email Input Field
                                _buildLabel(context, 'Email Address'),
                                const SizedBox(height: 6),
                                _buildEmailField(),
                                const SizedBox(height: 16),

                                // Password Input Field
                                _buildLabel(context, 'Password'),
                                const SizedBox(height: 6),
                                _buildPasswordField(),
                                const SizedBox(height: 12),

                                // Password validation checklist
                                _buildValidationIndicators(),
                                const SizedBox(height: 16),

                                // Confirm Password Input Field
                                _buildLabel(context, 'Confirm Password'),
                                const SizedBox(height: 6),
                                _buildConfirmPasswordField(),
                                const SizedBox(height: 16),

                                // Terms and conditions checkbox
                                _buildTermsRow(),
                                const SizedBox(height: 20),

                                // Submit Create Account Button
                                _buildCreateAccountButton(isLoading),
                                const SizedBox(height: 20),

                                // Already have an account footer
                                _buildLoginFooter(context),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Secure Data badge
                    _buildSecurityBadge(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () => context.go('/login'),
            child: Column(
              children: [
                Text(
                  'Login',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: AppColors.border,
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Column(
            children: [
              Text(
                'Register',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return OutlinedButton(
      onPressed: () {
        context.read<AuthBloc>().add(const AuthGoogleSignInEvent());
      },
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.text,
        side: const BorderSide(color: AppColors.border),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        minimumSize: const Size(double.infinity, 52),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.g_mobiledata_rounded,
            size: 32,
            color: Color(0xFFEA4335),
          ),
          const SizedBox(width: 4),
          Text(
            'Continue with Google',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.text,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Row(
      children: [
        Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }

  Widget _buildLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.text,
          ),
    );
  }

  Widget _buildNameField() {
    return TextFormField(
      controller: _nameController,
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: 'Enter your full name',
        prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.supportingGreen),
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter your name';
        }
        return null;
      },
    );
  }

  Widget _buildEmailField() {
    return TextFormField(
      controller: _emailController,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: 'name@example.com',
        prefixIcon: const Icon(Icons.mail_outline_rounded, color: AppColors.supportingGreen),
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your email address';
        }
        final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
        if (!emailRegex.hasMatch(value)) {
          return 'Please enter a valid email address';
        }
        return null;
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      textInputAction: TextInputAction.next,
      decoration: InputDecoration(
        hintText: 'Create a password',
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.supportingGreen),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter a password';
        }
        if (!_hasMinLength || !_hasUppercase || !_hasNumber || !_hasSpecialChar) {
          return 'Password does not meet validation criteria';
        }
        return null;
      },
    );
  }

  Widget _buildValidationIndicators() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 5,
      children: [
        _buildValidationCheck('At least 8 characters', _hasMinLength),
        _buildValidationCheck('One number', _hasNumber),
        _buildValidationCheck('One uppercase letter', _hasUppercase),
        _buildValidationCheck('One special character', _hasSpecialChar),
      ],
    );
  }

  Widget _buildValidationCheck(String text, bool isValid) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isValid ? AppColors.success : AppColors.border,
          size: 16,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isValid ? AppColors.text : AppColors.textSecondary,
              fontWeight: isValid ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextFormField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      textInputAction: TextInputAction.done,
      onFieldSubmitted: (_) => _submitForm(),
      decoration: InputDecoration(
        hintText: 'Confirm your password',
        prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.supportingGreen),
        suffixIcon: IconButton(
          icon: Icon(
            _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: AppColors.textSecondary,
          ),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please confirm your password';
        }
        if (value != _passwordController.text) {
          return 'Passwords do not match';
        }
        return null;
      },
    );
  }

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 24,
          width: 24,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (val) {
              setState(() {
                _agreeToTerms = val ?? false;
              });
            },
            activeColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              text: 'I agree to the ',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
              children: const [
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateAccountButton(bool isLoading) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.0),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.supportingGreen],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.surface,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2.0),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Create Account',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
      ),
    );
  }

  Widget _buildLoginFooter(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => context.go('/login'),
        child: RichText(
          text: TextSpan(
            text: 'Already have an account? ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
            children: const [
              TextSpan(
                text: 'Login',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.verified_user_outlined,
          color: AppColors.supportingGreen,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          'Your data is secure with us',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.supportingGreen.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}

/// Helper background painter for auth pages.
class _RegisterBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.primary.withOpacity(0.04);

    // Subtle background lines
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.05), 180, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.9), 220, paint);
    
    final wavePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.04),
          AppColors.secondary.withOpacity(0.01),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, size.height * 0.8, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.8, size.width * 0.7, size.height * 0.87)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.9, size.width, size.height * 0.85)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
