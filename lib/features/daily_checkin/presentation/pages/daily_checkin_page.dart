import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_event.dart';
import '../../../analytics/presentation/bloc/analytics_bloc.dart';
import '../../../analytics/presentation/bloc/analytics_event.dart';
import '../bloc/daily_checkin_bloc.dart';
import '../bloc/daily_checkin_enums.dart';
import '../bloc/daily_checkin_event.dart';
import '../bloc/daily_checkin_state.dart';
import '../widgets/checkin_progress_header.dart';
import '../widgets/checkin_start_widget.dart';
import '../widgets/checkin_recording_widget.dart';
import '../widgets/checkin_symptoms_widget.dart';
import '../widgets/checkin_review_widget.dart';
import '../widgets/checkin_completing_widget.dart';
import '../widgets/checkin_completion_widget.dart';

class DailyCheckinPage extends StatelessWidget {
  const DailyCheckinPage({super.key});

  void _onExit(BuildContext context, DailyCheckinState state) {
    if (state.isSubmitting) return;

    if (state.currentStep == CheckinStep.start ||
        state.currentStep == CheckinStep.completed) {
      _navigateToDashboard(context);
    } else {
      context.read<DailyCheckinBloc>().add(const CheckinGoBackEvent());
    }
  }

  void _navigateToDashboard(BuildContext context) {
    // Refresh dashboard and analytics data before navigating
    context.read<WellnessBloc>().add(const WellnessFetchDataEvent());
    context.read<AnalyticsBloc>().add(const AnalyticsLoadEvent());
    context.go('/dashboard');
  }

  String _getTitle(CheckinStep step) {
    switch (step) {
      case CheckinStep.start:
        return 'Daily Check-in';
      case CheckinStep.cough:
        return 'Cough Recording';
      case CheckinStep.breathing:
        return 'Breathing Recording';
      case CheckinStep.symptoms:
        return 'Daily Symptoms';
      case CheckinStep.review:
        return 'Review Check-in';
      case CheckinStep.completing:
        return 'Processing...';
      case CheckinStep.completed:
        return 'Check-in Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DailyCheckinBloc, DailyCheckinState>(
      builder: (context, state) {
        final title = _getTitle(state.currentStep);
        final isSubmitting = state.isSubmitting;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _onExit(context, state);
          },
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: Text(title),
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.text,
              elevation: 0.5,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: isSubmitting ? null : () => _onExit(context, state),
              ),
              actions: [
                if (state.currentStep != CheckinStep.completed &&
                    state.currentStep != CheckinStep.start)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                    tooltip: 'Exit to Dashboard',
                    onPressed: isSubmitting
                        ? null
                        : () => _navigateToDashboard(context),
                  ),
              ],
            ),
            body: Column(
              children: [
                // Top Progress Tracker
                CheckinProgressHeader(state: state),

                // Step Body
                Expanded(
                  child: _buildStepBody(context, state),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStepBody(BuildContext context, DailyCheckinState state) {
    switch (state.currentStep) {
      case CheckinStep.start:
        return CheckinStartWidget(
          state: state,
          onStart: () => context.read<DailyCheckinBloc>().add(const CheckinStartEvent()),
        );

      case CheckinStep.cough:
        return CheckinRecordingWidget(
          key: const ValueKey('checkin_cough_step'),
          recordingType: 'cough',
          maxDurationSeconds: 20,
          onCompleted: (result) {
            context.read<DailyCheckinBloc>().add(CheckinCoughCompletedEvent(result));
          },
        );

      case CheckinStep.breathing:
        return CheckinRecordingWidget(
          key: const ValueKey('checkin_breathing_step'),
          recordingType: 'breathing',
          maxDurationSeconds: 30,
          onCompleted: (result) {
            context.read<DailyCheckinBloc>().add(CheckinBreathingCompletedEvent(result));
          },
        );

      case CheckinStep.symptoms:
        return CheckinSymptomsWidget(
          key: const ValueKey('checkin_symptoms_step'),
          initialLog: state.symptomsResult,
          onCompleted: (log) {
            context.read<DailyCheckinBloc>().add(CheckinSymptomsCompletedEvent(log));
          },
        );

      case CheckinStep.review:
        return CheckinReviewWidget(
          state: state,
          onReRecord: (step) {
            context.read<DailyCheckinBloc>().add(CheckinReRecordEvent(step));
          },
          onSubmit: () {
            context.read<DailyCheckinBloc>().add(const CheckinSubmitEvent());
          },
          onRetry: () {
            context.read<DailyCheckinBloc>().add(const CheckinRetrySubmitEvent());
          },
        );

      case CheckinStep.completing:
        return CheckinCompletingWidget(state: state);

      case CheckinStep.completed:
        return CheckinCompletionWidget(
          state: state,
          onReturnToDashboard: () => _navigateToDashboard(context),
        );
    }
  }
}
