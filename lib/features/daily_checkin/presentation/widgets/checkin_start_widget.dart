import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/cough_recording_icon.dart';
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
    final completedCount = (state.coughCompleted ? 1 : 0) +
        (state.breathingCompleted ? 1 : 0) +
        (state.symptomsCompleted ? 1 : 0);
    final isPartiallyDone = completedCount > 0;
    final buttonText = isPartiallyDone
        ? (completedCount >= 3 ? 'Review & Complete Check-in' : 'Continue Check-in ($completedCount/3)')
        : 'Start Daily Check-in';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card with Embedded Start Button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18.0),
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
                            '3 Guided Steps',
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
                const SizedBox(height: 12),
                const Text(
                  'Record your cough and breathing sounds, then report your symptoms to generate your Lung Wellness Score.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
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
                            '$completedCount of 3 stages completed',
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
                const SizedBox(height: 14),
                // Embedded Start Button within the top Daily Check-in Card
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: onStart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      elevation: 2,
                      shadowColor: AppColors.primary.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.0),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isPartiallyDone ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          buttonText,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Check-in Stages',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),

          // Stage 1: Cough
          _buildStageCard(
            stepNumber: '1',
            title: 'Cough Sound Recording',
            description: 'Perform 3-5 distinct coughs into your phone microphone.',
            customIcon: const CoughRecordingIcon(size: 22, color: AppColors.primary),
            isCompleted: state.coughCompleted,
            accentColor: AppColors.primary,
          ),
          const SizedBox(height: 10),

          // Stage 2: Breathing
          _buildStageCard(
            stepNumber: '2',
            title: 'Breathing / Chest Sound',
            description: 'Take deep, steady inhalations and exhalations.',
            icon: Icons.air_rounded,
            isCompleted: state.breathingCompleted,
            accentColor: AppColors.secondary,
          ),
          const SizedBox(height: 10),

          // Stage 3: Symptoms
          _buildStageCard(
            stepNumber: '3',
            title: 'Symptom & Lifestyle Log',
            description: 'Rate breathlessness, cough severity, fever, and daily activity.',
            icon: Icons.fact_check_outlined,
            isCompleted: state.symptomsCompleted,
            accentColor: Colors.amber.shade800,
          ),
          const SizedBox(height: 22),

          // Main Bottom Action Button
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
                  blurRadius: 10,
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
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPartiallyDone ? Icons.play_arrow_rounded : Icons.arrow_forward_rounded,
                    size: 20,
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
          const SizedBox(height: 14),

          // Disclaimer
          const Center(
            child: Text(
              'LungSense Wellness supports wellness tracking and does not provide a medical diagnosis.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStageCard({
    required String stepNumber,
    required String title,
    required String description,
    IconData? icon,
    Widget? customIcon,
    required bool isCompleted,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
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
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.supportingGreen.withValues(alpha: 0.12)
                  : accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isCompleted
                  ? const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.supportingGreen,
                      size: 22,
                    )
                  : (customIcon ??
                      Icon(
                        icon,
                        color: accentColor,
                        size: 22,
                      )),
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
                const SizedBox(height: 3),
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
