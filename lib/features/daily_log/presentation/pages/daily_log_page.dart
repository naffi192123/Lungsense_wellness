import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_event.dart';
import '../../../dashboard/presentation/bloc/wellness_state.dart';

/// Screen collecting the user's daily check-in symptoms.
class DailyLogPage extends StatefulWidget {
  const DailyLogPage({super.key});

  @override
  State<DailyLogPage> createState() => _DailyLogPageState();
}

class _DailyLogPageState extends State<DailyLogPage> {
  double _coughSeverity = 3.0;
  double _breathlessness = 2.0;
  bool _chestPain = false;
  bool _fever = false;
  bool _wheezing = false;
  bool _smoking = false;
  double _exerciseMinutes = 45.0;
  double _hydrationLiters = 2.4;
  double _sleepHours = 7.5;
  String _sleepQuality = 'Good';

  void _saveLog() {
    final log = DailyLogEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      coughSeverity: _coughSeverity,
      breathlessness: _breathlessness,
      chestPain: _chestPain,
      fever: _fever,
      wheezing: _wheezing,
      smoking: _smoking,
      exerciseMinutes: _exerciseMinutes,
      hydrationLiters: _hydrationLiters,
      sleepHours: _sleepHours,
      sleepQuality: _sleepQuality,
      timestamp: DateTime.now(),
    );
    
    context.read<WellnessBloc>().add(WellnessSaveDailyLogEvent(log));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Daily Log'),
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
            context.go('/dashboard');
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Intro header
              Text(
                'How are you feeling today? Tracking your symptoms helps us monitor your respiratory health.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
              ),
              const SizedBox(height: 24),

              // Sliders & Forms Card
              _buildFormSection(),
              const SizedBox(height: 24),

              // Save Button
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.supportingGreen],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _saveLog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.surface,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save_outlined, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Save Symptoms',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        // Cough Severity Card
        _buildSliderCard(
          title: 'Cough Severity',
          subtitle: 'Scale: 1 (Mild) - 10 (Severe)',
          value: _coughSeverity,
          min: 1.0,
          max: 10.0,
          divisions: 9,
          icon: Icons.sick_outlined,
          onChanged: (val) => setState(() => _coughSeverity = val),
        ),
        const SizedBox(height: 16),

        // Breathlessness Card
        _buildSliderCard(
          title: 'Breathlessness',
          subtitle: 'Scale: 1 - 10',
          value: _breathlessness,
          min: 1.0,
          max: 10.0,
          divisions: 9,
          icon: Icons.air_rounded,
          onChanged: (val) => setState(() => _breathlessness = val),
        ),
        const SizedBox(height: 16),

        // Toggle list card (Pain, Fever, Wheezing)
        _buildTogglesCard(),
        const SizedBox(height: 16),

        // Smoking Button Card
        _buildSmokingCard(),
        const SizedBox(height: 16),

        // Exercise slider
        _buildExerciseCard(),
        const SizedBox(height: 16),

        // Hydration Counter
        _buildHydrationCard(),
        const SizedBox(height: 16),

        // Sleep details
        _buildSleepCard(),
      ],
    );
  }

  Widget _buildSliderCard({
    required String title,
    required String subtitle,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required IconData icon,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            label: value.toInt().toString(),
            onChanged: onChanged,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(min.toInt().toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(
                value.toInt().toString(),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
              ),
              Text(max.toInt().toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTogglesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          _buildToggleRow(
            title: 'Chest Pain',
            icon: Icons.heart_broken_outlined,
            value: _chestPain,
            onChanged: (val) => setState(() => _chestPain = val),
          ),
          const Divider(color: AppColors.border),
          _buildToggleRow(
            title: 'Fever',
            icon: Icons.thermostat_outlined,
            value: _fever,
            onChanged: (val) => setState(() => _fever = val),
          ),
          const Divider(color: AppColors.border),
          _buildToggleRow(
            title: 'Wheezing',
            icon: Icons.insights_rounded,
            value: _wheezing,
            onChanged: (val) => setState(() => _wheezing = val),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.secondary, size: 22),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.text, fontSize: 14),
              ),
            ],
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.2),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.border,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSmokingCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
              const Icon(Icons.smoke_free_rounded, color: AppColors.text, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Smoking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Did you smoke today?', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _smoking = false),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: !_smoking ? AppColors.supportingGreen.withOpacity(0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: !_smoking ? AppColors.supportingGreen : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'No',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: !_smoking ? AppColors.supportingGreen : AppColors.text,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _smoking = true),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: _smoking ? AppColors.error.withOpacity(0.12) : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: _smoking ? AppColors.error : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Yes',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _smoking ? AppColors.error : AppColors.text,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Exercise', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Minutes of activity', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.health_and_safety_outlined, color: AppColors.supportingGreen, size: 24),
            ],
          ),
          const SizedBox(height: 12),
          Slider(
            value: _exerciseMinutes,
            min: 0.0,
            max: 180.0,
            divisions: 12,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (val) => setState(() => _exerciseMinutes = val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0m', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              Text(
                '${_exerciseMinutes.toInt()} mins',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.supportingGreen, fontSize: 15),
              ),
              const Text('180m', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHydrationCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.local_drink_outlined, color: AppColors.secondary, size: 24),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Hydration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text('Daily target progress', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: AppColors.textSecondary),
                onPressed: () {
                  if (_hydrationLiters > 0.1) {
                    setState(() => _hydrationLiters = double.parse((_hydrationLiters - 0.2).toStringAsFixed(1)));
                  }
                },
              ),
              Text(
                '${_hydrationLiters}L',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.text),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle, color: AppColors.secondary),
                onPressed: () {
                  setState(() => _hydrationLiters = double.parse((_hydrationLiters + 0.2).toStringAsFixed(1)));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSleepCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bedtime_outlined, color: AppColors.primary, size: 24),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sleep Quality', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text('Estimated hours and restfulness', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Text(
                '${_sleepHours} hrs',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _sleepHours,
            min: 4.0,
            max: 12.0,
            divisions: 16,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (val) => setState(() => _sleepHours = val),
          ),
          const Divider(color: AppColors.border, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Poor', 'Fair', 'Good', 'Excellent'].map((quality) {
              final isSelected = _sleepQuality == quality;
              return GestureDetector(
                onTap: () => setState(() => _sleepQuality = quality),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    quality,
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
