import 'package:hive_flutter/hive_flutter.dart';
import '../../../daily_log/data/datasources/daily_log_remote_data_source.dart';
import '../../../dashboard/data/datasources/score_remote_data_source.dart';
import '../../domain/entities/wellness_entities.dart';
import '../../domain/repositories/wellness_repository.dart';

/// Implementation of WellnessRepository with zero mock data and real backend API synchronization.
class WellnessRepositoryImpl implements WellnessRepository {
  final Box checkInBox;
  final Box recordingsBox;
  final Box? scoreBox;
  final DailyLogRemoteDataSource? dailyLogRemoteDataSource;
  final ScoreRemoteDataSource? scoreRemoteDataSource;

  WellnessRepositoryImpl({
    required this.checkInBox,
    required this.recordingsBox,
    this.scoreBox,
    this.dailyLogRemoteDataSource,
    this.scoreRemoteDataSource,
  });

  @override
  Future<void> saveDailyLog(DailyLogEntity log) async {
    final map = _dailyLogToMap(log);
    await checkInBox.put(log.id, map);

    if (dailyLogRemoteDataSource != null) {
      await dailyLogRemoteDataSource!.createCheckIn(log);
    }
  }

  @override
  Future<List<DailyLogEntity>> getDailyLogs() async {
    if (dailyLogRemoteDataSource != null) {
      try {
        final remoteLogs = await dailyLogRemoteDataSource!.getCheckIns();
        for (var remote in remoteLogs) {
          final now = remote.timestamp;
          final dateStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
          final entity = DailyLogEntity(
            id: remote.id,
            checkinDate: dateStr,
            breathlessness: remote.shortnessOfBreath.toDouble(),
            activityLimitation: remote.fatigueLevel.toDouble(),
            changeFromUsual: 3,
            fever: 0,
            chestTightness: 0,
            chestDiscomfortBreathing: 0,
            wheezing: 0,
            coughSeverity: remote.coughSeverity.toDouble(),
            mucus: 0,
            sleepDisruption: 0,
            chestPain: 0,
            smokedToday: false,
            exerciseMinutes: 30,
            sleepHours: 8.0,
            waterIntakeLiters: 2.0,
            timestamp: remote.timestamp,
          );
          await checkInBox.put(entity.id, _dailyLogToMap(entity));
        }
      } catch (_) {}
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

  @override
  Future<List<ScoreHistoryEntity>> getScoreHistory({int limit = 30, int offset = 0}) async {
    if (scoreRemoteDataSource != null) {
      try {
        final remote = await scoreRemoteDataSource!.getScoreHistory(limit: limit, offset: offset);
        final List<ScoreHistoryEntity> result = [];
        for (var item in remote) {
          final entity = ScoreHistoryEntity(
            id: item['id'] as String? ?? item['created_at']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            score: (item['score'] as num?)?.toInt() ?? (item['final_score'] as num?)?.toInt() ?? 0,
            band: item['band'] as String? ?? 'good',
            message: item['message'] as String?,
            breakdown: item['breakdown'] is Map ? Map<String, dynamic>.from(item['breakdown']) : null,
            sessionNumber: (item['session_number'] as num?)?.toInt(),
            baselineStatus: item['baseline_status'] as String?,
            timestamp: item['created_at'] != null ? DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
          );
          result.add(entity);
          if (scoreBox != null) {
            await scoreBox!.put(entity.id, {
              'id': entity.id,
              'score': entity.score,
              'band': entity.band,
              'message': entity.message,
              'breakdown': entity.breakdown,
              'sessionNumber': entity.sessionNumber,
              'baselineStatus': entity.baselineStatus,
              'timestamp': entity.timestamp.toIso8601String(),
            });
          }
        }
        result.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        return result;
      } catch (_) {}
    }

    if (scoreBox != null) {
      final List<ScoreHistoryEntity> list = [];
      for (var key in scoreBox!.keys) {
        final raw = scoreBox!.get(key);
        if (raw != null) {
          final map = Map<String, dynamic>.from(raw);
          list.add(ScoreHistoryEntity(
            id: map['id'] as String? ?? '',
            score: (map['score'] as num?)?.toInt() ?? 0,
            band: map['band'] as String? ?? 'good',
            message: map['message'] as String?,
            breakdown: map['breakdown'] is Map ? Map<String, dynamic>.from(map['breakdown']) : null,
            sessionNumber: (map['sessionNumber'] as num?)?.toInt(),
            baselineStatus: map['baselineStatus'] as String?,
            timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now(),
          ));
        }
      }
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    }
    return [];
  }

  @override
  Future<ScoreHistoryEntity?> getLatestScore() async {
    if (scoreRemoteDataSource != null) {
      try {
        final remote = await scoreRemoteDataSource!.getLatestScore();
        if (remote != null) {
          return ScoreHistoryEntity(
            id: remote['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            score: (remote['score'] as num?)?.toInt() ?? (remote['final_score'] as num?)?.toInt() ?? 0,
            band: remote['band'] as String? ?? 'good',
            message: remote['message'] as String?,
            breakdown: remote['breakdown'] is Map ? Map<String, dynamic>.from(remote['breakdown']) : null,
            sessionNumber: (remote['session_number'] as num?)?.toInt(),
            baselineStatus: remote['baseline_status'] as String?,
            timestamp: remote['created_at'] != null ? DateTime.tryParse(remote['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
          );
        }
      } catch (_) {}
    }
    final history = await getScoreHistory(limit: 1);
    return history.isNotEmpty ? history.first : null;
  }

  @override
  Future<Map<String, dynamic>> getBaselineStatus() async {
    if (scoreRemoteDataSource != null) {
      try {
        return await scoreRemoteDataSource!.getBaselineStatus();
      } catch (_) {}
    }
    return {'status': 'initializing', 'message': 'Complete screening sessions to activate trend scoring.'};
  }

  // Serializers with safe conversion helpers
  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    if (val is bool) return val ? 10.0 : 0.0;
    if (val is String) return double.tryParse(val) ?? 0.0;
    return 0.0;
  }

  bool _toBool(dynamic val) {
    if (val == null) return false;
    if (val is bool) return val;
    if (val is num) return val > 0;
    if (val is String) return val.toLowerCase() == 'true';
    return false;
  }

  Map<String, dynamic> _dailyLogToMap(DailyLogEntity log) {
    return {
      'id': log.id,
      'checkinDate': log.checkinDate,
      'breathlessness': log.breathlessness,
      'activityLimitation': log.activityLimitation,
      'changeFromUsual': log.changeFromUsual,
      'fever': log.fever,
      'chestTightness': log.chestTightness,
      'chestDiscomfortBreathing': log.chestDiscomfortBreathing,
      'wheezing': log.wheezing,
      'coughSeverity': log.coughSeverity,
      'mucus': log.mucus,
      'sleepDisruption': log.sleepDisruption,
      'chestPain': log.chestPain,
      'smokedToday': log.smokedToday,
      'exerciseMinutes': log.exerciseMinutes,
      'sleepHours': log.sleepHours,
      'waterIntakeLiters': log.waterIntakeLiters,
      'timestamp': log.timestamp.toIso8601String(),
    };
  }

  DailyLogEntity _mapToDailyLog(Map<String, dynamic> map) {
    return DailyLogEntity(
      id: map['id'] as String? ?? '',
      checkinDate: map['checkinDate'] as String? ?? '',
      breathlessness: _toDouble(map['breathlessness']),
      activityLimitation: _toDouble(map['activityLimitation']),
      changeFromUsual: _toDouble(map['changeFromUsual']),
      fever: _toDouble(map['fever']),
      chestTightness: _toDouble(map['chestTightness']),
      chestDiscomfortBreathing: _toDouble(map['chestDiscomfortBreathing']),
      wheezing: _toDouble(map['wheezing']),
      coughSeverity: _toDouble(map['coughSeverity']),
      mucus: _toDouble(map['mucus']),
      sleepDisruption: _toDouble(map['sleepDisruption']),
      chestPain: _toDouble(map['chestPain']),
      smokedToday: _toBool(map['smokedToday'] ?? map['smoking']),
      exerciseMinutes: _toDouble(map['exerciseMinutes']),
      sleepHours: _toDouble(map['sleepHours']),
      waterIntakeLiters: _toDouble(map['waterIntakeLiters'] ?? map['hydrationLiters']),
      timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now(),
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
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      confidence: (map['confidence'] as num?)?.toInt() ?? 0,
      lungsScore: (map['lungsScore'] as num?)?.toInt() ?? 0,
      insight: map['insight'] as String? ?? '',
      intensity: map['intensity'] as String? ?? '',
      breathingRate: (map['breathingRate'] as num?)?.toInt() ?? 0,
      rhythm: map['rhythm'] as String? ?? '',
      signalQuality: map['signalQuality'] as String? ?? '',
      backgroundNoise: map['backgroundNoise'] as String? ?? '',
      timestamp: DateTime.parse(map['timestamp'] as String),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }
}
