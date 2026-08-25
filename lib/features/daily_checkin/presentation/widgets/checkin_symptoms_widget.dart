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

  int _breathlessness = 0;
  int _activityLimitation = 0;
  int _changeFromUsual = 0;
  int _fever = 0;
  int _chestTightness = 0;
  int _chestDiscomfortBreathing = 0;
  int _wheezing = 0;
  int _coughSeverity = 0;
  int _mucus = 0;
  int _sleepDisruption = 0;

  @override
  void initState() {
    super.initState();
    final log = widget.initialLog;
    if (log != null) {
      _breathlessness = log.breathlessness.toInt().clamp(0, 3);
      _activityLimitation = log.activityLimitation.toInt().clamp(0, 3);
      _changeFromUsual = log.changeFromUsual.toInt().clamp(0, 3);
      _fever = log.fever.toInt().clamp(0, 3);
      _chestTightness = log.chestTightness.toInt().clamp(0, 3);
      _chestDiscomfortBreathing = log.chestDiscomfortBreathing.toInt().clamp(0, 3);
      _wheezing = log.wheezing.toInt().clamp(0, 3);
      _coughSeverity = log.coughSeverity.toInt().clamp(0, 3);
      _mucus = log.mucus.toInt().clamp(0, 3);
      _sleepDisruption = log.sleepDisruption.toInt().clamp(0, 3);
      _selectedDate = log.timestamp;
    }
  }

  void _saveAndContinue() {
    final dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    final log = DailyLogEntity(
      id: widget.initialLog?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      checkinDate: dateStr,
      breathlessness: _breathlessness.toDouble(),
      activityLimitation: _activityLimitation.toDouble(),
      changeFromUsual: _changeFromUsual.toDouble(),
      fever: _fever.toDouble(),
      chestTightness: _chestTightness.toDouble(),
      chestDiscomfortBreathing: _chestDiscomfortBreathing.toDouble(),
      wheezing: _wheezing.toDouble(),
      coughSeverity: _coughSeverity.toDouble(),
      mucus: _mucus.toDouble(),
      sleepDisruption: _sleepDisruption.toDouble(),
      chestPain: 0.0,
      smokedToday: false,
      exerciseMinutes: 0.0,
      sleepHours: 8.0,
      waterIntakeLiters: 2.0,
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
        return const Color(0xFF0284C7); // Rich Blue
      case 2:
        return const Color(0xFFD97706); // Warm Amber
      case 3:
        return AppColors.error; // Red
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

          // 1. Breathlessness
          _buildSymptomCard(
            title: 'Breathlessness',
            subtitle: 'Shortness of breath or difficulty breathing',
            icon: Icons.air_rounded,
            currentScore: _breathlessness,
            onChanged: (val) => setState(() => _breathlessness = val),
            customDescriptions: const {
              0: 'Breathing normal & easy',
              1: 'Slight shortness with fast walk',
              2: 'Noticeable breathlessness on stairs',
              3: 'Severe breathlessness even at rest',
            },
          ),
          const SizedBox(height: 16),

          // 2. Activity Limitation
          _buildSymptomCard(
            title: 'Activity Limitation',
            subtitle: 'Trouble walking, climbing stairs, or routine tasks',
            icon: Icons.directions_walk_rounded,
            currentScore: _activityLimitation,
            onChanged: (val) => setState(() => _activityLimitation = val),
            customDescriptions: const {
              0: 'No limitations at all',
              1: 'Slight fatigue with heavy work',
              2: 'Need frequent rest during daily tasks',
              3: 'Unable to do normal daily activities',
            },
          ),
          const SizedBox(height: 16),

          // 3. Change from Usual
          _buildSymptomCard(
            title: 'Change From Usual',
            subtitle: 'How much your breathing deviates from your baseline',
            icon: Icons.published_with_changes_rounded,
            currentScore: _changeFromUsual,
            onChanged: (val) => setState(() => _changeFromUsual = val),
            customDescriptions: const {
              0: 'Same as usual baseline',
              1: 'Slightly worse than usual',
              2: 'Noticeably worse than usual',
              3: 'Much worse than usual baseline',
            },
          ),
          const SizedBox(height: 16),

          // 4. Fever
          _buildSymptomCard(
            title: 'Fever',
            subtitle: 'Feeling feverish, having chills, or elevated temperature',
            icon: Icons.thermostat_outlined,
            currentScore: _fever,
            onChanged: (val) => setState(() => _fever = val),
            customDescriptions: const {
              0: 'No fever (normal body temp)',
              1: 'Mildly warm or slight chills',
              2: 'Definite fever (chills & sweats)',
              3: 'High or persistent fever',
            },
          ),
          const SizedBox(height: 16),

          // 5. Chest Tightness
          _buildSymptomCard(
            title: 'Chest Tightness',
            subtitle: 'Feeling of constriction, heaviness, or pressure in chest',
            icon: Icons.compress_rounded,
            currentScore: _chestTightness,
            onChanged: (val) => setState(() => _chestTightness = val),
            customDescriptions: const {
              0: 'No chest tightness',
              1: 'Occasional slight tightness',
              2: 'Frequent tightness throughout day',
              3: 'Constant, severe chest constriction',
            },
          ),
          const SizedBox(height: 16),

          // 6. Chest Discomfort While Breathing
          _buildSymptomCard(
            title: 'Chest Discomfort While Breathing',
            subtitle: 'Soreness or discomfort specifically when breathing deeply',
            icon: Icons.medical_services_outlined,
            currentScore: _chestDiscomfortBreathing,
            onChanged: (val) => setState(() => _chestDiscomfortBreathing = val),
            customDescriptions: const {
              0: 'No pain or discomfort',
              1: 'Mild discomfort on deep inhale',
              2: 'Noticeable ache when breathing',
              3: 'Severe pain prevents deep breath',
            },
          ),
          const SizedBox(height: 16),

          // 7. Wheezing
          _buildSymptomCard(
            title: 'Wheezing',
            subtitle: 'High-pitched whistling sound when inhaling/exhaling',
            icon: Icons.insights_rounded,
            currentScore: _wheezing,
            onChanged: (val) => setState(() => _wheezing = val),
            customDescriptions: const {
              0: 'No whistling or squeaking',
              1: 'Faint wheeze only with exertion',
              2: 'Clear wheezing sound during day',
              3: 'Loud, constant audible wheezing',
            },
          ),
          const SizedBox(height: 16),

          // 8. Cough Severity
          _buildSymptomCard(
            title: 'Cough Severity',
            subtitle: 'Frequency and intensity of dry or productive coughing',
            icon: Icons.sick_outlined,
            currentScore: _coughSeverity,
            onChanged: (val) => setState(() => _coughSeverity = val),
            customDescriptions: const {
              0: 'No coughing at all',
              1: 'Occasional mild cough',
              2: 'Frequent coughing fits',
              3: 'Severe continuous coughing',
            },
          ),
          const SizedBox(height: 16),

          // 9. Mucus
          _buildSymptomCard(
            title: 'Mucus Production',
            subtitle: 'Excess phlegm, sputum, or congestion in airways',
            icon: Icons.water_drop_outlined,
            currentScore: _mucus,
            onChanged: (val) => setState(() => _mucus = val),
            customDescriptions: const {
              0: 'Clear airways / no mucus',
              1: 'Small amount of clear mucus',
              2: 'Moderate thick or colored phlegm',
              3: 'Heavy persistent phlegm/congestion',
            },
          ),
          const SizedBox(height: 16),

          // 10. Sleep Disruption
          _buildSymptomCard(
            title: 'Sleep Disruption',
            subtitle: 'Trouble sleeping or waking up due to breathing symptoms',
            icon: Icons.bedtime_outlined,
            currentScore: _sleepDisruption,
            onChanged: (val) => setState(() => _sleepDisruption = val),
            customDescriptions: const {
              0: 'Slept soundly all night',
              1: 'Woke up once with symptoms',
              2: 'Woke up 2-3 times during night',
              3: 'Severe insomnia due to breathing',
            },
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
                  blurRadius: 14,
                  offset: const Offset(0, 5),
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
          const SizedBox(height: 28),
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
        borderRadius: BorderRadius.circular(18),
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
                  'Tap your severity level for each respiratory symptom today.',
                  style: TextStyle(
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

  Widget _buildSymptomCard({
    required String title,
    required String subtitle,
    required int currentScore,
    required IconData icon,
    required ValueChanged<int> onChanged,
    required Map<int, String> customDescriptions,
  }) {
    final activeColor = _getSeverityColor(currentScore);
    final label = _getSeverityLabel(currentScore);

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: currentScore > 0 ? activeColor.withValues(alpha: 0.4) : AppColors.border,
          width: currentScore > 0 ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: currentScore > 0
                ? activeColor.withValues(alpha: 0.07)
                : AppColors.text.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Symptom Header Row: Icon + Title/Subtitle + Severity Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: activeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: activeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: activeColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '$label ($currentScore)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: activeColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2x2 Large Severity Option Cards
          Row(
            children: [
              _buildSeverityOption(
                label: 'None',
                score: 0,
                description: customDescriptions[0] ?? 'No symptoms',
                currentScore: currentScore,
                activeColor: _getSeverityColor(0),
                onSelect: onChanged,
              ),
              const SizedBox(width: 10),
              _buildSeverityOption(
                label: 'Mild',
                score: 1,
                description: customDescriptions[1] ?? 'Mild / slight',
                currentScore: currentScore,
                activeColor: _getSeverityColor(1),
                onSelect: onChanged,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildSeverityOption(
                label: 'Moderate',
                score: 2,
                description: customDescriptions[2] ?? 'Moderate / noticeable',
                currentScore: currentScore,
                activeColor: _getSeverityColor(2),
                onSelect: onChanged,
              ),
              const SizedBox(width: 10),
              _buildSeverityOption(
                label: 'Severe',
                score: 3,
                description: customDescriptions[3] ?? 'Severe / intense',
                currentScore: currentScore,
                activeColor: _getSeverityColor(3),
                onSelect: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityOption({
    required String label,
    required int score,
    required String description,
    required int currentScore,
    required Color activeColor,
    required ValueChanged<int> onSelect,
  }) {
    final isSelected = score == currentScore;

    return Expanded(
      child: InkWell(
        onTap: () => onSelect(score),
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withValues(alpha: 0.12) : AppColors.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? activeColor : AppColors.border,
              width: isSelected ? 2.0 : 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: activeColor.withValues(alpha: 0.16),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? activeColor : AppColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? activeColor : AppColors.border.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: 10.5,
                  color: isSelected ? activeColor.withValues(alpha: 0.9) : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
