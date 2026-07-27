import 'dart:convert';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/onboarding_model.dart';
import '../../domain/entities/medical_condition_entity.dart';

/// Contract definition for remote onboarding database sync operations.
abstract class OnboardingRemoteDataSource {
  /// Fetch all medical conditions listed dynamically in the database.
  Future<List<MedicalConditionEntity>> fetchMedicalConditions();

  /// Save all profile details.
  Future<void> saveOnboarding({required OnboardingModel model, required String userId});

  /// Check completion status flag.
  Future<bool> checkProfileCompleted({required String userId});
}

/// FastAPI implementation of remote onboarding transactions.
class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final ApiClient apiClient;

  OnboardingRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<MedicalConditionEntity>> fetchMedicalConditions() async {
    // Since the backend does not expose a list of conditions via endpoints,
    // we return a standard static list of common respiratory/medical conditions.
    return const [
      MedicalConditionEntity(id: '1', name: 'Asthma', description: 'Chronic bronchial airway inflammation'),
      MedicalConditionEntity(id: '2', name: 'COPD', description: 'Chronic Obstructive Pulmonary Disease'),
      MedicalConditionEntity(id: '3', name: 'Chronic Bronchitis', description: 'Long-term bronchial tube inflammation'),
      MedicalConditionEntity(id: '4', name: 'Allergies', description: 'Respiratory allergies'),
      MedicalConditionEntity(id: '5', name: 'Hypertension', description: 'High blood pressure'),
      MedicalConditionEntity(id: '6', name: 'Diabetes', description: 'High blood sugar level'),
    ];
  }

  @override
  Future<void> saveOnboarding({required OnboardingModel model, required String userId}) async {
    try {
      final age = _calculateAge(model.dateOfBirth);
      final conditions = model.selectedConditionIds.map((id) {
        if (id == '1') return 'Asthma';
        if (id == '2') return 'COPD';
        if (id == '3') return 'Chronic Bronchitis';
        if (id == '4') return 'Allergies';
        if (id == '5') return 'Hypertension';
        if (id == '6') return 'Diabetes';
        return id;
      }).join(', ');

      final profileUpsert = {
        'age': age,
        'gender': model.gender.toLowerCase(),
        'height_cm': model.height,
        'weight_kg': model.weight,
        'smoking_status': model.smokingStatus,
        'respiratory_conditions': conditions,
        'occupation': model.occupation,
        'activity_level': model.activityLevel,
      };

      final response = await apiClient.put('/profile', body: profileUpsert);

      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        final message = detail is String ? detail : detail.toString();
        throw ServerException(message, code: response.statusCode.toString());
      }

      // If the user's name needs updating, call /auth/me or update local cache
      if (model.fullName.isNotEmpty) {
        await apiClient.updateUserName(model.fullName);
      }
    } catch (e) {
      if (e is ServerException) {
        rethrow;
      }
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> checkProfileCompleted({required String userId}) async {
    try {
      final response = await apiClient.get('/profile');
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 404) {
        return false;
      } else {
        return false;
      }
    } catch (_) {
      return false;
    }
  }

  int _calculateAge(String dob) {
    try {
      final birthDate = DateTime.parse(dob);
      final today = DateTime.now();
      var age = today.year - birthDate.year;
      if (today.month < birthDate.month || (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return 30; // Sensible default fallback
    }
  }
}
