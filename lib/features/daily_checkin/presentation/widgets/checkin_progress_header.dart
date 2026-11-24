import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/daily_checkin_enums.dart';
import '../bloc/daily_checkin_state.dart';

/// A horizontally scrollable progress tracker for the Daily Check-in flow.
///
/// - Labels are never truncated (no Expanded/Flexible constraints on the text).
/// - When [state.currentStep] changes, the active step is automatically
///   scrolled into the centre of the visible area.
/// - Completed steps show a green check; the active step is highlighted in
///   primary colour; pending steps are dimmed.
class CheckinProgressHeader extends StatefulWidget {
  final DailyCheckinState state;

  const CheckinProgressHeader({super.key, required this.state});

  @override
  State<CheckinProgressHeader> createState() => _CheckinProgressHeaderState();
}

class _CheckinProgressHeaderState extends State<CheckinProgressHeader> {
  final ScrollController _scrollController = ScrollController();

  // One GlobalKey per visible step so we can call Scrollable.ensureVisible.
  final List<GlobalKey> _stepKeys = List.generate(3, (_) => GlobalKey());

  // ---- step definitions (order matches display order) ---------------------
  static const _steps = [
    _StepDef(label: 'Cough',     step: CheckinStep.cough,     icon: Icons.mic),
    _StepDef(label: 'Breathing', step: CheckinStep.breathing,  icon: Icons.air_rounded),
    _StepDef(label: 'Symptoms',  step: CheckinStep.symptoms,   icon: Icons.fact_check_outlined),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(CheckinProgressHeader oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to the newly active step whenever the step changes.
    if (oldWidget.state.currentStep != widget.state.currentStep) {
      _scrollToActiveStep();
    }
  }

  @override
  void initState() {
    super.initState();
    // After the first frame, centre the initial active step.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToActiveStep());
  }

  void _scrollToActiveStep() {
    final activeIndex = _activeStepIndex();
    if (activeIndex < 0) return;
    final key = _stepKeys[activeIndex];
    if (key.currentContext == null) return;
    Scrollable.ensureVisible(
      key.currentContext!,
      alignment: 0.5, // centre the item in the viewport
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  int _activeStepIndex() {
    for (int i = 0; i < _steps.length; i++) {
      if (_steps[i].step == widget.state.currentStep) return i;
    }
    return -1;
  }

  bool _isDone(CheckinStep step) {
    switch (step) {
      case CheckinStep.cough:
        return widget.state.coughCompleted;
      case CheckinStep.breathing:
        return widget.state.breathingCompleted;
      case CheckinStep.symptoms:
        return widget.state.symptomsCompleted;
      default:
        return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hide the tracker on the start and completed screens.
    if (widget.state.currentStep == CheckinStep.start ||
        widget.state.currentStep == CheckinStep.completed) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SingleChildScrollView(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        // Add symmetric padding so the first / last step can be centred too.
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: _buildStepRow(),
        ),
      ),
    );
  }

  List<Widget> _buildStepRow() {
    final widgets = <Widget>[];

    for (int i = 0; i < _steps.length; i++) {
      final def = _steps[i];
      final isActive = widget.state.currentStep == def.step;
      final isDone = _isDone(def.step);

      widgets.add(
        _StepItem(
          key: _stepKeys[i],
          stepNum: '${i + 1}',
          label: def.label,
          isActive: isActive,
          isDone: isDone,
        ),
      );

      // Add a connector between steps (not after the last one).
      if (i < _steps.length - 1) {
        final nextDone = _isDone(_steps[i + 1].step);
        final connectorActive = isDone || nextDone ||
            widget.state.currentStep == _steps[i + 1].step;
        widgets.add(_Connector(isActive: connectorActive));
      }
    }

    return widgets;
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _StepDef {
  final String label;
  final CheckinStep step;
  final IconData icon;
  const _StepDef({required this.label, required this.step, required this.icon});
}

class _StepItem extends StatelessWidget {
  final String stepNum;
  final String label;
  final bool isActive;
  final bool isDone;

  const _StepItem({
    super.key,
    required this.stepNum,
    required this.label,
    required this.isActive,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    final Color circleColor;
    final Color textColor;
    final Widget circleChild;

    if (isDone) {
      circleColor = AppColors.supportingGreen;
      textColor   = AppColors.supportingGreen;
      circleChild = const Icon(Icons.check, color: AppColors.surface, size: 14);
    } else if (isActive) {
      circleColor = AppColors.primary;
      textColor   = AppColors.primary;
      circleChild = Text(
        stepNum,
        style: const TextStyle(
          color: AppColors.surface,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    } else {
      circleColor = AppColors.border;
      textColor   = AppColors.textSecondary;
      circleChild = Text(
        stepNum,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Circle badge
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          child: Center(child: circleChild),
        ),
        const SizedBox(width: 6),
        // Label — unconstrained so it never truncates
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive || isDone ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
          softWrap: false,
          overflow: TextOverflow.visible,
        ),
      ],
    );
  }
}

class _Connector extends StatelessWidget {
  final bool isActive;
  const _Connector({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isActive ? AppColors.primary : AppColors.border,
    );
  }
}
