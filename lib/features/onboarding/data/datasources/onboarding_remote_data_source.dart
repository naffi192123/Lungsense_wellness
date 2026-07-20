import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../../../../core/errors/exceptions.dart';
import '../models/onboarding_model.dart';
import '../../domain/entities/medical_condition_entity.dart';

/// Contract definition for remote onboarding database sync operations.
abstract class OnboardingRemoteDataSource {
  /// Fetch all medical conditions listed dynamically in the database.
  Future<List<MedicalConditionEntity>> fetchMedicalConditions();

  /// Save all profile details (user_profiles, lifestyle_profiles, respiratory_profiles, conditions).
  Future<void> saveOnboarding({required OnboardingModel model, required String userId});

  /// Check completion status flag inside user_profiles table.
  Future<bool> checkProfileCompleted({required String userId});
}

/// Supabase implementation of remote onboarding transactions.
class OnboardingRemoteDataSourceImpl implements OnboardingRemoteDataSource {
  final supabase.SupabaseClient client;

  OnboardingRemoteDataSourceImpl(this.client);

  @override
  Future<List<MedicalConditionEntity>> fetchMedicalConditions() async {
    try {
      final response = await client.from('medical_conditions').select();
      final list = response as List<dynamic>;
      return list.map((item) {
        final map = item as Map<String, dynamic>;
        return MedicalConditionEntity(
          id: map['id'].toString(),
          name: map['name'] as String? ?? '',
          description: map['description'] as String?,
        );
      }).toList();
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> saveOnboarding({required OnboardingModel model, required String userId}) async {
    try {
      // 1. Synchronize user_profiles table
      await client.from('user_profiles').upsert({
        'user_id': userId,
        'full_name': model.fullName,
        'date_of_birth': model.dateOfBirth,
        'gender': model.gender.toLowerCase(),
        'height_cm': model.height,
        'weight_kg': model.weight,
        'bmi': model.bmi,
        'profile_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 2. Synchronize lifestyle_profiles table
      await client.from('lifestyle_profiles').upsert({
        'user_id': userId,
        'activity_level': model.activityLevel,
        'occupation': model.occupation,
        'sleep_hours': model.sleepHours,
        'water_intake': model.waterIntake,
        'exercise_days': model.exerciseDays,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 3. Synchronize respiratory_profiles table
      await client.from('respiratory_profiles').upsert({
        'user_id': userId,
        'smoking_status': model.smokingStatus,
        'notes': model.otherNotes,
        'updated_at': DateTime.now().toIso8601String(),
      });

      // 4. Synchronize user_medical_conditions relationships
      // Remove any existing selections
      await client.from('user_medical_conditions').delete().eq('user_id', userId);

      // Insert current selections
      if (model.selectedConditionIds.isNotEmpty) {
        // Map dynamic ID strings to appropriate database formats (cast depending on schema string/int)
        final rowsToInsert = model.selectedConditionIds.map((conditionId) {
          // Attempt to parse to integer if required by key constraints, else insert as-is
          final dynamic parsedId = int.tryParse(conditionId) ?? conditionId;
          return {
            'user_id': userId,
            'condition_id': parsedId,
          };
        }).toList();
        await client.from('user_medical_conditions').insert(rowsToInsert);
      }
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }

  @override
  Future<bool> checkProfileCompleted({required String userId}) async {
    try {
      final response = await client
          .from('user_profiles')
          .select('profile_completed')
          .eq('user_id', userId)
          .maybeSingle();
      if (response == null) {
        return false;
      }
      final map = response;
      return map['profile_completed'] as bool? ?? false;
    } on supabase.PostgrestException catch (e) {
      throw ServerException(e.message, code: e.code);
    } catch (e) {
      throw ServerException(e.toString());
    }
  }
}
