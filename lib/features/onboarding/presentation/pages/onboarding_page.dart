import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/onboarding_bloc.dart';
import '../bloc/onboarding_event.dart';
import '../bloc/onboarding_state.dart';
import '../../domain/entities/onboarding_data.dart';

/// Multi-step Onboarding screen that collects profile data.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _formKeyStep1 = GlobalKey<FormState>();
  final _formKeyStep2 = GlobalKey<FormState>();
  final _formKeyStep3 = GlobalKey<FormState>();

  // Step 1 Controllers
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGender = '';

  // Step 2 Controllers
  final _occupationController = TextEditingController();
  final _exerciseController = TextEditingController();
  String _selectedActivityLevel = '';

  // Step 3 Controllers
  final _notesController = TextEditingController();
  String _selectedSmokingStatus = '';
  final Set<String> _selectedConditionIds = {};

  late final OnboardingBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = sl<OnboardingBloc>();
    _bloc.add(const OnboardingLoadConditionsEvent());
    _bloc.add(const OnboardingLoadDraftEvent());
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _occupationController.dispose();
    _exerciseController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _syncUIFromData(OnboardingData data) {
    if (data.age != null && data.age! > 0) {
      if (_ageController.text != data.age.toString()) {
        _ageController.text = data.age.toString();
      }
    } else if (data.dateOfBirth.isNotEmpty) {
      try {
        final birthDate = DateTime.parse(data.dateOfBirth);
        final today = DateTime.now();
        var age = today.year - birthDate.year;
        if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
          age--;
        }
        if (age > 0 && _ageController.text != age.toString()) {
          _ageController.text = age.toString();
        }
      } catch (_) {}
    }

    final curHeight = double.tryParse(_heightController.text);
    if (data.height > 0 && curHeight != data.height) {
      _heightController.text = data.height % 1 == 0 ? data.height.toInt().toString() : data.height.toString();
    }
    final curWeight = double.tryParse(_weightController.text);
    if (data.weight > 0 && curWeight != data.weight) {
      _weightController.text = data.weight % 1 == 0 ? data.weight.toInt().toString() : data.weight.toString();
    }
    _selectedGender = data.gender.toLowerCase();

    if (_occupationController.text != data.occupation) {
      _occupationController.text = data.occupation;
    }
    _selectedActivityLevel = data.activityLevel;

    if (data.exerciseDays != null && _exerciseController.text != data.exerciseDays.toString()) {
      _exerciseController.text = data.exerciseDays.toString();
    }

    _selectedSmokingStatus = data.smokingStatus;
    if (_notesController.text != data.otherNotes) {
      _notesController.text = data.otherNotes;
    }
    _selectedConditionIds.clear();
    _selectedConditionIds.addAll(data.selectedConditionIds);
  }

  OnboardingData _gatherCurrentData(OnboardingData baseData) {
    final age = int.tryParse(_ageController.text.trim());
    final dob = (age != null && age > 0)
        ? DateTime(DateTime.now().year - age, 1, 1).toIso8601String().split('T').first
        : baseData.dateOfBirth;

    return baseData.copyWith(
      age: age,
      dateOfBirth: dob,
      gender: _selectedGender,
      height: double.tryParse(_heightController.text) ?? 0.0,
      weight: double.tryParse(_weightController.text) ?? 0.0,
      occupation: _occupationController.text.trim(),
      activityLevel: _selectedActivityLevel,
      exerciseDays: int.tryParse(_exerciseController.text.trim()),
      smokingStatus: _selectedSmokingStatus,
      selectedConditionIds: _selectedConditionIds.toList(),
      otherNotes: _notesController.text.trim(),
    );
  }

  void _onStepContinue(OnboardingState state) {
    if (state.currentStep == 1) {
      if (_formKeyStep1.currentState?.validate() ?? false) {
        if (_selectedGender.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select your gender.')),
          );
          return;
        }
        _bloc.add(OnboardingUpdateDataEvent(_gatherCurrentData(state.data)));
        _bloc.add(const OnboardingNextStepEvent());
      }
    } else if (state.currentStep == 2) {
      if (_formKeyStep2.currentState?.validate() ?? false) {
        if (_selectedActivityLevel.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select your activity level.')),
          );
          return;
        }
        _bloc.add(OnboardingUpdateDataEvent(_gatherCurrentData(state.data)));
        _bloc.add(const OnboardingNextStepEvent());
      }
    }
  }

  void _onSubmit(OnboardingState state) {
    if (_formKeyStep3.currentState?.validate() ?? false) {
      if (_selectedSmokingStatus.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select your smoking status.')),
        );
        return;
      }
      _bloc.add(OnboardingUpdateDataEvent(_gatherCurrentData(state.data)));
      _bloc.add(const OnboardingSubmitEvent());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _bloc,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocConsumer<OnboardingBloc, OnboardingState>(
          listener: (context, state) {
            if (state.status == OnboardingStatus.submitSuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Profile setup complete! Welcome to LungSense.'),
                  backgroundColor: AppColors.success,
                ),
              );
              context.go('/dashboard');
            } else if (state.status == OnboardingStatus.error && state.errorMessage != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.errorMessage!),
                  backgroundColor: AppColors.error,
                ),
              );
            }
            _syncUIFromData(state.data);
          },
          builder: (context, state) {
            final isLoading = state.status == OnboardingStatus.submitting;

            return Stack(
              children: [
                // Background waves
                Positioned.fill(
                  child: CustomPaint(
                    painter: _OnboardingBgPainter(),
                  ),
                ),
                
                SafeArea(
                  child: Column(
                    children: [
                      // Header Progress Section
                      _buildHeaderProgress(context, state.currentStep),
                      
                      // Main Onboarding Step form
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                          child: Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.surface,
                                  borderRadius: BorderRadius.circular(24.0),
                                  border: Border.all(color: AppColors.border),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.text.withOpacity(0.02),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(24.0),
                                child: _buildFormContent(state),
                              ),
                              const SizedBox(height: 24),

                              // Bottom Buttons
                              _buildActionButtons(state, isLoading),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeaderProgress(BuildContext context, int step) {
    final double percent = step / 3.0;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Personalize Your Journey',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.text,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Step $step of 3',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ],
              ),
              // Dots indicators
              Row(
                children: List.generate(3, (index) {
                  final isActive = index + 1 == step;
                  return Container(
                    margin: const EdgeInsets.only(left: 6.0),
                    height: 8,
                    width: isActive ? 24 : 8,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4.0),
            child: LinearProgressIndicator(
              value: percent,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormContent(OnboardingState state) {
    switch (state.currentStep) {
      case 1:
        return _buildStep1BasicInfo(state.data);
      case 2:
        return _buildStep2Lifestyle(state.data);
      case 3:
        return _buildStep3Respiratory(state);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStep1BasicInfo(OnboardingData data) {
    return Form(
      key: _formKeyStep1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header Title
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Basic Information',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Age
          _buildLabel('Age'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Enter your age (e.g. 28)',
              prefixIcon: Icon(Icons.cake_outlined, color: AppColors.primary),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your age';
              }
              final age = int.tryParse(value.trim());
              if (age == null || age < 1 || age > 120) {
                return 'Please enter a valid age (1-120)';
              }
              return null;
            },
          ),
          const SizedBox(height: 20),

          // Gender Dropdown
          _buildLabel('Gender'),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedGender.isEmpty ? null : _selectedGender.toLowerCase(),
            hint: const Text('Select'),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            ),
            items: const [
              DropdownMenuItem<String>(value: 'male', child: Text('Male')),
              DropdownMenuItem<String>(value: 'female', child: Text('Female')),
              DropdownMenuItem<String>(value: 'other', child: Text('Other')),
              DropdownMenuItem<String>(value: 'prefer_not_to_say', child: Text('Prefer not to say')),
            ],
            onChanged: (val) {
              setState(() {
                _selectedGender = val ?? '';
              });
            },
          ),
          const SizedBox(height: 20),

          // Height & Weight Rows
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Height (cm)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(hintText: '175'),
                      onChanged: (val) {
                        _bloc.add(OnboardingUpdateDataEvent(_gatherCurrentData(data)));
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height < 50 || height > 250) {
                          return 'Enter valid height (cm)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Weight (kg)'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                      ],
                      decoration: const InputDecoration(hintText: '70'),
                      onChanged: (val) {
                        _bloc.add(OnboardingUpdateDataEvent(_gatherCurrentData(data)));
                      },
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight < 20 || weight > 300) {
                          return 'Enter valid weight (kg)';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Lifestyle(OnboardingData data) {
    return Form(
      key: _formKeyStep2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header Title
          Row(
            children: [
              const Icon(Icons.fitness_center_rounded, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Lifestyle & Work',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Daily Activity Level Selection Tiles
          _buildLabel('Daily Activity Level'),
          const SizedBox(height: 12),
          _buildActivityTile(
            level: 'Sedentary',
            description: 'Little to no exercise, desk job',
            isActive: _selectedActivityLevel == 'Sedentary',
          ),
          const SizedBox(height: 12),
          _buildActivityTile(
            level: 'Moderately Active',
            description: 'Daily walking or light exercise',
            isActive: _selectedActivityLevel == 'Moderately Active',
          ),
          const SizedBox(height: 12),
          _buildActivityTile(
            level: 'Very Active',
            description: 'Regular intense workouts/manual labor',
            isActive: _selectedActivityLevel == 'Very Active',
          ),
          const SizedBox(height: 24),

          // Occupation
          _buildLabel('Occupation'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _occupationController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Enter your occupation',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter your occupation';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Exercise Days / Week
          _buildLabel('Exercise Days / Week'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _exerciseController,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(1),
            ],
            decoration: const InputDecoration(
              hintText: 'e.g. 3 (Optional)',
              prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.primary),
            ),
            validator: (value) {
              if (value != null && value.trim().isNotEmpty) {
                final days = int.tryParse(value.trim());
                if (days == null || days < 0 || days > 7) {
                  return 'Please enter a number between 0 and 7';
                }
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Respiratory(OnboardingState state) {
    return Form(
      key: _formKeyStep3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step Header Title
          Row(
            children: [
              const Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                'Health & Respiratory',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Smoking Status Segmented selection
          _buildLabel('Smoking Status'),
          const SizedBox(height: 12),
          Row(
            children: ['Never', 'Former', 'Current'].map((status) {
              final isSelected = _selectedSmokingStatus == status;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedSmokingStatus = status;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.supportingGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(12.0),
                      border: Border.all(
                        color: isSelected ? AppColors.supportingGreen : AppColors.border,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      status,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.surface : AppColors.text,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Dynamic Medical Conditions Chip Box
          _buildLabel('Existing Conditions'),
          const SizedBox(height: 12),
          if (state.status == OnboardingStatus.loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            )
          else if (state.conditions.isEmpty)
            Text(
              'No conditions listed in database.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            )
          else
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: state.conditions.map((condition) {
                final isSelected = _selectedConditionIds.contains(condition.id);
                return FilterChip(
                  label: Text(condition.name),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withOpacity(0.12),
                  checkmarkColor: AppColors.primary,
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? AppColors.primary : AppColors.text,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedConditionIds.add(condition.id);
                      } else {
                        _selectedConditionIds.remove(condition.id);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          const SizedBox(height: 24),

          // Other Health Notes
          _buildLabel('Other Health Notes'),
          const SizedBox(height: 8),
          TextFormField(
            controller: _notesController,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Enter any other health concerns or notes...',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(OnboardingState state, bool isLoading) {
    final isFinalStep = state.currentStep == 3;

    return Column(
      children: [
        // Continue / Submit button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: LinearGradient(
              colors: isFinalStep
                  ? [AppColors.supportingGreen, AppColors.supportingGreen.withOpacity(0.9)]
                  : [AppColors.primary, AppColors.supportingGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ElevatedButton(
            onPressed: isLoading
                ? null
                : () {
                    if (isFinalStep) {
                      _onSubmit(state);
                    } else {
                      _onStepContinue(state);
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.surface,
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2.0),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isFinalStep ? 'Complete Setup' : 'Continue',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isFinalStep ? Icons.check_circle_outline_rounded : Icons.arrow_forward_rounded,
                        size: 20,
                      ),
                    ],
                  ),
          ),
        ),

        // Back button (Steps 2 and 3)
        if (state.currentStep > 1) ...[
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () {
              // Save draft locally before shifting backwards
              _bloc.add(OnboardingUpdateDataEvent(_gatherCurrentData(state.data)));
              _bloc.add(const OnboardingPreviousStepEvent());
            },
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('BACK'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.text,
        fontSize: 13,
      ),
    );
  }

  Widget _buildActivityTile({
    required String level,
    required String description,
    required bool isActive,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedActivityLevel = level;
        });
      },
      borderRadius: BorderRadius.circular(12.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary.withOpacity(0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isActive ? AppColors.primary : AppColors.border,
            width: isActive ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isActive ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isActive ? AppColors.primary : AppColors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    level,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isActive ? AppColors.primary : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper background painter for onboarding.
class _OnboardingBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = AppColors.primary.withOpacity(0.03);

    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.05), 180, paint);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.9), 220, paint);
    
    final wavePaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = LinearGradient(
        colors: [
          AppColors.primary.withOpacity(0.03),
          AppColors.secondary.withOpacity(0.005),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTRB(0, size.height * 0.8, size.width, size.height));

    final path = Path()
      ..moveTo(0, size.height * 0.85)
      ..quadraticBezierTo(size.width * 0.35, size.height * 0.8, size.width * 0.7, size.height * 0.87)
      ..quadraticBezierTo(size.width * 0.85, size.height * 0.9, size.width, size.height * 0.85)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
