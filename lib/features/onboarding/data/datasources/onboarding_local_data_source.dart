import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/onboarding_model.dart';

/// Contract definition for local onboarding draft storage.
abstract class OnboardingLocalDataSource {
  /// Saves current onboarding draft.
  Future<void> saveDraft(OnboardingModel model);

  /// Loads locally cached draft, if any.
  Future<OnboardingModel?> loadDraft();

  /// Deletes the cached onboarding draft.
  Future<void> clearDraft();
}

/// Hive implementation of local onboarding storage.
class OnboardingLocalDataSourceImpl implements OnboardingLocalDataSource {
  final Box box;

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
}
