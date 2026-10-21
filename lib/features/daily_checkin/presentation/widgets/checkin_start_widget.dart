import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/daily_checkin_state.dart';

class CheckinStartWidget extends StatelessWidget {
  final DailyCheckinState state;
  final VoidCallback onStart;

  const CheckinStartWidget({
    super.key,
    required this.state,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    final completedCount = state.completedStepsCount;
    final isPartiallyDone = completedCount > 0;
    final buttonText = isPartiallyDone
        ? (completedCount >= 3 ? 'Review & Complete Check-in' : 'Continue Check-in ($completedCount/4)')
        : 'Start Daily Check-in';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  AppColors.secondary.withValues(alpha: 0.08),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_rounded,
                        color: AppColors.surface,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Daily Check-in',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '4 Guided Steps • ~3 Minutes',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Record your respiratory sounds and log your daily symptoms. The AI engine analyzes acoustic features and computes your comprehensive Lung Wellness Score.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                // Progress counter pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        completedCount >= 3
                            ? Icons.check_circle_rounded
                            : Icons.timelapse_rounded,
                        size: 16,
                        color: completedCount >= 3
                            ? AppColors.supportingGreen
                            : AppColors.primary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$completedCount of 4 stages completed',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: completedCount >= 3
                              ? AppColors.supportingGreen
                              : AppColors.text,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text(
            'Check-in Stages',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 14),

          // Stage 1: Cough
          _buildStageCard(
            stepNumber: '1',
            title: 'Cough Sound Recording',
            duration: 'Max 10 seconds',
            description: 'Perform 3-5 distinct coughs into your phone microphone.',
            icon: Icons.sick_outlined,
            isCompleted: state.coughCompleted,
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: 12),

          // Stage 2: Breathing
          _buildStageCard(
            stepNumber: '2',
            title: 'Breathing / Chest Sound',
            duration: 'Max 15 seconds',
            description: 'Take deep, steady inhalations and exhalations.',
            icon: Icons.air_rounded,
            isCompleted: state.breathingCompleted,
            accentColor: AppColors.secondary,
          ),
          const SizedBox(height: 12),

          // Stage 3: Symptoms
          _buildStageCard(
            stepNumber: '3',
            title: 'Symptom & Lifestyle Log',
            duration: '1-2 minutes',
            description: 'Rate breathlessness, cough severity, fever, and daily activity.',
            icon: Icons.fact_check_outlined,
            isCompleted: state.symptomsCompleted,
            accentColor: Colors.amber.shade800,
          ),
          const SizedBox(height: 12),

          // Stage 4: Diagnosis (Optional)
          _buildStageCard(
            stepNumber: '4',
            title: 'Diagnosis (Optional)',
            duration: '< 1 minute',
            description: 'Report a known respiratory diagnosis or skip this step.',
            icon: Icons.medical_information_outlined,
            isCompleted: state.diagnosisCompleted,
            accentColor: Colors.teal.shade700,
          ),
          const SizedBox(height: 32),

          // Start Button
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
              onPressed: onStart,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.surface,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPartiallyDone ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    buttonText,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Disclaimer
          const Center(
            child: Text(
              'LungSense Wellness is for wellness tracking, not medical diagnosis.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStageCard({
    required String stepNumber,
    required String title,
    required String duration,
    required String description,
    required IconData icon,
    required bool isCompleted,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? AppColors.supportingGreen.withValues(alpha: 0.5) : AppColors.border,
          width: isCompleted ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.supportingGreen.withValues(alpha: 0.12)
                  : accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : icon,
                color: isCompleted ? AppColors.supportingGreen : accentColor,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                    ),
                    if (isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.supportingGreen.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Done ✓',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.supportingGreen,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  duration,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
