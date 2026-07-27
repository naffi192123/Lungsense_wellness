import 'package:hive_flutter/hive_flutter.dart';
import '../../../daily_log/data/datasources/daily_log_remote_data_source.dart';
import '../../domain/entities/wellness_entities.dart';
import '../../domain/repositories/wellness_repository.dart';

/// Implementation of WellnessRepository using Hive storage boxes and optional remote sync.
class WellnessRepositoryImpl implements WellnessRepository {
  final Box checkInBox;
  final Box recordingsBox;
  final DailyLogRemoteDataSource? dailyLogRemoteDataSource;

  WellnessRepositoryImpl({
    required this.checkInBox,
    required this.recordingsBox,
    this.dailyLogRemoteDataSource,
  });

  @override
  Future<void> saveDailyLog(DailyLogEntity log) async {
    final map = _dailyLogToMap(log);
    await checkInBox.put(log.id, map);

    if (dailyLogRemoteDataSource != null) {
      try {
        await dailyLogRemoteDataSource!.createCheckIn(
          coughSeverity: log.coughSeverity.round(),
          shortnessOfBreath: log.breathlessness.round(),
          fatigueLevel: log.sleepQuality.toLowerCase() == 'poor' ? 7 : 3,
          symptomsDescription: 'Cough: ${log.coughSeverity}, Breathlessness: ${log.breathlessness}',
        );
      } catch (_) {}
    }
  }

  @override
  Future<List<DailyLogEntity>> getDailyLogs() async {
    if (dailyLogRemoteDataSource != null) {
      try {
        final remoteLogs = await dailyLogRemoteDataSource!.getCheckIns();
        for (var remote in remoteLogs) {
          final entity = DailyLogEntity(
            id: remote.id,
            coughSeverity: remote.coughSeverity.toDouble(),
            breathlessness: remote.shortnessOfBreath.toDouble(),
            chestPain: false,
            fever: false,
            wheezing: false,
            smoking: false,
            exerciseMinutes: 30,
            hydrationLiters: 2.0,
            sleepHours: 8.0,
            sleepQuality: remote.fatigueLevel > 5 ? 'Fair' : 'Good',
            timestamp: remote.timestamp,
          );
          await checkInBox.put(entity.id, _dailyLogToMap(entity));
        }
      } catch (_) {}
    }

    if (checkInBox.isEmpty) {
      final logs = _getMockDailyLogs();
      for (var log in logs) {
        await checkInBox.put(log.id, _dailyLogToMap(log));
      }
    }
    final List<DailyLogEntity> list = [];
    for (var key in checkInBox.keys) {
      final raw = checkInBox.get(key);
      if (raw != null) {
        list.add(_mapToDailyLog(Map<String, dynamic>.from(raw)));
      }
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  @override
  Future<void> saveAudioAnalysis(AudioAnalysisEntity analysis) async {
    final map = _audioAnalysisToMap(analysis);
    await recordingsBox.put(analysis.id, map);
  }

  @override
  Future<List<AudioAnalysisEntity>> getAudioAnalyses() async {
    if (recordingsBox.isEmpty) {
      final analyses = _getMockAudioAnalyses();
      for (var analysis in analyses) {
        await saveAudioAnalysis(analysis);
      }
    }
    final List<AudioAnalysisEntity> list = [];
    for (var key in recordingsBox.keys) {
      final raw = recordingsBox.get(key);
      if (raw != null) {
        list.add(_mapToAudioAnalysis(Map<String, dynamic>.from(raw)));
      }
    }
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  // Serializer helpers
  Map<String, dynamic> _dailyLogToMap(DailyLogEntity log) {
    return {
      'id': log.id,
      'coughSeverity': log.coughSeverity,
      'breathlessness': log.breathlessness,
      'chestPain': log.chestPain,
      'fever': log.fever,
      'wheezing': log.wheezing,
      'smoking': log.smoking,
      'exerciseMinutes': log.exerciseMinutes,
      'hydrationLiters': log.hydrationLiters,
      'sleepHours': log.sleepHours,
      'sleepQuality': log.sleepQuality,
      'timestamp': log.timestamp.toIso8601String(),
    };
  }

  DailyLogEntity _mapToDailyLog(Map<String, dynamic> map) {
    return DailyLogEntity(
      id: map['id'] as String? ?? '',
      coughSeverity: (map['coughSeverity'] as num?)?.toDouble() ?? 0.0,
      breathlessness: (map['breathlessness'] as num?)?.toDouble() ?? 0.0,
      chestPain: map['chestPain'] as bool? ?? false,
      fever: map['fever'] as bool? ?? false,
      wheezing: map['wheezing'] as bool? ?? false,
      smoking: map['smoking'] as bool? ?? false,
      exerciseMinutes: (map['exerciseMinutes'] as num?)?.toDouble() ?? 0.0,
      hydrationLiters: (map['hydrationLiters'] as num?)?.toDouble() ?? 0.0,
      sleepHours: (map['sleepHours'] as num?)?.toDouble() ?? 0.0,
      sleepQuality: map['sleepQuality'] as String? ?? 'Good',
      timestamp: DateTime.parse(map['timestamp'] as String),
    );
  }

  Map<String, dynamic> _audioAnalysisToMap(AudioAnalysisEntity analysis) {
    return {
      'id': analysis.id,
      'title': analysis.title,
      'type': analysis.type,
      'duration': analysis.duration,
      'confidence': analysis.confidence,
      'lungsScore': analysis.lungsScore,
      'insight': analysis.insight,
      'intensity': analysis.intensity,
      'breathingRate': analysis.breathingRate,
      'rhythm': analysis.rhythm,
      'signalQuality': analysis.signalQuality,
      'backgroundNoise': analysis.backgroundNoise,
      'timestamp': analysis.timestamp.toIso8601String(),
      'tags': analysis.tags,
    };
  }

  AudioAnalysisEntity _mapToAudioAnalysis(Map<String, dynamic> map) {
    return AudioAnalysisEntity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? '',
      duration: map['duration'] as int? ?? 0,
      confidence: map['confidence'] as int? ?? 0,
      lungsScore: map['lungsScore'] as int? ?? 0,
      insight: map['insight'] as String? ?? '',
      intensity: map['intensity'] as String? ?? '',
      breathingRate: map['breathingRate'] as int? ?? 0,
      rhythm: map['rhythm'] as String? ?? '',
      signalQuality: map['signalQuality'] as String? ?? '',
      backgroundNoise: map['backgroundNoise'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  // Mock data generators
  List<DailyLogEntity> _getMockDailyLogs() {
    return [
      DailyLogEntity(
        id: 'log1',
        coughSeverity: 3,
        breathlessness: 2,
        chestPain: false,
        fever: false,
        wheezing: false,
        smoking: false,
        exerciseMinutes: 45,
        hydrationLiters: 2.4,
        sleepHours: 7.5,
        sleepQuality: 'Good',
        timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      ),
      DailyLogEntity(
        id: 'log2',
        coughSeverity: 4,
        breathlessness: 3,
        chestPain: false,
        fever: false,
        wheezing: true,
        smoking: false,
        exerciseMinutes: 30,
        hydrationLiters: 1.8,
        sleepHours: 6.0,
        sleepQuality: 'Fair',
        timestamp: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];
  }

  List<AudioAnalysisEntity> _getMockAudioAnalyses() {
    final now = DateTime.now();
    return [
      AudioAnalysisEntity(
        id: 'rec1',
        title: 'Excellent Airflow',
        type: 'Cough',
        duration: 42,
        confidence: 98,
        lungsScore: 98,
        insight: 'Your recording shows a crisp, dry cough pattern with a clear respiratory rhythm. No significant wheezing or crackling was detected by the algorithm. This profile is consistent with minor throat irritation rather than deep lung congestion.',
        intensity: 'Moderate',
        breathingRate: 16,
        rhythm: 'Steady',
        signalQuality: 'Excellent',
        backgroundNoise: 'Low (Minimal Interference)',
        timestamp: now.subtract(const Duration(hours: 2)),
        tags: const ['No Congestion', 'High Energy'],
      ),
      AudioAnalysisEntity(
        id: 'rec2',
        title: 'Slight Wheezing',
        type: 'Breathing',
        duration: 30,
        confidence: 85,
        lungsScore: 85,
        insight: 'Slight whistling sounds detected during exhalation phases. This could point to mild airway restriction or environmental allergy responses.',
        intensity: 'Low',
        breathingRate: 18,
        rhythm: 'Irregular',
        signalQuality: 'Good',
        backgroundNoise: 'Medium (Slight static)',
        timestamp: now.subtract(const Duration(days: 1)),
        tags: const ['Mild Cough', 'Humidity Alert'],
      ),
      AudioAnalysisEntity(
        id: 'rec3',
        title: 'Optimal Recovery',
        type: 'Cough',
        duration: 55,
        confidence: 95,
        lungsScore: 95,
        insight: 'Lung acoustics present clear airways with a stable breath recovery timing profile under 1.5 seconds, showing healthy baseline function.',
        intensity: 'Moderate',
        breathingRate: 15,
        rhythm: 'Steady',
        signalQuality: 'Excellent',
        backgroundNoise: 'Low (Minimal Interference)',
        timestamp: now.subtract(const Duration(days: 2)),
        tags: const ['Clear Morning'],
      ),
    ];
  }
}
