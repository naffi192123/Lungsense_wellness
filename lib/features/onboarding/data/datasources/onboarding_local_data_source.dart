import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/onboarding_model.dart';

/// Contract definition for local onboarding draft and profile storage.
abstract class OnboardingLocalDataSource {
  /// Saves current onboarding draft.
  Future<void> saveDraft(OnboardingModel model);

  /// Loads locally cached draft, if any.
  Future<OnboardingModel?> loadDraft();

  /// Deletes the cached onboarding draft.
  Future<void> clearDraft();

  /// Stores completed profile locally.
  Future<void> saveCompletedProfile(OnboardingModel model);

  /// Checks if user has completed onboarding profile locally.
  Future<bool> isProfileCompletedLocally();

  /// Loads the completed local profile.
  Future<OnboardingModel?> getCompletedProfile();
}

/// Hive implementation of local onboarding and profile storage.
class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  final Box box;
  static const String _keyProfileCompleted = 'is_profile_completed';
  static const String _keyCompletedProfileData = 'completed_profile_data';

  OnboardingLocalDataSourceImpl(this.box);

  @override
  Future<void> saveDraft(OnboardingModel model) async {
    await box.put(AppConstants.keyOnboardingDraft, model.toJson());
  }

  @override
  Future<OnboardingModel?> loadDraft() async {
    final rawData = box.get(AppConstants.keyOnboardingDraft);
    if (rawData == null) {
      return null;
    }
    final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(rawData);
    return OnboardingModel.fromJson(jsonMap);
  }

  @override
  Future<void> clearDraft() async {
    await box.delete(AppConstants.keyOnboardingDraft);
  }

  @override
  Future<void> saveCompletedProfile(OnboardingModel model) async {
    await box.put(_keyProfileCompleted, true);
    await box.put(_keyCompletedProfileData, model.toJson());
  }

  @override
  Future<bool> isProfileCompletedLocally() async {
    final flag = box.get(_keyProfileCompleted);
    if (flag == true) return true;
    final profileData = box.get(_keyCompletedProfileData);
    return profileData != null;
  }

  @override
  Future<OnboardingModel?> getCompletedProfile() async {
    final rawData = box.get(_keyCompletedProfileData);
    if (rawData == null) return null;
    final Map<String, dynamic> jsonMap = Map<String, dynamic>.from(rawData);
    return OnboardingModel.fromJson(jsonMap);
  }
}
