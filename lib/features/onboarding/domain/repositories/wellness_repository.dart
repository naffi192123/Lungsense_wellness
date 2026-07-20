import '../entities/wellness_entities.dart';

/// Repository interface for storing and retrieving wellness records locally.
abstract class WellnessRepository {
  /// Save a daily symptoms tracker log.
  Future<void> saveDailyLog(DailyLogEntity log);

  /// Fetch all daily check-in logs.
  Future<List<DailyLogEntity>> getDailyLogs();

  /// Save a recorded audio analysis.
  Future<void> saveAudioAnalysis(AudioAnalysisEntity analysis);

  /// Fetch all respiratory audio analyses.
  Future<List<AudioAnalysisEntity>> getAudioAnalyses();
}
