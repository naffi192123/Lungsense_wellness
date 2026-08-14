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
        if (data is! Map<String, dynamic> && data is! Map) {
          throw const ServerException('Invalid response format from audio job status');
        }
        final map = Map<String, dynamic>.from(data as Map);

        // Parse segmentation and cough event count
        Map<String, dynamic>? segmentationMap;
        int? coughEvents;
        if (map['segmentation'] is Map) {
          segmentationMap = Map<String, dynamic>.from(map['segmentation'] as Map);
          if (segmentationMap['cough_event_count'] != null) {
            coughEvents = (segmentationMap['cough_event_count'] as num?)?.toInt();
          } else if (segmentationMap['cough_events'] is List) {
            coughEvents = (segmentationMap['cough_events'] as List).length;
          }
        }
        if (coughEvents == null && map['cough_event_count'] != null) {
          coughEvents = (map['cough_event_count'] as num?)?.toInt();
        }

        // Parse MFCC means
        List<double>? mfccList;
        if (map['mfcc_means'] is List) {
          mfccList = (map['mfcc_means'] as List)
              .whereType<num>()
              .map((n) => n.toDouble())
              .toList();
        }

        // Parse spectral summary
        Map<String, dynamic>? spectral;
        if (map['spectral_summary'] is Map) {
          spectral = Map<String, dynamic>.from(map['spectral_summary'] as Map);
        }

        // Parse quality breakdown
        Map<String, dynamic>? qualityBreakdown;
        if (map['quality_breakdown'] is Map) {
          qualityBreakdown = Map<String, dynamic>.from(map['quality_breakdown'] as Map);
        }

        DateTime? created;
        if (map['created_at'] != null) {
          created = DateTime.tryParse(map['created_at'].toString())?.toLocal();
        }

        DateTime? completed;
        if (map['completed_at'] != null) {
          completed = DateTime.tryParse(map['completed_at'].toString())?.toLocal();
        }

        return AudioJobEntity(
          jobId: map['job_id'] as String? ?? map['id'] as String? ?? jobId,
          status: map['status'] as String? ?? 'processing',
          recordingType: map['recording_type'] as String?,
          message: map['message'] as String?,
          error: map['error'] as String?,
          breathingRateBpm: (map['breathing_rate_bpm'] as num?)?.toDouble(),
          breathCycleSeconds: (map['breath_cycle_seconds'] as num?)?.toDouble(),
          dominantFrequencyHz: (map['dominant_frequency_hz'] as num?)?.toDouble(),
          rmsEnergy: (map['rms_energy'] as num?)?.toDouble(),
          zeroCrossingRate: (map['zero_crossing_rate'] as num?)?.toDouble(),
          qualityScore: (map['quality_score'] as num?)?.toDouble(),
          classification: map['classification'] as String?,
          durationSeconds: (map['duration_seconds'] as num?)?.toDouble(),
          spectralSummary: spectral,
          qualityBreakdown: qualityBreakdown,
          segmentation: segmentationMap,
          coughEventCount: coughEvents,
          mfccMeans: mfccList,
          mfccDeltaMean: (map['mfcc_delta_mean'] as num?)?.toDouble(),
          mfccDelta2Mean: (map['mfcc_delta2_mean'] as num?)?.toDouble(),
          createdAt: created,
          completedAt: completed,
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
