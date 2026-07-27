import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/audio_recorder_service.dart';
import '../../data/services/file_picker_service.dart';
import '../../domain/usecases/check_and_record_consent_usecase.dart';
import '../../domain/usecases/get_job_status_usecase.dart';
import '../../domain/usecases/upload_audio_usecase.dart';
import 'audio_recording_event.dart';
import 'audio_recording_state.dart';

class AudioRecordingBloc extends Bloc<AudioRecordingEvent, AudioRecordingState> {
  final AudioRecorderService recorderService;
  final FilePickerService filePickerService;
  final UploadAudioUseCase uploadAudioUseCase;
  final GetJobStatusUseCase getJobStatusUseCase;
  final CheckAndRecordConsentUseCase checkAndRecordConsentUseCase;

  StreamSubscription<int>? _durationSubscription;
  String? _currentFilePath;
  String _currentRecordingType = 'cough';
  bool _isImported = false;
  String _fileName = '';

  AudioRecordingBloc({
    required this.recorderService,
    required this.filePickerService,
    required this.uploadAudioUseCase,
    required this.getJobStatusUseCase,
    required this.checkAndRecordConsentUseCase,
  }) : super(const AudioRecordingInitial()) {
    on<AudioStartRecordingEvent>(_onStartRecording);
    on<AudioPauseRecordingEvent>(_onPauseRecording);
    on<AudioResumeRecordingEvent>(_onResumeRecording);
    on<AudioStopRecordingEvent>(_onStopRecording);
    on<AudioCancelRecordingEvent>(_onCancelRecording);
    on<AudioPickFileEvent>(_onPickFile);
    on<AudioRemoveFileEvent>(_onRemoveFile);
    on<AudioUploadEvent>(_onUpload);
    on<AudioResetEvent>(_onReset);
    on<AudioTimerTickEvent>(_onTimerTick);
  }

  void _onTimerTick(
    AudioTimerTickEvent event,
    Emitter<AudioRecordingState> emit,
  ) {
    if (state is AudioRecordingInProgress) {
      final current = state as AudioRecordingInProgress;
      emit(AudioRecordingInProgress(
        durationSeconds: event.durationSeconds,
        isPaused: current.isPaused,
        recordingType: current.recordingType,
        filePath: current.filePath,
      ));
    }
  }

  Future<void> _onStartRecording(
    AudioStartRecordingEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    try {
      final isGranted = await recorderService.requestMicrophonePermission();
      if (!isGranted) {
        final isPermanentlyDenied = await recorderService.isPermissionPermanentlyDenied();
        emit(AudioRecordingPermissionDenied(
          message: 'Microphone permission is required to record audio.',
          isPermanentlyDenied: isPermanentlyDenied,
        ));
        return;
      }

      _currentRecordingType = event.recordingType;
      _isImported = false;
      final path = await recorderService.startRecording();

      if (path == null) {
        emit(const AudioRecordingFailure(message: 'Failed to initialize audio recorder.'));
        return;
      }

      _currentFilePath = path;
      _fileName = path.split('/').last;

      _durationSubscription?.cancel();
      _durationSubscription = recorderService.durationStream.listen((durationSeconds) {
        if (!isClosed) {
          add(AudioTimerTickEvent(durationSeconds));
        }
      });

      emit(AudioRecordingInProgress(
        durationSeconds: recorderService.elapsedSeconds,
        isPaused: false,
        recordingType: _currentRecordingType,
        filePath: path,
      ));
    } catch (e) {
      emit(AudioRecordingFailure(message: e.toString()));
    }
  }

  Future<void> _onPauseRecording(
    AudioPauseRecordingEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    if (_currentFilePath == null) return;
    await recorderService.pauseRecording();
    emit(AudioRecordingInProgress(
      durationSeconds: recorderService.elapsedSeconds,
      isPaused: true,
      recordingType: _currentRecordingType,
      filePath: _currentFilePath!,
    ));
  }

  Future<void> _onResumeRecording(
    AudioResumeRecordingEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    if (_currentFilePath == null) return;
    await recorderService.resumeRecording();
    emit(AudioRecordingInProgress(
      durationSeconds: recorderService.elapsedSeconds,
      isPaused: false,
      recordingType: _currentRecordingType,
      filePath: _currentFilePath!,
    ));
  }

  Future<void> _onStopRecording(
    AudioStopRecordingEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    _durationSubscription?.cancel();
    final path = await recorderService.stopRecording();
    if (path != null) {
      _currentFilePath = path;
      _fileName = path.split('/').last;
      emit(AudioRecordingReady(
        filePath: path,
        fileName: _fileName,
        recordingType: _currentRecordingType,
        isImported: false,
      ));
    } else {
      emit(const AudioRecordingFailure(message: 'Recording returned an invalid path.'));
    }
  }

  Future<void> _onCancelRecording(
    AudioCancelRecordingEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    _durationSubscription?.cancel();
    await recorderService.cancelRecording();
    _currentFilePath = null;
    emit(const AudioRecordingInitial());
  }

  Future<void> _onPickFile(
    AudioPickFileEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    try {
      final picked = await filePickerService.pickAudioFile();
      if (picked != null) {
        _currentFilePath = picked.path;
        _fileName = picked.name;
        _currentRecordingType = event.recordingType;
        _isImported = true;

        emit(AudioRecordingReady(
          filePath: picked.path,
          fileName: picked.name,
          recordingType: _currentRecordingType,
          isImported: true,
        ));
      }
    } catch (e) {
      emit(AudioRecordingFailure(message: e.toString().replaceAll('Exception: ', '')));
    }
  }

  Future<void> _onRemoveFile(
    AudioRemoveFileEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    _currentFilePath = null;
    emit(const AudioRecordingInitial());
  }

  Future<void> _onUpload(
    AudioUploadEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    final filePath = _currentFilePath;
    if (filePath == null) {
      emit(const AudioRecordingFailure(message: 'No audio file available for upload.'));
      return;
    }

    emit(const AudioRecordingUploading(statusMessage: 'Verifying consent and preparing upload...'));

    // Step 1: Check and record user consent
    final consentResult = await checkAndRecordConsentUseCase();
    final consentGranted = consentResult.fold((_) => false, (consent) => consent.granted);
    if (!consentGranted) {
      emit(const AudioRecordingFailure(message: 'Audio recording consent is required by backend specifications.'));
      return;
    }

    // Step 2: Upload file to /recordings/cough or /recordings/breathing
    emit(const AudioRecordingUploading(statusMessage: 'Uploading audio signature to FastAPI...'));
    final uploadResult = await uploadAudioUseCase(
      path: filePath,
      recordingType: event.recordingType,
    );

    await uploadResult.fold(
      (failure) async {
        emit(AudioRecordingFailure(
          message: failure.message,
          filePath: filePath,
          recordingType: event.recordingType,
        ));
      },
      (job) async {
        // Step 3: Poll status of job until completed or failed
        emit(AudioRecordingJobPolling(
          jobId: job.jobId,
          statusMessage: 'Acoustic signature feature extraction in progress...',
        ));

        await _pollJobStatus(job.jobId, emit, filePath, event.recordingType);
      },
    );
  }

  Future<void> _pollJobStatus(
    String jobId,
    Emitter<AudioRecordingState> emit,
    String filePath,
    String recordingType,
  ) async {
    const maxPollAttempts = 30; // 30 attempts * 2s = 60s max
    int attempt = 0;

    while (attempt < maxPollAttempts) {
      attempt++;
      await Future.delayed(const Duration(seconds: 2));

      final jobResult = await getJobStatusUseCase(jobId);

      bool isDone = false;

      jobResult.fold(
        (failure) {
          // Keep retrying unless exceeded
          if (attempt >= maxPollAttempts) {
            emit(AudioRecordingFailure(
              message: failure.message,
              jobId: jobId,
              filePath: filePath,
              recordingType: recordingType,
            ));
            isDone = true;
          }
        },
        (job) {
          if (job.isCompleted) {
            emit(AudioRecordingSuccess(job: job));
            isDone = true;
          } else if (job.isFailed) {
            emit(AudioRecordingFailure(
              message: job.error ?? 'Acoustic analysis job failed.',
              jobId: jobId,
              filePath: filePath,
              recordingType: recordingType,
            ));
            isDone = true;
          } else {
            emit(AudioRecordingJobPolling(
              jobId: jobId,
              statusMessage: 'Processing acoustic features (attempt $attempt)...',
            ));
          }
        },
      );

      if (isDone) break;
    }

    if (attempt >= maxPollAttempts && state is AudioRecordingJobPolling) {
      emit(AudioRecordingFailure(
        message: 'Acoustic analysis timeout. The job took longer than 60 seconds.',
        jobId: jobId,
        filePath: filePath,
        recordingType: recordingType,
      ));
    }
  }

  Future<void> _onReset(
    AudioResetEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    _durationSubscription?.cancel();
    _currentFilePath = null;
    emit(const AudioRecordingInitial());
  }

  @override
  Future<void> close() {
    _durationSubscription?.cancel();
    recorderService.dispose();
    return super.close();
  }
}
