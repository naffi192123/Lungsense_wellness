import 'dart:convert';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/diagnosis_entity.dart';

abstract class DiagnosisRemoteDataSource {
  /// Fetches the controlled list of diagnosis options from GET /diagnosis/options.
  Future<List<String>> getDiagnosisOptions();

  /// Retrieves the user's latest self-reported diagnosis from GET /diagnosis/latest.
  Future<DiagnosisEntity?> getLatestDiagnosis();

  /// Submits a newly reported diagnosis to POST /diagnosis.
  Future<DiagnosisEntity> createDiagnosis({
    required String diagnosis,
    String? notes,
  });
}

class DiagnosisRemoteDataSourceImpl implements DiagnosisRemoteDataSource {
  final ApiClient apiClient;

  DiagnosisRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<String>> getDiagnosisOptions() async {
    try {
      final response = await apiClient.get('/diagnosis/options');

      if (response.statusCode == 200) {
        if (response.body.trim().isEmpty || response.body.trim().startsWith('<')) {
          throw ServerException(
            'Server returned invalid response for diagnosis options (${response.statusCode})',
            code: response.statusCode.toString(),
          );
        }

        final dynamic data = jsonDecode(response.body);
        if (data is List) {
          return data.map((item) => item.toString()).toList();
        } else {
          throw const ServerException('Unexpected response format for diagnosis options.');
        }
      } else {
        throw ServerException(
          'Failed to load diagnosis options (${response.statusCode})',
          code: response.statusCode.toString(),
        );
      }
    } catch (e) {
      if (e is ServerException || e is ConnectionException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<DiagnosisEntity?> getLatestDiagnosis() async {
    try {
      final response = await apiClient.get('/diagnosis/latest');

      if (response.statusCode == 200) {
        final bodyTrimmed = response.body.trim();
        if (bodyTrimmed.isEmpty || bodyTrimmed == 'null' || bodyTrimmed.startsWith('<')) {
          return null;
        }

        final dynamic data = jsonDecode(response.body);
        if (data == null) return null;
        if (data is Map<String, dynamic>) {
          return DiagnosisEntity.fromJson(data);
        } else if (data is Map) {
          return DiagnosisEntity.fromJson(Map<String, dynamic>.from(data));
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        // For pre-filling, failure should be non-fatal (return null)
        return null;
      }
    } catch (_) {
      // If unable to fetch latest diagnosis, fallback gracefully to null
      return null;
    }
  }

  @override
  Future<DiagnosisEntity> createDiagnosis({
    required String diagnosis,
    String? notes,
  }) async {
    try {
      final body = <String, dynamic>{
        'diagnosis': diagnosis,
      };
      if (notes != null && notes.trim().isNotEmpty) {
        body['notes'] = notes.trim();
      }

      final response = await apiClient.post('/diagnosis', body: body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.body.trim().isEmpty || response.body.trim().startsWith('<')) {
          throw ServerException(
            'Server returned invalid response after saving diagnosis (${response.statusCode})',
            code: response.statusCode.toString(),
          );
        }

        final dynamic data = jsonDecode(response.body);
        if (data is Map) {
          return DiagnosisEntity.fromJson(Map<String, dynamic>.from(data));
        } else {
          throw const ServerException('Unexpected response format after saving diagnosis.');
        }
      } else {
        String message = 'Failed to submit diagnosis (${response.statusCode})';
        try {
          if (!response.body.trim().startsWith('<') && response.body.isNotEmpty) {
            final dynamic errData = jsonDecode(response.body);
            if (errData is Map && errData['detail'] != null) {
              final detail = errData['detail'];
              message = detail is String ? detail : detail.toString();
            }
          }
        } catch (_) {}
        throw ServerException(message, code: response.statusCode.toString());
      }
    } catch (e) {
      if (e is ServerException || e is ConnectionException) rethrow;
      throw ServerException(e.toString());
    }
  }
}
