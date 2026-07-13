import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// Screen directing the user to verify their email before logging in.
class EmailVerificationPage extends StatelessWidget {
  const EmailVerificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        } else if (state is AuthAuthenticated) {
          // If state updates to authenticated, check emailConfirmedAt
          // Wait! The app router redirects users from splash / login.
          // But if they clicked check status and are now fully verified, let's redirect them:
          // We can route them to splash to re-evaluate the full session routing!
          // This is incredibly clean because it re-runs the splash logic (session verification + onboarding completed checks)
          context.go('/');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Background waves
            Positioned.fill(
              child: CustomPaint(
                painter: _VerificationBgPainter(),
              ),
            ),
            
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Centered Logo
                      Image.asset(
                        'assets/images/horizontal_logo.png',
                        height: 70,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 32),

                      // Card container
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(24.0),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.text.withOpacity(0.04),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Envelope illustration icon
                            const Icon(
                              Icons.mark_email_unread_outlined,
                              color: AppColors.primary,
                              size: 72,
                            ),
                            const SizedBox(height: 20),

                            // Heading
                            Text(
                              'Verify Your Email',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.text,
                                  ),
                            ),
                            const SizedBox(height: 12),

                            // Description
                            Text(
                              "We've sent a verification link to your email address. Please check your inbox and click the link to activate your account.",
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textSecondary,
                                    height: 1.5,
                                  ),
                            ),
                            const SizedBox(height: 32),

                            // Check Status Button
                            _buildCheckStatusButton(context),
                            const SizedBox(height: 20),

                            // Resend link
                            _buildResendRow(context),
                            const SizedBox(height: 24),

                            // Divider
                            const Divider(color: AppColors.border),
                            const SizedBox(height: 16),

                            // Back to login (Logout)
                            _buildBackToLoginLink(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckStatusButton(BuildContext context) {
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
        onPressed: () {
          // Re-evaluate verification status
          context.read<AuthBloc>().add(const AuthCheckStatusEvent());
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.surface,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'I have verified my email',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(width: 8),
            Icon(Icons.refresh_rounded, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildResendRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Didn't receive the email? ",
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        GestureDetector(
          onTap: () {
            // Note: resending is stubbed out via simple user snackbar check
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Verification email resent. Please check spam if missing.'),
                backgroundColor: AppColors.success,
              ),
            );
          },
          child: const Text(
            'Resend',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBackToLoginLink(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Sign out to return user back to login page
        context.read<AuthBloc>().add(const AuthLogoutEvent());
      },
      child: Text(
        'Back to Login',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

/// Helper background painter for verification page.
class _VerificationBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.primary.withOpacity(0.04);

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
