import 'package:equatable/equatable.dart';
import '../../domain/entities/audio_recording_entities.dart';

abstract class AudioRecordingState extends Equatable {
  const AudioRecordingState();

  @override
  List<Object?> get props => [];
}

class AudioRecordingInitial extends AudioRecordingState {
  const AudioRecordingInitial();
}

class AudioRecordingPermissionDenied extends AudioRecordingState {
  final String message;
  final bool isPermanentlyDenied;

  const AudioRecordingPermissionDenied({
    required this.message,
    required this.isPermanentlyDenied,
  });

  @override
  List<Object?> get props => [message, isPermanentlyDenied];
}

class AudioRecordingInProgress extends AudioRecordingState {
  final int durationSeconds;
  final bool isPaused;
  final String recordingType;
  final String filePath;

  const AudioRecordingInProgress({
    required this.durationSeconds,
    required this.isPaused,
    required this.recordingType,
    required this.filePath,
  });

  @override
  List<Object?> get props => [durationSeconds, isPaused, recordingType, filePath];
}

class AudioRecordingReady extends AudioRecordingState {
  final String filePath;
  final String fileName;
  final String recordingType;
  final bool isImported;
  final int durationSeconds;

  const AudioRecordingReady({
    required this.filePath,
    required this.fileName,
    required this.recordingType,
    required this.isImported,
    this.durationSeconds = 0,
  });

  @override
  List<Object?> get props => [filePath, fileName, recordingType, isImported, durationSeconds];
}

class AudioRecordingUploading extends AudioRecordingState {
  final String statusMessage;

  const AudioRecordingUploading({required this.statusMessage});

  @override
  List<Object?> get props => [statusMessage];
}

class AudioRecordingJobPolling extends AudioRecordingState {
  final String jobId;
  final String statusMessage;

  const AudioRecordingJobPolling({
    required this.jobId,
    required this.statusMessage,
  });

  @override
  List<Object?> get props => [jobId, statusMessage];
}

class AudioRecordingSuccess extends AudioRecordingState {
  final AudioJobEntity job;
  final String? filePath;
  final String? recordingType;

  const AudioRecordingSuccess({
    required this.job,
    this.filePath,
    this.recordingType,
  });

  @override
  List<Object?> get props => [job, filePath, recordingType];
}

class AudioRecordingFailure extends AudioRecordingState {
  final String message;
  final String? jobId;
  final String? filePath;
  final String? recordingType;

  const AudioRecordingFailure({
    required this.message,
    this.jobId,
    this.filePath,
    this.recordingType,
  });

  @override
  List<Object?> get props => [message, jobId, filePath, recordingType];
}
