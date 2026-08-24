import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/daily_checkin_state.dart';

class CheckinCompletionWidget extends StatelessWidget {
  final DailyCheckinState state;
  final VoidCallback onReturnToDashboard;

  const CheckinCompletionWidget({
    super.key,
    required this.state,
    required this.onReturnToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final scoreEntity = state.computedScore;
    final double? lungWellnessScore = scoreEntity?.lungWellnessScore ??
        (scoreEntity?.score != null && scoreEntity!.score > 0
            ? scoreEntity.score.toDouble()
            : null);

    final hasScore = lungWellnessScore != null && lungWellnessScore > 0;
    final displayScoreVal = hasScore ? lungWellnessScore : 0.0;
    final scoreStr = hasScore
        ? (lungWellnessScore % 1 == 0
            ? lungWellnessScore.toInt().toString()
            : lungWellnessScore.toStringAsFixed(1))
        : '--';

    final statusText = hasScore
        ? (displayScoreVal >= 80 ? 'EXCELLENT' : (displayScoreVal >= 60 ? 'FAIR' : 'ATTENTION'))
        : 'COMPLETED';

    final statusColor = hasScore
        ? (displayScoreVal >= 80
            ? AppColors.supportingGreen
            : (displayScoreVal >= 60 ? AppColors.secondary : AppColors.error))
        : AppColors.supportingGreen;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Celebration Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.supportingGreen.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: AppColors.supportingGreen,
                size: 50,
              ),
            ),
          ),
          const SizedBox(height: 18),

          const Text(
            'Check-in Completed!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your daily session has been recorded and finalized.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Score Dial Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: CircularProgressIndicator(
                        value: hasScore ? (displayScoreVal / 100.0) : 1.0,
                        strokeWidth: 8,
                        backgroundColor: AppColors.border,
                        valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          scoreStr,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Today\'s Lung Wellness Score',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                ),
                if (scoreEntity?.message != null && scoreEntity!.message!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    scoreEntity.message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4 Checklist Items Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Session Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 12),
                _buildCheckRow('Cough Audio Recorded & Processed'),
                const SizedBox(height: 8),
                _buildCheckRow('Breathing Audio Recorded & Processed'),
                const SizedBox(height: 8),
                _buildCheckRow('Daily Symptoms & Metrics Logged'),
                const SizedBox(height: 8),
                _buildCheckRow('Lung Wellness Score Computed & Synced'),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // Return to Dashboard Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.supportingGreen],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: onReturnToDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.surface,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.dashboard_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Return to Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCheckRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.supportingGreen, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.text,
            ),
          ),
        ),
      ],
    );
  }
}
