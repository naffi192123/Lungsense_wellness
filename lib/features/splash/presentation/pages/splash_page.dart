import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';
import '../bloc/splash_state.dart';
import '../../../../core/theme/app_colors.dart';

/// Splash screen matching the reference design:
/// Logo_square.png centred + LungSense wordmark + tagline + 3 feature bubbles + DigiBiomics footer.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
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
            // Decorative background blobs + leaves
            Positioned.fill(
              child: CustomPaint(painter: _SplashBackgroundPainter()),
            ),

            // Foreground content
            SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Central logo (contains LungSense WELLNESS)
                  Expanded(
                    child: Center(
                      child: Image.asset(
                        'assets/images/logo_square.png',
                        width: 250,
                        height: 250,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(width: 250, height: 250),
                      ),
                    ),
                  ),

                  // Three feature bubbles
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildFeatureBubble(
                          icon: Icons.calendar_today_outlined,
                          iconColor: AppColors.supportingGreen,
                          label: 'Daily Tracking',
                          isScore: false,
                        ),
                        _buildFeatureBubble(
                          icon: Icons.circle_outlined,
                          iconColor: AppColors.secondary,
                          label: 'Lung Wellness\nScore',
                          isScore: true,
                          score: '82',
                        ),
                        _buildFeatureBubble(
                          icon: Icons.lightbulb_outline_rounded,
                          iconColor: AppColors.accent,
                          label: 'Smart Insights',
                          isScore: false,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // POWERED BY + DigiBiomics logo
                  _buildFooter(),

                  const SizedBox(height: 28),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildFeatureBubble({
    required IconData icon,
    required Color iconColor,
    required String label,
    required bool isScore,
    String? score,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          painter: _DashedCirclePainter(color: iconColor.withValues(alpha: 0.40)),
          child: SizedBox(
            width: 76,
            height: 76,
            child: Center(
              child: isScore && score != null
                  ? _buildScoreBubble(score, iconColor)
                  : Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 26),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.text,
            height: 1.35,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreBubble(String score, Color ringColor) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: _ScoreRingPainter(color: ringColor),
            size: const Size(56, 56),
          ),
          Text(
            score,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: ringColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'POWERED BY',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.5,
            color: AppColors.textSecondary.withValues(alpha: 0.65),
          ),
        ),
        const SizedBox(height: 10),
        Image.asset(
          'assets/images/digibiomics_logo.png',
          height: 32,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) =>
              const SizedBox(height: 32),
        ),
      ],
    );
  }
}

// Dashed circle painter
class _DashedCirclePainter extends CustomPainter {
  final Color color;
  const _DashedCirclePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;
    const dashCount = 24;
    const dashAngle = 2 * math.pi / dashCount;
    const gapFraction = 0.4;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle * (1 - gapFraction);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedCirclePainter old) => old.color != color;
}

// Score ring painter (270 degree arc)
class _ScoreRingPainter extends CustomPainter {
  final Color color;
  const _ScoreRingPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi * 0.75,
      math.pi * 1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreRingPainter old) => old.color != color;
}

// Background painter with blobs and floating leaves
class _SplashBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left teal blob
    final tealPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;
    final tealPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(size.width * 0.05, 0, size.width * 0.22, size.height * 0.05,
          size.width * 0.20, size.height * 0.12)
      ..cubicTo(size.width * 0.17, size.height * 0.19, 0, size.height * 0.17,
          0, size.height * 0.13)
      ..close();
    canvas.drawPath(tealPath, tealPaint);

    // Top-right lavender blob
    final lavPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.15)
      ..style = PaintingStyle.fill;
    final lavPath = Path()
      ..moveTo(size.width, 0)
      ..cubicTo(size.width, size.height * 0.02, size.width * 0.80,
          size.height * 0.08, size.width * 0.82, size.height * 0.14)
      ..cubicTo(size.width * 0.84, size.height * 0.21, size.width,
          size.height * 0.18, size.width, size.height * 0.14)
      ..close();
    canvas.drawPath(lavPath, lavPaint);

    // Bottom-left green blob
    final greenPaint = Paint()
      ..color = AppColors.primary.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final greenPath = Path()
      ..moveTo(0, size.height)
      ..cubicTo(size.width * 0.10, size.height * 0.88, size.width * 0.28,
          size.height * 0.92, size.width * 0.22, size.height)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // Bottom-right lavender blob
    final lavBottomPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.10)
      ..style = PaintingStyle.fill;
    final lavBottomPath = Path()
      ..moveTo(size.width, size.height)
      ..cubicTo(size.width * 0.85, size.height * 0.90, size.width * 0.70,
          size.height * 0.94, size.width * 0.72, size.height)
      ..close();
    canvas.drawPath(lavBottomPath, lavBottomPaint);

    // Floating leaves
    _drawLeaf(canvas, Offset(size.width * 0.14, size.height * 0.20),
        AppColors.primary.withValues(alpha: 0.50), 11, 0.6);
    _drawLeaf(canvas, Offset(size.width * 0.88, size.height * 0.23),
        AppColors.supportingGreen.withValues(alpha: 0.45), 9, -0.4);
    _drawLeaf(canvas, Offset(size.width * 0.05, size.height * 0.32),
        AppColors.primary.withValues(alpha: 0.30), 7, 1.0);
  }

  void _drawLeaf(Canvas canvas, Offset center, Color color, double leafSize, double rotation) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final path = Path()
      ..moveTo(0, -leafSize)
      ..cubicTo(leafSize * 0.8, -leafSize * 0.4, leafSize * 0.8, leafSize * 0.4, 0, leafSize)
      ..cubicTo(-leafSize * 0.8, leafSize * 0.4, -leafSize * 0.8, -leafSize * 0.4, 0, -leafSize)
      ..close();
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
