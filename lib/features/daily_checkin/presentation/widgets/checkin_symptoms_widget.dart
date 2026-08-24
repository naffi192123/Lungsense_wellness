import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_event.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

class CheckinSymptomsWidget extends StatefulWidget {
  final DailyLogEntity? initialLog;
  final ValueChanged<DailyLogEntity> onCompleted;

  const CheckinSymptomsWidget({
    super.key,
    this.initialLog,
    required this.onCompleted,
  });

  @override
  State<CheckinSymptomsWidget> createState() => _CheckinSymptomsWidgetState();
}

class _CheckinSymptomsWidgetState extends State<CheckinSymptomsWidget> {
  DateTime _selectedDate = DateTime.now();

  double _breathlessness = 0.0;
  double _activityLimitation = 0.0;
  double _changeFromUsual = 0.0;
  double _fever = 0.0;
  double _chestTightness = 0.0;
  double _chestDiscomfortBreathing = 0.0;
  double _wheezing = 0.0;
  double _coughSeverity = 0.0;
  double _mucus = 0.0;
  double _sleepDisruption = 0.0;
  double _chestPain = 0.0;
  bool _smokedToday = false;
  double _exerciseMinutes = 30.0;
  double _sleepHours = 7.5;
  double _waterIntakeLiters = 2.0;

  @override
  void initState() {
    super.initState();
    final log = widget.initialLog;
    if (log != null) {
      _breathlessness = log.breathlessness;
      _activityLimitation = log.activityLimitation;
      _changeFromUsual = log.changeFromUsual;
      _fever = log.fever;
      _chestTightness = log.chestTightness;
      _chestDiscomfortBreathing = log.chestDiscomfortBreathing;
      _wheezing = log.wheezing;
      _coughSeverity = log.coughSeverity;
      _mucus = log.mucus;
      _sleepDisruption = log.sleepDisruption;
      _chestPain = log.chestPain;
      _smokedToday = log.smokedToday;
      _exerciseMinutes = log.exerciseMinutes;
      _sleepHours = log.sleepHours;
      _waterIntakeLiters = log.waterIntakeLiters;
      _selectedDate = log.timestamp;
    }
  }

  void _saveAndContinue() {
    final dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    final log = DailyLogEntity(
      id: widget.initialLog?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      checkinDate: dateStr,
      breathlessness: _breathlessness.clamp(0.0, 3.0),
      activityLimitation: _activityLimitation.clamp(0.0, 3.0),
      changeFromUsual: _changeFromUsual.clamp(0.0, 3.0),
      fever: _fever.clamp(0.0, 3.0),
      chestTightness: _chestTightness.clamp(0.0, 3.0),
      chestDiscomfortBreathing: _chestDiscomfortBreathing.clamp(0.0, 3.0),
      wheezing: _wheezing.clamp(0.0, 3.0),
      coughSeverity: _coughSeverity.clamp(0.0, 3.0),
      mucus: _mucus.clamp(0.0, 3.0),
      sleepDisruption: _sleepDisruption.clamp(0.0, 3.0),
      chestPain: _chestPain.clamp(0.0, 3.0),
      smokedToday: _smokedToday,
      exerciseMinutes: _exerciseMinutes,
      sleepHours: _sleepHours,
      waterIntakeLiters: _waterIntakeLiters,
      timestamp: _selectedDate,
    );

    // Save to repository via WellnessBloc
    context.read<WellnessBloc>().add(WellnessSaveDailyLogEvent(log));

    // Advance daily checkin workflow
    widget.onCompleted(log);
  }

  String _getSeverityLabel(int value) {
    switch (value) {
      case 0:
        return 'None';
      case 1:
        return 'Mild';
      case 2:
        return 'Moderate';
      case 3:
        return 'Severe';
      default:
        return 'None';
    }
  }

  Color _getSeverityColor(int value) {
    switch (value) {
      case 0:
        return AppColors.supportingGreen;
      case 1:
        return Colors.blue;
      case 2:
        return Colors.orange;
      case 3:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header info
          _buildHeader(),
          const SizedBox(height: 20),

          // Symptoms 0-3
          _buildSectionTitle('Respiratory & Physical Symptoms (0 - 3)'),
          const SizedBox(height: 12),

          _buildSliderCard(
            title: 'Cough Severity',
            subtitle: 'Dry or productive coughing',
            value: _coughSeverity,
            icon: Icons.sick_outlined,
            onChanged: (val) => setState(() => _coughSeverity = val),
          ),
          const SizedBox(height: 12),

          _buildSliderCard(
            title: 'Breathlessness',
            subtitle: 'Shortness of breath level',
            value: _breathlessness,
            icon: Icons.air_rounded,
            onChanged: (val) => setState(() => _breathlessness = val),
          ),
          const SizedBox(height: 12),

          _buildSliderCard(
            title: 'Chest Tightness',
            subtitle: 'Feeling of pressure or tightness',
            value: _chestTightness,
            icon: Icons.compress_rounded,
            onChanged: (val) => setState(() => _chestTightness = val),
          ),
          const SizedBox(height: 12),

          _buildSliderCard(
            title: 'Chest Discomfort Breathing',
            subtitle: 'Discomfort when taking deep breaths',
            value: _chestDiscomfortBreathing,
            icon: Icons.medical_services_outlined,
            onChanged: (val) => setState(() => _chestDiscomfortBreathing = val),
          ),
          const SizedBox(height: 12),

          _buildSliderCard(
            title: 'Wheezing',
            subtitle: 'High-pitched whistling sound',
            value: _wheezing,
            icon: Icons.insights_rounded,
            onChanged: (val) => setState(() => _wheezing = val),
          ),
          const SizedBox(height: 12),

          _buildSliderCard(
            title: 'Mucus Production',
            subtitle: 'Phlegm or sputum level',
            value: _mucus,
            icon: Icons.water_drop_outlined,
            onChanged: (val) => setState(() => _mucus = val),
          ),
          const SizedBox(height: 12),

          _buildSliderCard(
            title: 'Chest Pain',
            subtitle: 'Localized chest soreness or pain',
            value: _chestPain,
            icon: Icons.heart_broken_outlined,
            onChanged: (val) => setState(() => _chestPain = val),
          ),
          const SizedBox(height: 12),

          _buildSliderCard(
            title: 'Fever Severity',
            subtitle: 'Elevated body temperature feeling',
            value: _fever,
            icon: Icons.thermostat_outlined,
            onChanged: (val) => setState(() => _fever = val),
          ),
          const SizedBox(height: 24),

          // Daily Impact
          _buildSectionTitle('Daily Impact & Disruption (0 - 3)'),
          const SizedBox(height: 12),

          _buildSliderCard(
            title: 'Activity Limitation',
            subtitle: 'Difficulty completing routine activities',
            value: _activityLimitation,
            icon: Icons.directions_walk_rounded,
            onChanged: (val) => setState(() => _activityLimitation = val),
          ),
          const SizedBox(height: 12),

          _buildSliderCard(
            title: 'Change From Usual Baseline',
            subtitle: 'Deviation from your normal state',
            value: _changeFromUsual,
            icon: Icons.published_with_changes_rounded,
            onChanged: (val) => setState(() => _changeFromUsual = val),
          ),
          const SizedBox(height: 12),

          _buildSliderCard(
            title: 'Sleep Disruption',
            subtitle: 'Nighttime waking due to symptoms',
            value: _sleepDisruption,
            icon: Icons.bedtime_outlined,
            onChanged: (val) => setState(() => _sleepDisruption = val),
          ),
          const SizedBox(height: 24),

          // Lifestyle & Habits
          _buildSectionTitle('Lifestyle & Metrics'),
          const SizedBox(height: 12),

          _buildSmokingRadioCard(),
          const SizedBox(height: 12),

          _buildCounterCard(
            title: 'Exercise (Minutes)',
            subtitle: 'Daily physical activity duration',
            value: _exerciseMinutes,
            step: 5,
            min: 0,
            max: 1440,
            unit: 'mins',
            icon: Icons.fitness_center_rounded,
            onChanged: (val) => setState(() => _exerciseMinutes = val),
          ),
          const SizedBox(height: 12),

          _buildCounterCard(
            title: 'Sleep (Hours)',
            subtitle: 'Total sleep time in last 24 hours',
            value: _sleepHours,
            step: 0.5,
            min: 0,
            max: 24,
            unit: 'hrs',
            icon: Icons.nightlight_round,
            onChanged: (val) => setState(() => _sleepHours = val),
          ),
          const SizedBox(height: 12),

          _buildCounterCard(
            title: 'Water Intake (Liters)',
            subtitle: 'Hydration consumed today',
            value: _waterIntakeLiters,
            step: 0.25,
            min: 0,
            max: 20,
            unit: 'L',
            icon: Icons.local_drink_rounded,
            onChanged: (val) => setState(() => _waterIntakeLiters = val),
          ),
          const SizedBox(height: 32),

          // Save & Continue Button
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
              onPressed: _saveAndContinue,
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
                  Icon(Icons.check_circle_outline_rounded, size: 22),
                  SizedBox(width: 8),
                  Text(
                    'Save Symptoms & Continue to Review',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade800.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade800.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.fact_check_outlined,
              color: Colors.amber.shade800,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step 3: Daily Symptoms Log',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Rate how you are feeling today on a 0-3 severity scale.',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String subtitle,
    required double value,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    final intVal = value.toInt().clamp(0, 3);
    final label = _getSeverityLabel(intVal);
    final color = _getSeverityColor(intVal);

    return Container(
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$intVal - $label',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Slider(
            value: value.clamp(0.0, 3.0),
            min: 0,
            max: 3,
            divisions: 3,
            activeColor: color,
            inactiveColor: AppColors.border,
            label: '$intVal ($label)',
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSmokingRadioCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.smoking_rooms_outlined, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Smoked Today?',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2),
                Text(
                  'Tobacco or vape usage',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: const Text('No'),
                selected: !_smokedToday,
                selectedColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: !_smokedToday ? AppColors.surface : AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _smokedToday = false);
                },
              ),
              const SizedBox(width: 6),
              ChoiceChip(
                visualDensity: VisualDensity.compact,
                label: const Text('Yes'),
                selected: _smokedToday,
                selectedColor: AppColors.error,
                labelStyle: TextStyle(
                  color: _smokedToday ? AppColors.surface : AppColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
                onSelected: (selected) {
                  if (selected) setState(() => _smokedToday = true);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCounterCard({
    required String title,
    required String subtitle,
    required double value,
    required double step,
    required double min,
    required double max,
    required String unit,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.primary, size: 22),
                onPressed: value > min ? () => onChanged((value - step).clamp(min, max)) : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: Text(
                  value % 1 == 0 ? '${value.toInt()} $unit' : '${value.toStringAsFixed(1)} $unit',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.text),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary, size: 22),
                onPressed: value < max ? () => onChanged((value + step).clamp(min, max)) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
