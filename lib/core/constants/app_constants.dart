/// App-wide constants for names, paths, cache keys, and values.
abstract class AppConstants {
  static const String appName = 'LungSense Wellness';
  
  // Hive Box Names
  static const String userPreferencesBox = 'user_preferences_box';
  static const String wellnessScoreBox = 'wellness_score_box';
  static const String checkInBox = 'check_in_box';
  static const String recordingsBox = 'recordings_box';

  // Hive Keys
  static const String keyFirstTimeUser = 'is_first_time_user';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserProfile = 'user_profile';
  static const String keyOnboardingDraft = 'onboarding_draft';
  
  // Timeout settings
  static const Duration apiTimeout = Duration(seconds: 30);
}
