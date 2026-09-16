import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/daily_checkin_enums.dart';
import '../bloc/daily_checkin_state.dart';

class CheckinProgressHeader extends StatelessWidget {
  final DailyCheckinState state;

  const CheckinProgressHeader({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.currentStep == CheckinStep.start ||
        state.currentStep == CheckinStep.completed) {
      return const SizedBox.shrink();
    }

    final coughActive = state.currentStep == CheckinStep.cough;
    final coughDone = state.coughCompleted;

    final breathingActive = state.currentStep == CheckinStep.breathing;
    final breathingDone = state.breathingCompleted;

    final symptomsActive = state.currentStep == CheckinStep.symptoms;
    final symptomsDone = state.symptomsCompleted;

    final diagnosisActive = state.currentStep == CheckinStep.diagnosis;
    final diagnosisDone = state.diagnosisCompleted;

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildStepItem(
                stepNum: '1',
                title: 'Cough',
                isActive: coughActive,
                isDone: coughDone,
                icon: Icons.sick_outlined,
              ),
              _buildConnector(isActive: breathingActive || breathingDone || coughDone),
              _buildStepItem(
                stepNum: '2',
                title: 'Breathing',
                isActive: breathingActive,
                isDone: breathingDone,
                icon: Icons.air_rounded,
              ),
              _buildConnector(isActive: symptomsActive || symptomsDone || breathingDone),
              _buildStepItem(
                stepNum: '3',
                title: 'Symptoms',
                isActive: symptomsActive,
                isDone: symptomsDone,
                icon: Icons.fact_check_outlined,
              ),
              _buildConnector(isActive: diagnosisActive || diagnosisDone || symptomsDone),
              _buildStepItem(
                stepNum: '4',
                title: 'Diagnosis',
                isActive: diagnosisActive,
                isDone: diagnosisDone,
                icon: Icons.medical_information_outlined,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepItem({
    required String stepNum,
    required String title,
    required bool isActive,
    required bool isDone,
    required IconData icon,
  }) {
    Color circleColor;
    Color textColor;
    Widget centerWidget;

    if (isDone) {
      circleColor = AppColors.supportingGreen;
      textColor = AppColors.supportingGreen;
      centerWidget = const Icon(Icons.check, color: AppColors.surface, size: 14);
    } else if (isActive) {
      circleColor = AppColors.primary;
      textColor = AppColors.primary;
      centerWidget = Text(
        stepNum,
        style: const TextStyle(
          color: AppColors.surface,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    } else {
      circleColor = AppColors.border;
      textColor = AppColors.textSecondary;
      centerWidget = Text(
        stepNum,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: circleColor,
              shape: BoxShape.circle,
            ),
            child: Center(child: centerWidget),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnector({required bool isActive}) {
    return Container(
      width: 20,
      height: 2,
      color: isActive ? AppColors.primary : AppColors.border,
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
