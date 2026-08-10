import 'dart:convert';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';

/// Contract for backend Lung Wellness Score endpoints.
abstract class ScoreRemoteDataSource {
  /// Compute today's full score from latest check-in and acoustic features.
  Future<Map<String, dynamic>> computeScore();

  /// Finalize screening session and advance baseline counter once.
  Future<void> completeSession();

  /// Get single most recent wellness score for the dashboard dial.
  Future<Map<String, dynamic>?> getLatestScore();

  /// Get paginated wellness score history for trends and charts.
  Future<List<Map<String, dynamic>>> getScoreHistory({int limit = 30, int offset = 0});

  /// Get baseline status and progress message.
  Future<Map<String, dynamic>> getBaselineStatus();

  /// Get symptom score for a specific date (or today).
  Future<Map<String, dynamic>> getSymptomScore({String? date});

  /// Get score band legend.
  Future<Map<String, dynamic>> getScoreBands();
}

/// Implementation of ScoreRemoteDataSource calling FastAPI endpoints.
class ScoreRemoteDataSourceImpl implements ScoreRemoteDataSource {
  final ApiClient apiClient;

  ScoreRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> computeScore() async {
    try {
      final response = await apiClient.post('/score/compute');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        throw ServerException(detail is String ? detail : detail.toString(), code: response.statusCode.toString());
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<void> completeSession() async {
    try {
      final response = await apiClient.post('/score/session-complete');
      if (response.statusCode != 200) {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        throw ServerException(detail is String ? detail : detail.toString(), code: response.statusCode.toString());
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<Map<String, dynamic>?> getLatestScore() async {
    try {
      final response = await apiClient.get('/score/latest');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded == null) return null;
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is String && decoded.isNotEmpty) {
          try {
            return jsonDecode(decoded) as Map<String, dynamic>;
          } catch (_) {
            return null;
          }
        }
        return null;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getScoreHistory({int limit = 30, int offset = 0}) async {
    try {
      final response = await apiClient.get('/score/history?limit=$limit&offset=$offset');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
        return [];
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>> getBaselineStatus() async {
    try {
      final response = await apiClient.get('/score/baseline');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      return {'status': 'initializing', 'message': 'Complete sessions to activate trend scoring.'};
    } catch (_) {
      return {'status': 'initializing', 'message': 'Complete sessions to activate trend scoring.'};
    }
  }

  @override
  Future<Map<String, dynamic>> getSymptomScore({String? date}) async {
    try {
      final query = date != null ? '?on=$date' : '';
      final response = await apiClient.get('/score/symptom$query');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      return {'symptom_score': 0, 'band': 'neutral'};
    } catch (_) {
      return {'symptom_score': 0, 'band': 'neutral'};
    }
  }

  @override
  Future<Map<String, dynamic>> getScoreBands() async {
    try {
      final response = await apiClient.get('/score/bands');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}
