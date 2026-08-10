import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../data/datasources/profile_remote_data_source.dart';

/// Screen allowing the user to view and edit their profile details.
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
  String _selectedGender = 'Male';

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await sl<ProfileRemoteDataSource>().getProfile();
      if (mounted) {
        setState(() {
          _nameController.text = profile.fullName ?? '';
          if (profile.age != null) _ageController.text = profile.age.toString();
          if (profile.heightCm != null) _heightController.text = profile.heightCm!.toStringAsFixed(1);
          if (profile.weightKg != null) _weightController.text = profile.weightKg!.toStringAsFixed(1);
          if (profile.gender != null && profile.gender!.isNotEmpty) {
            _selectedGender = profile.gender![0].toUpperCase() + profile.gender!.substring(1).toLowerCase();
          }
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
      final age = int.tryParse(_ageController.text.trim());
      final height = double.tryParse(_heightController.text.trim());
      final weight = double.tryParse(_weightController.text.trim());

      await sl<ProfileRemoteDataSource>().updateProfile(
        fullName: fullName.isNotEmpty ? fullName : null,
        age: age,
        gender: _selectedGender.toLowerCase(),
        heightCm: height,
        weightKg: weight,
      );

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

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard?tab=4');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Edit Profile'),
          centerTitle: false,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _onBack,
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Full Name
                      _buildTextField(
                        controller: _nameController,
                        label: 'Full Name',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline_rounded,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Full name is required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Age
                      _buildTextField(
                        controller: _ageController,
                        label: 'Age',
                        hint: 'Enter your age (e.g. 32)',
                        icon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Age is required';
                          final a = int.tryParse(val);
                          if (a == null || a < 1 || a > 130) return 'Enter a valid age (1-130)';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Gender Dropdown
                      const Text(
                        'Gender',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedGender,
                            isExpanded: true,
                            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
                            items: const [
                              DropdownMenuItem(value: 'Male', child: Text('Male')),
                              DropdownMenuItem(value: 'Female', child: Text('Female')),
                              DropdownMenuItem(value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedGender = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Height (cm)
                      _buildTextField(
                        controller: _heightController,
                        label: 'Height (cm)',
                        hint: 'Enter height in cm (e.g. 175)',
                        icon: Icons.height_rounded,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Height is required';
                          final h = double.tryParse(val);
                          if (h == null || h < 50 || h > 250) return 'Enter a valid height (50 - 250 cm)';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Weight (kg)
                      _buildTextField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        hint: 'Enter weight in kg (e.g. 70)',
                        icon: Icons.monitor_weight_outlined,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) return 'Weight is required';
                          final w = double.tryParse(val);
                          if (w == null || w < 20 || w > 300) return 'Enter a valid weight (20 - 300 kg)';
                          return null;
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
                        ),
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: AppColors.surface,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16.0),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: AppColors.surface, strokeWidth: 2),
                                )
                              : const Text(
                                  'Save Changes',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surface,
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
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
