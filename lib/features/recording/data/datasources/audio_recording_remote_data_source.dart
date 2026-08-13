import 'dart:convert';
import 'dart:io';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/entities/audio_recording_entities.dart';

abstract class AudioRecordingRemoteDataSource {
  Future<ConsentEntity> getConsent(String consentType);
  Future<ConsentEntity> recordConsent({required String consentType, required bool granted});
  Future<AudioJobEntity> uploadAudio({required String path, required String recordingType});
  Future<AudioJobEntity> getJobStatus(String jobId);
  Future<List<Map<String, dynamic>>> getRecordingFeatures();
}

class AudioRecordingRemoteDataSourceImpl implements AudioRecordingRemoteDataSource {
  final ApiClient apiClient;

  AudioRecordingRemoteDataSourceImpl(this.apiClient);

  @override
  Future<ConsentEntity> getConsent(String consentType) async {
    try {
      final response = await apiClient.get('/consent/$consentType');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return ConsentEntity(
          consentType: data['consent_type'] as String? ?? consentType,
          version: data['version'] as String? ?? '1.0',
          granted: data['granted'] as bool? ?? false,
          grantedAt: data['granted_at'] != null ? DateTime.tryParse(data['granted_at']) : null,
        );
      } else {
        throw ServerException('Consent status unavailable', code: response.statusCode.toString());
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<ConsentEntity> recordConsent({required String consentType, required bool granted}) async {
    try {
      final response = await apiClient.post('/consent', body: {
        'consent_type': consentType,
        'version': '1.0',
        'granted': granted,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return ConsentEntity(
          consentType: data['consent_type'] as String? ?? consentType,
          version: data['version'] as String? ?? '1.0',
          granted: data['granted'] as bool? ?? true,
          grantedAt: data['granted_at'] != null ? DateTime.tryParse(data['granted_at']) : DateTime.now(),
        );
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
  Future<AudioJobEntity> uploadAudio({required String path, required String recordingType}) async {
    try {
      final file = File(path);
      if (!await file.exists()) {
        throw const ServerException('Audio file not found on device path.');
      }

      final fileBytes = await file.readAsBytes();
      final filename = file.path.split(Platform.pathSeparator).last;
      
      final endpoint = recordingType.toLowerCase() == 'cough' 
          ? '/recordings/cough' 
          : '/recordings/breathing';

      final response = await apiClient.multipartPost(
        endpoint,
        fileBytes: fileBytes,
        filename: filename,
      );

      if (response.statusCode == 202) {
        final data = jsonDecode(response.body);
        return AudioJobEntity(
          jobId: data['job_id'] as String,
          status: data['status'] as String? ?? 'processing',
          message: data['message'] as String?,
        );
      } else {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        throw ServerException(detail is String ? detail : 'Upload failed (${response.statusCode})', code: response.statusCode.toString());
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<AudioJobEntity> getJobStatus(String jobId) async {
    try {
      final response = await apiClient.get('/recordings/jobs/$jobId');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AudioJobEntity(
          jobId: data['job_id'] as String? ?? jobId,
          status: data['status'] as String? ?? 'processing',
          error: data['error'] as String?,
          breathingRateBpm: (data['breathing_rate_bpm'] as num?)?.toDouble(),
          dominantFrequencyHz: (data['dominant_frequency_hz'] as num?)?.toDouble(),
          rmsEnergy: (data['rms_energy'] as num?)?.toDouble(),
          qualityScore: (data['quality_score'] as num?)?.toDouble(),
          classification: data['classification'] as String?,
          durationSeconds: (data['duration_seconds'] as num?)?.toDouble(),
          spectralSummary: data['spectral_summary'] as Map<String, dynamic>?,
        );
      } else {
        final data = jsonDecode(response.body);
        final detail = data['detail'];
        throw ServerException(detail is String ? detail : 'Failed to query job status', code: response.statusCode.toString());
      }
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(e.toString());
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getRecordingFeatures() async {
    try {
      final response = await apiClient.get('/recordings/features');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
