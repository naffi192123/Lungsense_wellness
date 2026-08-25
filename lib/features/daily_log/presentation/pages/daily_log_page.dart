import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_event.dart';
import '../../../dashboard/presentation/bloc/wellness_state.dart';

/// Interactive Daily Log (Check-ins) screen aligned with backend 0-3 symptom severity schema.
class DailyLogPage extends StatefulWidget {
  const DailyLogPage({super.key});

  @override
  State<DailyLogPage> createState() => _DailyLogPageState();
}

class _DailyLogPageState extends State<DailyLogPage> {
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

  void _saveLog() {
    final dateStr =
        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}";

    final log = DailyLogEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
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

    context.read<WellnessBloc>().add(WellnessSaveDailyLogEvent(log));
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.surface,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Symptoms Log'),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: BlocListener<WellnessBloc, WellnessState>(
        listener: (context, state) {
          if (state.status == WellnessStatus.saveSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Daily log saved successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.read<WellnessBloc>().add(const WellnessFetchDataEvent());
            context.go('/dashboard');
          } else if (state.status == WellnessStatus.error && state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to save log: ${state.errorMessage!}'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: BlocBuilder<WellnessBloc, WellnessState>(
          builder: (context, state) {
            final isSaving = state.status == WellnessStatus.saving;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Picker Card
                  _buildDatePickerCard(context),
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

                  // Save Button
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
                      onPressed: isSaving ? null : _saveLog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        foregroundColor: AppColors.surface,
                        shadowColor: Colors.transparent,
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.0),
                        ),
                      ),
                      child: isSaving
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: AppColors.surface,
                                    strokeWidth: 2,
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Saving Log...',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ],
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_rounded, size: 22),
                                SizedBox(width: 8),
                                Text(
                                  'Save Daily Symptoms',
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
          },
        ),
      ),
    );
  }

  Widget _buildDatePickerCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Check-in Date',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: () => _selectDate(context),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
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
