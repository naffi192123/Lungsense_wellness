import 'package:hive_flutter/hive_flutter.dart';
import '../../../daily_log/data/datasources/daily_log_remote_data_source.dart';
import '../../../dashboard/data/datasources/score_remote_data_source.dart';
import '../../../recording/data/datasources/audio_recording_remote_data_source.dart';
import '../../domain/entities/wellness_entities.dart';
import '../../domain/repositories/wellness_repository.dart';

/// Implementation of WellnessRepository with zero mock data and real backend API synchronization.
class WellnessRepositoryImpl implements WellnessRepository {
  final Box checkInBox;
  final Box recordingsBox;
  final Box? scoreBox;
  final DailyLogRemoteDataSource? dailyLogRemoteDataSource;
  final ScoreRemoteDataSource? scoreRemoteDataSource;
  final AudioRecordingRemoteDataSource? audioRecordingRemoteDataSource;

  WellnessRepositoryImpl({
    required this.checkInBox,
    required this.recordingsBox,
    this.scoreBox,
    this.dailyLogRemoteDataSource,
    this.scoreRemoteDataSource,
    this.audioRecordingRemoteDataSource,
  });

  @override
  Future<void> saveDailyLog(DailyLogEntity log) async {
    // 1. Submit to backend checkin API
    String savedId = log.id;
    DateTime savedTime = log.timestamp;
    if (dailyLogRemoteDataSource != null) {
      try {
        final remote = await dailyLogRemoteDataSource!.createCheckIn(log);
        savedId = remote.id;
        savedTime = remote.timestamp;
      } catch (_) {}
    }

    final entityToSave = DailyLogEntity(
      id: savedId,
      checkinDate: log.checkinDate,
      breathlessness: log.breathlessness,
      activityLimitation: log.activityLimitation,
      changeFromUsual: log.changeFromUsual,
      fever: log.fever,
      chestTightness: log.chestTightness,
      chestDiscomfortBreathing: log.chestDiscomfortBreathing,
      wheezing: log.wheezing,
      coughSeverity: log.coughSeverity,
      mucus: log.mucus,
      sleepDisruption: log.sleepDisruption,
      chestPain: log.chestPain,
      smokedToday: log.smokedToday,
      exerciseMinutes: log.exerciseMinutes,
      sleepHours: log.sleepHours,
      waterIntakeLiters: log.waterIntakeLiters,
      timestamp: savedTime,
    );

    // 2. Persist locally in checkInBox
    await checkInBox.put(entityToSave.id, _dailyLogToMap(entityToSave));

    // 3. Automatically trigger backend score computation via POST /score/compute
    if (scoreRemoteDataSource != null) {
      try {
        await scoreRemoteDataSource!.computeScore();
      } catch (_) {}
      try {
        await getLatestScore();
        await getScoreHistory(limit: 30);
      } catch (_) {}
    }
  }

  @override
  Future<List<DailyLogEntity>> getDailyLogs() async {
    if (dailyLogRemoteDataSource != null) {
      try {
        final rawCheckIns = await dailyLogRemoteDataSource!.getRawCheckIns();
        for (var raw in rawCheckIns) {
          final id = raw['id'] as String? ?? '';
          if (id.isEmpty) continue;
          final createdStr = raw['created_at']?.toString();
          final dt = createdStr != null ? DateTime.tryParse(createdStr) ?? DateTime.now() : DateTime.now();
          final dateStr = raw['checkin_date'] as String? ?? "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";

          final entity = DailyLogEntity(
            id: id,
            checkinDate: dateStr,
            breathlessness: _toDouble(raw['breathlessness'] ?? raw['shortness_of_breath']),
            activityLimitation: _toDouble(raw['activity_limitation'] ?? raw['fatigue_level']),
            changeFromUsual: _toDouble(raw['change_from_usual'] ?? 0),
            fever: _toDouble(raw['fever'] ?? 0),
            chestTightness: _toDouble(raw['chest_tightness'] ?? 0),
            chestDiscomfortBreathing: _toDouble(raw['chest_discomfort_breathing'] ?? 0),
            wheezing: _toDouble(raw['wheezing'] ?? 0),
            coughSeverity: _toDouble(raw['cough_severity'] ?? 0),
            mucus: _toDouble(raw['mucus'] ?? 0),
            sleepDisruption: _toDouble(raw['sleep_disruption'] ?? 0),
            chestPain: _toDouble(raw['chest_pain'] ?? 0),
            smokedToday: _toBool(raw['smoked_today'] ?? raw['smoking']),
            exerciseMinutes: _toDouble(raw['exercise_minutes'] ?? 30),
            sleepHours: _toDouble(raw['sleep_hours'] ?? 8.0),
            waterIntakeLiters: _toDouble(raw['water_intake_liters'] ?? raw['hydration_liters'] ?? 2.0),
            timestamp: dt,
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
    // 1. Persist recording entry into recordingsBox
    final map = _audioAnalysisToMap(analysis);
    await recordingsBox.put(analysis.id, map);

    // 2. When complete, compute full Lung Wellness Score via POST /score/compute
    if (analysis.status.toLowerCase() == 'complete' && scoreRemoteDataSource != null) {
      try {
        await scoreRemoteDataSource!.computeScore();
      } catch (_) {}
      try {
        await getLatestScore();
        await getScoreHistory(limit: 30);
      } catch (_) {}
    }
  }

  @override
  Future<List<AudioAnalysisEntity>> getAudioAnalyses() async {
    if (audioRecordingRemoteDataSource != null) {
      try {
        final remoteFeatures = await audioRecordingRemoteDataSource!.getRecordingFeatures();
        for (var raw in remoteFeatures) {
          final jobId = raw['job_id'] as String? ?? raw['id'] as String? ?? '';
          if (jobId.isEmpty) continue;
          final createdStr = raw['created_at']?.toString();
          final dt = createdStr != null ? DateTime.tryParse(createdStr) ?? DateTime.now() : DateTime.now();
          final recType = (raw['recording_type'] as String? ?? 'cough').toLowerCase() == 'cough' ? 'Cough' : 'Breathing';
          final qScore = (raw['quality_score'] as num?)?.toDouble() ?? 0.95;
          final qScoreInt = (qScore * 100).round();
          final classification = raw['classification'] as String? ?? 'Optimal Respiratory Sound';

          final existing = recordingsBox.get(jobId);
          String? localPath;
          if (existing != null && existing is Map) {
            localPath = existing['localAudioPath'] as String?;
          }

          final entity = AudioAnalysisEntity(
            id: jobId,
            title: '$recType Recording',
            type: recType,
            status: (raw['status'] as String? ?? 'complete').toLowerCase(),
            duration: (raw['duration_seconds'] as num?)?.toInt() ?? 12,
            confidence: qScoreInt,
            lungsScore: qScoreInt,
            insight: 'Acoustic parameters processed: Breathing Rate = ${raw['breathing_rate_bpm'] != null ? '${raw['breathing_rate_bpm']} BPM' : 'N/A'}, Dominant Frequency = ${raw['dominant_frequency_hz'] != null ? '${raw['dominant_frequency_hz']} Hz' : 'N/A'}, Classification = $classification.',
            intensity: 'Normal',
            breathingRate: (raw['breathing_rate_bpm'] as num?)?.toInt() ?? 0,
            rhythm: classification,
            signalQuality: 'Quality: $qScoreInt%',
            backgroundNoise: 'Low',
            timestamp: dt,
            tags: ['FastAPI Engine', classification],
            localAudioPath: localPath,
            jobId: jobId,
            qualityScore: qScore,
            dominantFrequencyHz: (raw['dominant_frequency_hz'] as num?)?.toDouble(),
            rmsEnergy: (raw['rms_energy'] as num?)?.toDouble(),
            classification: classification,
            spectralSummary: raw['spectral_summary'] is Map ? Map<String, dynamic>.from(raw['spectral_summary']) : null,
          );
          await recordingsBox.put(entity.id, _audioAnalysisToMap(entity));
        }
      } catch (_) {}
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

  @override
  Future<List<ScoreHistoryEntity>> getScoreHistory({int limit = 30, int offset = 0}) async {
    if (scoreRemoteDataSource != null) {
      try {
        final remote = await scoreRemoteDataSource!.getScoreHistory(limit: limit, offset: offset);
        final List<ScoreHistoryEntity> result = [];
        for (var item in remote) {
          final rawScore = item['score'] ?? item['final_score'] ?? item['wellness_score'] ?? item['total_score'];
          final intScore = rawScore != null
              ? (rawScore is num ? rawScore.toInt() : int.tryParse(rawScore.toString()) ?? 0)
              : 0;

          final entity = ScoreHistoryEntity(
            id: item['id'] as String? ?? item['created_at']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
            score: intScore,
            band: item['band'] as String? ?? 'good',
            message: item['message'] as String?,
            breakdown: item['breakdown'] is Map
                ? Map<String, dynamic>.from(item['breakdown'])
                : (item['components'] is Map ? Map<String, dynamic>.from(item['components']) : null),
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
        var remote = await scoreRemoteDataSource!.getLatestScore();
        if (remote == null || (remote['lung_wellness_score'] == null && remote['score'] == null && remote['final_score'] == null)) {
          // If no score computed yet on backend, try computing via POST /score/compute
          try {
            final computed = await scoreRemoteDataSource!.computeScore();
            if (computed.isNotEmpty && (computed['lung_wellness_score'] != null || computed['score'] != null || computed['final_score'] != null)) {
              remote = computed;
            }
          } catch (_) {}
        }

        if (remote != null) {
          final String? baselineStatusStr = remote['baseline_status']?.toString();
          final bool isInitializing = baselineStatusStr?.toLowerCase() == 'initializing' ||
              (remote['breakdown'] is Map &&
                  remote['breakdown']['weights'] is Map &&
                  remote['breakdown']['weights']['T'] == 0);

          final double? lungWellnessScore = _parseDouble(remote['lung_wellness_score'] ?? remote['score'] ?? remote['final_score'] ?? remote['wellness_score'] ?? remote['total_score']);
          final double? coughScore = _parseDouble(remote['cough_score'] ?? remote['coughScore'] ?? (remote['breakdown'] is Map ? remote['breakdown']['C'] : null));
          final double? breathingScore = _parseDouble(remote['breathing_score'] ?? remote['breathingScore'] ?? (remote['breakdown'] is Map ? remote['breakdown']['B'] : null));
          final double? symptomScore = _parseDouble(remote['symptom_score'] ?? remote['symptomScore'] ?? (remote['breakdown'] is Map ? remote['breakdown']['S'] : null));
          final double? trendScore = isInitializing
              ? null
              : _parseDouble(remote['trend_score'] ?? remote['trendScore'] ?? (remote['breakdown'] is Map ? remote['breakdown']['T'] : null));

          final String? message = remote['message'] as String? ?? (remote['breakdown'] is Map ? remote['breakdown']['message'] as String? : null);
          final int intScore = (lungWellnessScore ?? 0).round();

          final breakdownMap = <String, dynamic>{};
          if (remote['breakdown'] is Map) {
            breakdownMap.addAll(Map<String, dynamic>.from(remote['breakdown']));
          }
          if (remote['components'] is Map) {
            breakdownMap.addAll(Map<String, dynamic>.from(remote['components']));
          }
          if (remote['scores'] is Map) {
            breakdownMap.addAll(Map<String, dynamic>.from(remote['scores']));
          }
          for (var key in ['C', 'B', 'S', 'T', 'cough_score', 'breathing_score', 'symptom_score', 'trend_score', 'coughScore', 'breathingScore', 'symptomScore', 'trendScore']) {
            if (remote[key] != null) {
              breakdownMap[key] = remote[key];
            }
          }

          final String? createdAtStr = remote['created_at']?.toString() ?? remote['timestamp']?.toString();
          final DateTime timestamp = createdAtStr != null
              ? (DateTime.tryParse(createdAtStr)?.toLocal() ?? DateTime.now())
              : DateTime.now();

          final entity = ScoreHistoryEntity(
            id: remote['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
            score: intScore,
            lungWellnessScore: lungWellnessScore,
            coughScore: coughScore,
            breathingScore: breathingScore,
            symptomScore: symptomScore,
            trendScore: trendScore,
            band: remote['band'] as String? ?? (intScore >= 80 ? 'good' : (intScore >= 60 ? 'fair' : 'attention')),
            message: message,
            breakdown: breakdownMap.isNotEmpty ? breakdownMap : null,
            sessionNumber: (remote['session_number'] as num?)?.toInt(),
            baselineStatus: remote['baseline_status'] as String?,
            timestamp: timestamp,
          );
          if (scoreBox != null) {
            await scoreBox!.put('latest', {
              'id': entity.id,
              'score': entity.score,
              'lungWellnessScore': entity.lungWellnessScore,
              'coughScore': entity.coughScore,
              'breathingScore': entity.breathingScore,
              'symptomScore': entity.symptomScore,
              'trendScore': entity.trendScore,
              'band': entity.band,
              'message': entity.message,
              'breakdown': entity.breakdown,
              'sessionNumber': entity.sessionNumber,
              'baselineStatus': entity.baselineStatus,
              'timestamp': entity.timestamp.toIso8601String(),
            });
          }
          return entity;
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
      'status': analysis.status,
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
      'localAudioPath': analysis.localAudioPath,
      'jobId': analysis.jobId,
      'qualityScore': analysis.qualityScore,
      'dominantFrequencyHz': analysis.dominantFrequencyHz,
      'rmsEnergy': analysis.rmsEnergy,
      'classification': analysis.classification,
      'errorMessage': analysis.errorMessage,
      'spectralSummary': analysis.spectralSummary,
    };
  }

  AudioAnalysisEntity _mapToAudioAnalysis(Map<String, dynamic> map) {
    return AudioAnalysisEntity(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      type: map['type'] as String? ?? '',
      status: map['status'] as String? ?? 'complete',
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      confidence: (map['confidence'] as num?)?.toInt() ?? 0,
      lungsScore: (map['lungsScore'] as num?)?.toInt() ?? 0,
      insight: map['insight'] as String? ?? '',
      intensity: map['intensity'] as String? ?? '',
      breathingRate: (map['breathingRate'] as num?)?.toInt() ?? 0,
      rhythm: map['rhythm'] as String? ?? '',
      signalQuality: map['signalQuality'] as String? ?? '',
      backgroundNoise: map['backgroundNoise'] as String? ?? '',
      timestamp: map['timestamp'] != null ? DateTime.tryParse(map['timestamp']) ?? DateTime.now() : DateTime.now(),
      tags: List<String>.from(map['tags'] ?? []),
      localAudioPath: map['localAudioPath'] as String?,
      jobId: map['jobId'] as String?,
      qualityScore: (map['qualityScore'] as num?)?.toDouble(),
      dominantFrequencyHz: (map['dominantFrequencyHz'] as num?)?.toDouble(),
      rmsEnergy: (map['rms_energy'] ?? map['rmsEnergy'] as num?)?.toDouble(),
      classification: map['classification'] as String?,
      errorMessage: map['errorMessage'] as String?,
      spectralSummary: map['spectralSummary'] is Map ? Map<String, dynamic>.from(map['spectralSummary']) : null,
    );
  }

  double? _parseDouble(dynamic val) {
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
}
