import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

/// The Welcome Screen shown to unauthenticated users after the Splash Screen.
/// Matches the reference design in resources/Welcome Screen.png.
/// Provides two CTAs:
///   - "Get started" → navigates to Register (replacing the route stack)
///   - "I already have an account" → navigates to Login (replacing the route stack)
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background decorative painter (blobs + dot grid + leaves)
          Positioned.fill(
            child: CustomPaint(
              painter: _WelcomeBackgroundPainter(),
            ),
          ),

          // Main scrollable content
          SafeArea(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.of(context).padding.top,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),

                      // ----- Horizontal Logo -----
                      Image.asset(
                        'assets/images/logo_horizontal.png',
                        height: 72,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 36),

                      // ----- Hero Copy -----
                      _buildHeroCopy(),
                      const SizedBox(height: 36),

                      // ----- Feature Rows -----
                      _buildFeatureRow(
                        iconData: Icons.assignment_turned_in_outlined,
                        iconColor: AppColors.supportingGreen,
                        iconBgColor: AppColors.supportingGreen.withValues(alpha: 0.12),
                        title: 'Simple guided recordings',
                        subtitle: 'Quick, easy step-by-step check-ins.',
                        dotColor: AppColors.supportingGreen,
                      ),
                      const SizedBox(height: 22),
                      _buildFeatureRow(
                        iconData: Icons.trending_up_rounded,
                        iconColor: AppColors.secondary,
                        iconBgColor: AppColors.secondary.withValues(alpha: 0.12),
                        title: 'Personal trends',
                        subtitle: 'See how your breathing changes over time.',
                        dotColor: AppColors.secondary,
                      ),
                      const SizedBox(height: 22),
                      _buildFeatureRow(
                        iconData: Icons.lightbulb_outlined,
                        iconColor: AppColors.accent,
                        iconBgColor: AppColors.accent.withValues(alpha: 0.12),
                        title: 'Helpful next Steps',
                        subtitle: 'Get clear guidance based on your results.',
                        dotColor: AppColors.accent,
                      ),

                      const SizedBox(height: 44),

                      // ----- CTA Buttons -----
                      _buildGetStartedButton(context),
                      const SizedBox(height: 14),
                      _buildAlreadyHaveAccountButton(context),

                      const SizedBox(height: 28),

                      // ----- Medical Disclaimer -----
                      _buildDisclaimer(),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ── Hero Copy ─────────────────────────────────────────────────────────────

  Widget _buildHeroCopy() {
    return Column(
      children: [
        RichText(
          textAlign: TextAlign.center,
          text: const TextSpan(
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.text,
              height: 1.35,
            ),
            children: [
              TextSpan(text: 'Understand your breathing, '),
              TextSpan(
                text: 'one check-in',
                style: TextStyle(color: AppColors.primary),
              ),
              TextSpan(text: ' at a time'),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Record cough and breathing, track symptoms, and follow changes in your respiratory wellness.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  // ── Feature Row ───────────────────────────────────────────────────────────

  Widget _buildFeatureRow({
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required Color dotColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 26),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        // Trailing accent dot
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(left: 8),
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // ── CTA Buttons ───────────────────────────────────────────────────────────

  Widget _buildGetStartedButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.secondary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          // go() replaces the stack — user cannot back-navigate to Welcome from Register
          onTap: () => context.go('/register'),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Get started',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(width: 12),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlreadyHaveAccountButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        // go() replaces the stack — user cannot back-navigate to Welcome from Login
        onPressed: () => context.go('/login'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: Colors.transparent,
        ),
        child: const Text(
          'I already have an account',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  // ── Medical Disclaimer ─────────────────────────────────────────────────────

  Widget _buildDisclaimer() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.supportingGreen.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.health_and_safety_outlined,
            color: AppColors.supportingGreen,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'LungSense does not provide a\nmedical diagnosis',
          textAlign: TextAlign.left,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

// ── Background Painter ─────────────────────────────────────────────────────

/// Paints the abstract blob background matching the Welcome Screen reference:
/// teal blob top-left, lavender blob top-right, subtle dot grid, floating leaves.
class _WelcomeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Top-left teal/green blob
    final tealPaint = Paint()
      ..color = AppColors.secondary.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final tealPath = Path()
      ..moveTo(0, 0)
      ..cubicTo(
        size.width * 0.05, 0,
        size.width * 0.22, size.height * 0.04,
        size.width * 0.20, size.height * 0.13,
      )
      ..cubicTo(
        size.width * 0.17, size.height * 0.20,
        0, size.height * 0.18,
        0, size.height * 0.14,
      )
      ..close();
    canvas.drawPath(tealPath, tealPaint);

    // Top-right lavender blob
    final lavPaint = Paint()
      ..color = AppColors.accent.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    final lavPath = Path()
      ..moveTo(size.width, 0)
      ..cubicTo(
        size.width, size.height * 0.02,
        size.width * 0.80, size.height * 0.08,
        size.width * 0.82, size.height * 0.15,
      )
      ..cubicTo(
        size.width * 0.84, size.height * 0.21,
        size.width, size.height * 0.18,
        size.width, size.height * 0.14,
      )
      ..close();
    canvas.drawPath(lavPath, lavPaint);

    // Subtle dot grid (right half, upper quarter)
    final dotPaint = Paint()
      ..color = AppColors.text.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    const spacing = 18.0;
    const radius = 1.5;
    for (double x = size.width * 0.55; x < size.width - 8; x += spacing) {
      for (double y = 8; y < size.height * 0.42; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, dotPaint);
      }
    }

    // Floating leaf — upper-right
    _drawLeaf(
      canvas,
      Offset(size.width * 0.87, size.height * 0.04),
      AppColors.primary.withValues(alpha: 0.50),
      11,
      -0.4,
    );

    // Floating leaf — right-center
    _drawLeaf(
      canvas,
      Offset(size.width * 0.94, size.height * 0.17),
      AppColors.supportingGreen.withValues(alpha: 0.38),
      8,
      0.35,
    );
  }

  void _drawLeaf(
    Canvas canvas,
    Offset center,
    Color color,
    double leafSize,
    double rotation,
  ) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final path = Path()
      ..moveTo(0, -leafSize)
      ..cubicTo(
        leafSize * 0.8, -leafSize * 0.4,
        leafSize * 0.8, leafSize * 0.4,
        0, leafSize,
      )
      ..cubicTo(
        -leafSize * 0.8, leafSize * 0.4,
        -leafSize * 0.8, -leafSize * 0.4,
        0, -leafSize,
      )
      ..close();

    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
