import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/daily_checkin_enums.dart';
import '../bloc/daily_checkin_state.dart';

class CheckinCompletingWidget extends StatelessWidget {
  final DailyCheckinState state;

  const CheckinCompletingWidget({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final status = state.sessionStatus;

    final isComputeDone = status == CheckinSessionStatus.completingSession ||
        status == CheckinSessionStatus.refreshingScore ||
        status == CheckinSessionStatus.completed;
    final isComputeActive = status == CheckinSessionStatus.computingScore ||
        status == CheckinSessionStatus.submitting;

    final isFinalizeDone = status == CheckinSessionStatus.refreshingScore ||
        status == CheckinSessionStatus.completed;
    final isFinalizeActive = status == CheckinSessionStatus.completingSession;

    final isRefreshDone = status == CheckinSessionStatus.completed;
    final isRefreshActive = status == CheckinSessionStatus.refreshingScore;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
              child: const Center(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.5,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Finalizing Check-in',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              state.statusMessage ?? 'Processing your daily wellness data...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 28),

            _buildPipelineStep(
              stepNum: 1,
              title: 'Computing Lung Wellness Score',
              isComplete: isComputeDone,
              isActive: isComputeActive,
            ),
            const SizedBox(height: 10),
            _buildPipelineStep(
              stepNum: 2,
              title: 'Finalizing Check-in Session',
              isComplete: isFinalizeDone,
              isActive: isFinalizeActive,
            ),
            const SizedBox(height: 10),
            _buildPipelineStep(
              stepNum: 3,
              title: 'Synchronizing Score & Baseline',
              isComplete: isRefreshDone,
              isActive: isRefreshActive,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPipelineStep({
    required int stepNum,
    required String title,
    required bool isComplete,
    required bool isActive,
  }) {
    final color = isComplete
        ? AppColors.supportingGreen
        : (isActive ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.4));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isActive ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.15),
            child: isComplete
                ? const Icon(Icons.check_rounded, color: AppColors.supportingGreen, size: 14)
                : (isActive
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                        ),
                      )
                    : Text('$stepNum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive || isComplete ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
                color: isComplete || isActive ? AppColors.text : AppColors.textSecondary,
              ),
            ),
          ),
          if (isComplete)
            const Text(
              'Done ✓',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.supportingGreen),
            )
          else if (isActive)
            const Text(
              'In Progress...',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
