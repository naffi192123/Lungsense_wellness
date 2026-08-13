import 'dart:convert';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';

abstract class ScoreRemoteDataSource {
  /// Invokes backend score computation algorithm based on recent acoustic & check-in inputs.
  Future<Map<String, dynamic>> computeScore();

  /// Finalizes the daily screening session and logs a completed record.
  Future<void> completeSession();

  /// Fetches the most recent Lung Wellness Score object for the active user.
  Future<Map<String, dynamic>?> getLatestScore();

  /// Fetches historical Lung Wellness Score entries.
  Future<List<Map<String, dynamic>>> getScoreHistory({int limit = 30, int offset = 0});

  /// Fetches personal baseline status and progress.
  Future<Map<String, dynamic>> getBaselineStatus();

  /// Fetches symptom-specific score.
  Future<Map<String, dynamic>> getSymptomScore({String? date});

  /// Fetches the visual classification bands legend.
  Future<Map<String, dynamic>> getScoreBands();
}

class ScoreRemoteDataSourceImpl implements ScoreRemoteDataSource {
  final ApiClient apiClient;

  ScoreRemoteDataSourceImpl(this.apiClient);

  @override
  Future<Map<String, dynamic>> computeScore() async {
    try {
      final response = await apiClient.post('/score/compute');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        if (decoded is String && decoded.isNotEmpty && decoded != 'null') {
          try {
            final inner = jsonDecode(decoded);
            if (inner is Map) return Map<String, dynamic>.from(inner);
          } catch (_) {
            return {};
          }
        }
        return {};
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
        if (decoded == null || decoded == 'null') return null;
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
        if (decoded is String && decoded.isNotEmpty && decoded != 'null') {
          try {
            final inner = jsonDecode(decoded);
            if (inner is Map) return Map<String, dynamic>.from(inner);
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
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
      return {'status': 'initializing', 'message': 'Complete sessions to activate trend scoring.'};
    } catch (_) {
      return {'status': 'initializing', 'message': 'Complete sessions to activate trend scoring.'};
    }
  }

  @override
  Future<Map<String, dynamic>> getSymptomScore({String? date}) async {
    try {
      final query = date != null ? '?date=$date' : '';
      final response = await apiClient.get('/score/symptom$query');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
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
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      }
      return {};
    } catch (_) {
      return {};
    }
  }
}
