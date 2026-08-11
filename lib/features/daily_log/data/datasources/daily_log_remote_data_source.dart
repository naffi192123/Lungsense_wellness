import 'dart:convert';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../../domain/entities/daily_checkin_entity.dart';

abstract class DailyLogRemoteDataSource {
  Future<DailyCheckInEntity> createCheckIn(DailyLogEntity log);

  Future<List<DailyCheckInEntity>> getCheckIns();

  Future<Map<String, dynamic>> getSymptomScore();
}

class DailyLogRemoteDataSourceImpl implements DailyLogRemoteDataSource {
  final ApiClient apiClient;

  DailyLogRemoteDataSourceImpl(this.apiClient);

  @override
  Future<DailyCheckInEntity> createCheckIn(DailyLogEntity log) async {
    try {
      final body = {
        'checkin_date': log.checkinDate,
        'breathlessness': log.breathlessness.round().clamp(0, 3),
        'activity_limitation': log.activityLimitation.round().clamp(0, 3),
        'change_from_usual': log.changeFromUsual.round().clamp(0, 3),
        'fever': log.fever.round().clamp(0, 3),
        'chest_tightness': log.chestTightness.round().clamp(0, 3),
        'chest_discomfort_breathing': log.chestDiscomfortBreathing.round().clamp(0, 3),
        'wheezing': log.wheezing.round().clamp(0, 3),
        'cough_severity': log.coughSeverity.round().clamp(0, 3),
        'mucus': log.mucus.round().clamp(0, 3),
        'sleep_disruption': log.sleepDisruption.round().clamp(0, 3),
      };

      final response = await apiClient.post('/checkins', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return DailyCheckInEntity(
          id: data['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
          coughSeverity: (data['cough_severity'] as num?)?.toInt() ?? log.coughSeverity.round(),
          shortnessOfBreath: (data['breathlessness'] as num?)?.toInt() ?? log.breathlessness.round(),
          fatigueLevel: (data['activity_limitation'] as num?)?.toInt() ?? log.activityLimitation.round(),
          notes: null,
          timestamp: data['created_at'] != null ? DateTime.tryParse(data['created_at']) ?? DateTime.now() : DateTime.now(),
        );
      } else {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        final message = detail is String ? detail : detail.toString();
        throw ServerException(message, code: response.statusCode.toString());
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  int _toInt(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val.toInt();
    if (val is bool) return val ? 1 : 0;
    if (val is String) return int.tryParse(val) ?? 0;
    return 0;
  }

  @override
  Future<List<DailyCheckInEntity>> getCheckIns() async {
    try {
      final response = await apiClient.get('/checkins');
      if (response.statusCode == 200) {
        final List list = jsonDecode(response.body);
        return list.map((item) {
          return DailyCheckInEntity(
            id: item['id'] as String? ?? '',
            coughSeverity: _toInt(item['cough_severity']),
            shortnessOfBreath: _toInt(item['breathlessness'] ?? item['shortness_of_breath']),
            fatigueLevel: _toInt(item['activity_limitation'] ?? item['fatigue_level']),
            notes: item['symptoms_description'] as String?,
            timestamp: item['created_at'] != null ? DateTime.tryParse(item['created_at']) ?? DateTime.now() : DateTime.now(),
          );
        }).toList();
      } else {
        return [];
      }
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getSymptomScore() async {
    try {
      final response = await apiClient.get('/score/symptom');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {};
      }
    } catch (_) {
      return {};
    }
  }
}
