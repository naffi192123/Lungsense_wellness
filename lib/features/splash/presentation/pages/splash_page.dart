import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';
import '../../../../core/theme/app_colors.dart';

/// The splash page containing app branding and a brief overview of key features.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Dispatch the timer start event to trigger the 3-second delay
    context.read<SplashBloc>().add(const SplashStartTimerEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<SplashBloc, SplashState>(
      listener: (context, state) {
        if (state is SplashNavigateToWelcome) {
          context.go('/welcome');
        } else if (state is SplashNavigateToLogin) {
          context.go('/login');
        } else if (state is SplashNavigateToDashboard) {
          context.go('/dashboard');
        } else if (state is SplashNavigateToVerification) {
          context.go('/email-verification');
        } else if (state is SplashNavigateToOnboarding) {
          context.go('/onboarding');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Stack(
          children: [
            // Abstract background layout elements
            Positioned.fill(
              child: CustomPaint(
                painter: _SplashBackgroundPainter(),
              ),
            ),
            
            // Foreground UI Layout
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(height: 24),
                  
                  // Central Logo section
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/images/logo.png',
                            width: 280,
                            fit: BoxFit.contain,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Three features list row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: _buildFeatureItem(
                            context,
                            iconPath: 'assets/images/ic_daily_tracking.png',
                            label: 'Daily Tracking',
                          ),
                        ),
                        _buildDivider(),
                        Expanded(
                          child: _buildFeatureItem(
                            context,
                            iconPath: 'assets/images/ic_lung_score.png',
                            label: 'Lung Score',
                          ),
                        ),
                        _buildDivider(),
                        Expanded(
                          child: _buildFeatureItem(
                            context,
                            iconPath: 'assets/images/ic_smart_insights.png',
                            label: 'Smart Insights',
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer Section
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Powered by',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Image.asset(
                        'assets/images/digibiomics_logo.png',
                        height: 28,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'www.digibiomics.com',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary.withOpacity(0.8),
                              fontSize: 12,
                              letterSpacing: 0.5,
                            ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Bottom gradient band
                      Container(
                        height: 6,
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary,
                              AppColors.secondary,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required String iconPath,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          iconPath,
          height: 48,
          width: 48,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 8),
        Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.text,
                fontSize: 13,
              ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 48,
      width: 1,
      color: AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
    );
  }
}

/// Custom painter to draw background accent circles and waves to match the reference design.
class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Top Concentric Lines (Soft grey/teal rings)
    paint.color = AppColors.secondary.withOpacity(0.08);
    canvas.drawCircle(Offset(size.width * 0.1, 0), 140, paint);
    canvas.drawCircle(Offset(size.width * 0.1, 0), 200, paint);
    canvas.drawCircle(Offset(size.width * 0.1, 0), 260, paint);

    paint.color = AppColors.primary.withOpacity(0.06);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.05), 110, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.05), 170, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.05), 230, paint);

    // Bottom Waves (filling bottom area with faint green/teal overlays)
    final wavePaint = Paint()..style = PaintingStyle.fill;
    
    // Wave 1 (Secondary Teal)
    wavePaint.shader = LinearGradient(
      colors: [
        AppColors.secondary.withOpacity(0.12),
        AppColors.secondary.withOpacity(0.01),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(0, size.height * 0.7, size.width, size.height));

    final path1 = Path()
      ..moveTo(0, size.height * 0.82)
      ..quadraticBezierTo(
        size.width * 0.25,
        size.height * 0.78,
        size.width * 0.5,
        size.height * 0.83,
      )
      ..quadraticBezierTo(
        size.width * 0.75,
        size.height * 0.88,
        size.width,
        size.height * 0.83,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path1, wavePaint);

    // Wave 2 (Primary Green)
    wavePaint.shader = LinearGradient(
      colors: [
        AppColors.primary.withOpacity(0.08),
        AppColors.primary.withOpacity(0.01),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    ).createShader(Rect.fromLTRB(0, size.height * 0.75, size.width, size.height));

    final path2 = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.88,
        size.width * 0.6,
        size.height * 0.82,
      )
      ..quadraticBezierTo(
        size.width * 0.85,
        size.height * 0.79,
        size.width,
        size.height * 0.81,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
