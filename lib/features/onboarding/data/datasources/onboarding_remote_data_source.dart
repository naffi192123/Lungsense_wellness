import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/onboarding_model.dart';
import '../../domain/entities/medical_condition_entity.dart';

/// Contract definition for remote onboarding database sync operations.
abstract class OnboardingRemoteDataSource {
  /// Fetch all medical conditions listed dynamically in the database.
  Future<List<MedicalConditionEntity>> fetchMedicalConditions();

  /// Save all profile details to backend.
  Future<void> saveOnboarding({required OnboardingModel model, required String userId});

  /// Check completion status flag directly from backend profile.
  Future<bool> checkProfileCompleted({required String userId});
}

/// FastAPI implementation of remote onboarding transactions.
class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final ApiClient apiClient;

  OnboardingRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<MedicalConditionEntity>> fetchMedicalConditions() async {
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
      String gender = model.gender.trim().toLowerCase();
      if (gender != 'male' && gender != 'female') {
        gender = 'other';
      }

      final profileUpsert = <String, dynamic>{
        'age': age,
        'gender': gender,
        'height_cm': model.height > 0 ? model.height : 170.0,
        'weight_kg': model.weight > 0 ? model.weight : 70.0,
      };

      final response = await apiClient.put('/profile', body: profileUpsert);

      if (response.statusCode == 200) {
        if (model.fullName.isNotEmpty) {
          await apiClient.updateUserName(model.fullName);
        }
      } else {
        final message = _extractErrorMessage(response);
        throw ServerException(message, code: response.statusCode.toString());
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
        final data = jsonDecode(response.body);
        if (data is Map) {
          final age = data['age'];
          final gender = data['gender'];
          final height = data['height_cm'];
          final weight = data['weight_kg'];

          final hasAge = age != null && age is num && age > 0;
          final hasGender = gender != null && gender.toString().trim().isNotEmpty;
          final hasHeight = height != null && height is num && height > 0;
          final hasWeight = weight != null && weight is num && weight > 0;

          // Onboarding is completed only when all required inputs are present in the backend profile
          return hasAge && hasGender && hasHeight && hasWeight;
        }
      }
      return false;
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
      if (age < 1) return 18;
      if (age > 130) return 100;
      return age;
    } catch (_) {
      return 30;
    }
  }

  String _extractErrorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);
      if (data is Map) {
        final detail = data['detail'];
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) {
            return first['msg'].toString();
          }
          return detail.toString();
        }
        if (data['message'] != null) return data['message'].toString();
      }
    } catch (_) {}
    return 'Server returned error (${response.statusCode}): ${response.body.isNotEmpty ? response.body : "Request failed"}';
  }
}
