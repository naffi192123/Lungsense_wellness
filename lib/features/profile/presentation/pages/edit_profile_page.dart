import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../onboarding/data/datasources/onboarding_local_data_source.dart';
import '../../../onboarding/data/models/onboarding_model.dart';
import '../../data/datasources/profile_remote_data_source.dart';

/// Screen allowing the user to view and edit all profile and health lifestyle attributes.
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _occupationController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGender = 'Male';
  String _selectedSmokingStatus = 'Never';
  String _selectedActivityLevel = 'Sedentary';
  final Set<String> _selectedConditions = {};

  final List<String> _availableConditions = [
    'Asthma',
    'COPD',
    'Chronic Bronchitis',
    'Allergies',
    'Hypertension',
    'Diabetes',
  ];

  final List<String> _smokingOptions = [
    'Never',
    'Former',
    'Current',
  ];

  final List<String> _activityOptions = [
    'Sedentary',
    'Lightly Active',
    'Moderately Active',
    'Very Active',
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  double _calculatedBmi = 0.0;

  @override
  void initState() {
    super.initState();
    _heightController.addListener(_recalcBmi);
    _weightController.addListener(_recalcBmi);
    _loadProfile();
  }

  @override
  void dispose() {
    _heightController.removeListener(_recalcBmi);
    _weightController.removeListener(_recalcBmi);
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _occupationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _recalcBmi() {
    final h = double.tryParse(_heightController.text.trim()) ?? 0.0;
    final w = double.tryParse(_weightController.text.trim()) ?? 0.0;
    if (h > 0 && w > 0) {
      final hM = h / 100.0;
      final bmi = w / (hM * hM);
      setState(() {
        _calculatedBmi = double.parse(bmi.toStringAsFixed(1));
      });
    } else {
      if (_calculatedBmi != 0.0) {
        setState(() {
          _calculatedBmi = 0.0;
        });
      }
    }
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      // 1. Fetch remote profile
      final profile = await sl<ProfileRemoteDataSource>().getProfile();

      // 2. Fetch local completed profile draft if available
      final localDraft = await sl<OnboardingLocalDataSource>().loadDraft();

      if (mounted) {
        setState(() {
          _nameController.text = profile.fullName ?? localDraft?.fullName ?? '';
          if (profile.age != null) {
            _ageController.text = profile.age.toString();
          }
          if (profile.heightCm != null && profile.heightCm! > 0) {
            _heightController.text = profile.heightCm! % 1 == 0
                ? profile.heightCm!.toInt().toString()
                : profile.heightCm!.toStringAsFixed(1);
          } else if (localDraft != null && localDraft.height > 0) {
            _heightController.text = localDraft.height.toString();
          }

          if (profile.weightKg != null && profile.weightKg! > 0) {
            _weightController.text = profile.weightKg! % 1 == 0
                ? profile.weightKg!.toInt().toString()
                : profile.weightKg!.toStringAsFixed(1);
          } else if (localDraft != null && localDraft.weight > 0) {
            _weightController.text = localDraft.weight.toString();
          }

          if (profile.gender != null && profile.gender!.isNotEmpty) {
            final g = profile.gender!.toLowerCase();
            _selectedGender = g == 'female' ? 'Female' : (g == 'other' ? 'Other' : 'Male');
          } else if (localDraft != null && localDraft.gender.isNotEmpty) {
            final g = localDraft.gender.toLowerCase();
            _selectedGender = g == 'female' ? 'Female' : (g == 'other' ? 'Other' : 'Male');
          }

          if (localDraft != null) {
            if (localDraft.smokingStatus.isNotEmpty) {
              _selectedSmokingStatus = localDraft.smokingStatus;
            }
            if (localDraft.activityLevel.isNotEmpty) {
              _selectedActivityLevel = localDraft.activityLevel;
            }
            _occupationController.text = localDraft.occupation;
            _notesController.text = localDraft.otherNotes;
            _selectedConditions.addAll(localDraft.selectedConditionIds);
          }

          _recalcBmi();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final fullName = _nameController.text.trim();
      final age = int.tryParse(_ageController.text.trim()) ?? 30;
      final height = double.tryParse(_heightController.text.trim()) ?? 170.0;
      final weight = double.tryParse(_weightController.text.trim()) ?? 70.0;

      // 1. Update backend profile
      await sl<ProfileRemoteDataSource>().updateProfile(
        fullName: fullName.isNotEmpty ? fullName : null,
        age: age,
        gender: _selectedGender.toLowerCase(),
        heightCm: height,
        weightKg: weight,
      );

      // 2. Persist lifestyle attributes locally
      final updatedModel = OnboardingModel(
        fullName: fullName,
        dateOfBirth: DateTime(DateTime.now().year - age, 1, 1).toIso8601String().split('T').first,
        gender: _selectedGender.toLowerCase(),
        height: height,
        weight: weight,
        bmi: _calculatedBmi,
        occupation: _occupationController.text.trim(),
        activityLevel: _selectedActivityLevel,
        smokingStatus: _selectedSmokingStatus,
        selectedConditionIds: _selectedConditions.toList(),
        otherNotes: _notesController.text.trim(),
      );
      await sl<OnboardingLocalDataSource>().saveDraft(updatedModel);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Personal Details
                    _buildSectionHeader('Personal Information', Icons.person_outline_rounded),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Your full name',
                        icon: Icons.badge_outlined,
                        validator: (val) => val == null || val.trim().isEmpty ? 'Name cannot be empty' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _ageController,
                              label: 'Age',
                              hint: 'e.g. 28',
                              icon: Icons.cake_outlined,
                              keyboardType: TextInputType.number,
                              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                final n = int.tryParse(val.trim());
                                if (n == null || n < 1 || n > 120) return '1-120';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildDropdown(
                              label: 'Gender',
                              value: _selectedGender,
                              items: const ['Male', 'Female', 'Other'],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedGender = val);
                              },
                            ),
                          ),
                        ],
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Section 2: Physical Metrics & BMI
                    _buildSectionHeader('Physical Metrics', Icons.monitor_weight_outlined),
                    const SizedBox(height: 12),
                    _buildCard([
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _heightController,
                              label: 'Height (cm)',
                              hint: 'e.g. 175',
                              icon: Icons.height_rounded,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                final n = double.tryParse(val.trim());
                                if (n == null || n < 50 || n > 260) return '50-260 cm';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _weightController,
                              label: 'Weight (kg)',
                              hint: 'e.g. 70',
                              icon: Icons.scale_outlined,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (val) {
                                if (val == null || val.trim().isEmpty) return 'Required';
                                final n = double.tryParse(val.trim());
                                if (n == null || n < 20 || n > 300) return '20-300 kg';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      if (_calculatedBmi > 0) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Calculated BMI:',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text),
                              ),
                              Text(
                                '$_calculatedBmi kg/m²',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ]),
                    const SizedBox(height: 24),

                    // Section 3: Respiratory Health & Smoking
                    _buildSectionHeader('Respiratory Health', Icons.air_rounded),
                    const SizedBox(height: 12),
                    _buildCard([
                      const Text(
                        'Smoking Status',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _smokingOptions.map((opt) {
                          final isSelected = _selectedSmokingStatus == opt;
                          return ChoiceChip(
                            label: Text(opt),
                            selected: isSelected,
                            selectedColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.surface : AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            backgroundColor: AppColors.background,
                            onSelected: (selected) {
                              if (selected) setState(() => _selectedSmokingStatus = opt);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Pre-existing Respiratory Conditions',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _availableConditions.map((cond) {
                          final isSelected = _selectedConditions.contains(cond);
                          return FilterChip(
                            label: Text(cond),
                            selected: isSelected,
                            selectedColor: AppColors.primary.withOpacity(0.18),
                            checkmarkColor: AppColors.primary,
                            labelStyle: TextStyle(
                              color: isSelected ? AppColors.primary : AppColors.text,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            backgroundColor: AppColors.background,
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  _selectedConditions.add(cond);
                                } else {
                                  _selectedConditions.remove(cond);
                                }
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    // Section 4: Lifestyle & Notes
                    _buildSectionHeader('Lifestyle & Occupation', Icons.work_outline_rounded),
                    const SizedBox(height: 12),
                    _buildCard([
                      _buildTextField(
                        controller: _occupationController,
                        label: 'Occupation',
                        hint: 'e.g. Software Engineer, Teacher',
                        icon: Icons.work_outline_rounded,
                      ),
                      const SizedBox(height: 16),
                      _buildDropdown(
                        label: 'Activity Level',
                        value: _selectedActivityLevel,
                        items: _activityOptions,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedActivityLevel = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _notesController,
                        label: 'Other Health Notes',
                        hint: 'Allergies, family history, or medications...',
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                    ]),
                    const SizedBox(height: 32),

                    // Save Changes Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                          elevation: 0,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.surface),
                                ),
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, color: AppColors.primary, size: 20) : null,
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: items.contains(value) ? value : items.first,
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        ),
      ],
    );
  }
}
