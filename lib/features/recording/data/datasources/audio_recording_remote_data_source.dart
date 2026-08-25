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
        if (response.body.trim().startsWith('<') || response.body.isEmpty) {
          throw ServerException('Server returned non-JSON response for consent (${response.statusCode})', code: response.statusCode.toString());
        }
        final data = jsonDecode(response.body);
        if (data is! Map) {
          throw const ServerException('Invalid consent data format from server');
        }
        return ConsentEntity(
          consentType: data['consent_type'] as String? ?? consentType,
          version: data['version'] as String? ?? '1.0',
          granted: data['granted'] as bool? ?? false,
          grantedAt: data['granted_at'] != null ? DateTime.tryParse(data['granted_at']) : null,
        );
      } else {
        throw ServerException('Consent status unavailable (${response.statusCode})', code: response.statusCode.toString());
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
        if (response.body.trim().startsWith('<') || response.body.isEmpty) {
          return ConsentEntity(
            consentType: consentType,
            version: '1.0',
            granted: granted,
            grantedAt: DateTime.now(),
          );
        }
        final data = jsonDecode(response.body);
        return ConsentEntity(
          consentType: (data is Map) ? (data['consent_type'] as String? ?? consentType) : consentType,
          version: (data is Map) ? (data['version'] as String? ?? '1.0') : '1.0',
          granted: (data is Map) ? (data['granted'] as bool? ?? true) : true,
          grantedAt: (data is Map && data['granted_at'] != null) ? DateTime.tryParse(data['granted_at']) : DateTime.now(),
        );
      } else {
        String message = 'Failed to record consent (${response.statusCode})';
        try {
          if (!response.body.trim().startsWith('<')) {
            final data = jsonDecode(response.body);
            if (data is Map && data['detail'] != null) {
              final detail = data['detail'];
              message = detail is String ? detail : detail.toString();
            }
          }
        } catch (_) {}
        throw ServerException(message, code: response.statusCode.toString());
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

      // Handle successful async submission status codes
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 202) {
        if (response.body.trim().startsWith('<') || response.body.isEmpty) {
          throw ServerException(
            'Server returned an invalid non-JSON response (${response.statusCode}). Please check your connection and try again.',
            code: response.statusCode.toString(),
          );
        }

        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          throw ServerException(
            'Failed to parse server upload response (${response.statusCode}).',
            code: response.statusCode.toString(),
          );
        }

        if (data is! Map) {
          throw const ServerException('Unexpected response structure from upload endpoint.');
        }

        final jobId = data['job_id'] as String? ?? data['id'] as String?;
        if (jobId == null || jobId.isEmpty) {
          throw const ServerException('Audio upload accepted, but no valid Job ID was returned by the server.');
        }

        return AudioJobEntity(
          jobId: jobId,
          status: data['status'] as String? ?? 'processing',
          message: data['message'] as String?,
        );
      } else {
        // Handle non-2xx status codes safely without crashing on HTML responses
        String errorMessage = 'Upload failed (${response.statusCode})';

        if (response.statusCode == 401 || response.statusCode == 403) {
          errorMessage = 'Session authentication required. Please log in again.';
        } else if (response.statusCode == 413) {
          errorMessage = 'The recorded audio file is too large to process. Please record a shorter sample.';
        } else if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
          errorMessage = 'The server is currently starting up or temporarily unavailable (${response.statusCode}). Please try again in a few moments.';
        } else {
          try {
            if (!response.body.trim().startsWith('<') && response.body.isNotEmpty) {
              final data = jsonDecode(response.body);
              if (data is Map && data['detail'] != null) {
                final detail = data['detail'];
                errorMessage = detail is String ? detail : detail.toString();
              }
            }
          } catch (_) {}
        }

        throw ServerException(errorMessage, code: response.statusCode.toString());
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
        if (response.body.trim().startsWith('<') || response.body.isEmpty) {
          throw ServerException(
            'Server returned an invalid non-JSON response while checking job status (${response.statusCode}).',
            code: response.statusCode.toString(),
          );
        }

        dynamic data;
        try {
          data = jsonDecode(response.body);
        } catch (_) {
          throw ServerException('Failed to parse audio job status JSON.', code: response.statusCode.toString());
        }

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
        String errorMsg = 'Failed to query job status (${response.statusCode})';
        if (response.statusCode == 502 || response.statusCode == 503 || response.statusCode == 504) {
          errorMsg = 'Server is currently processing. Retrying in a few moments...';
        } else {
          try {
            if (!response.body.trim().startsWith('<') && response.body.isNotEmpty) {
              final data = jsonDecode(response.body);
              if (data is Map && data['detail'] != null) {
                final detail = data['detail'];
                errorMsg = detail is String ? detail : detail.toString();
              }
            }
          } catch (_) {}
        }
        throw ServerException(errorMsg, code: response.statusCode.toString());
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
        if (!response.body.trim().startsWith('<') && response.body.isNotEmpty) {
          final decoded = jsonDecode(response.body);
          if (decoded is List) {
            return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        }
      }
      return [];
    } catch (_) {
      return [];
    }
  }
}
