import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/services/audio_player_service.dart';
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
  final AudioPlayerService? playerService;
  final UploadAudioUseCase uploadAudioUseCase;
  final GetJobStatusUseCase getJobStatusUseCase;
  final CheckAndRecordConsentUseCase checkAndRecordConsentUseCase;

  StreamSubscription<int>? _durationSubscription;
  String? _currentFilePath;
  String _currentRecordingType = 'cough';
  String _fileName = '';

  AudioRecordingBloc({
    required this.recorderService,
    required this.filePickerService,
    this.playerService,
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
    on<AudioCancelProcessingEvent>(_onCancelProcessing);
    on<AudioTimerTickEvent>(_onTimerTick);
  }

  bool _isProcessingCancelled = false;

  void _onCancelProcessing(
    AudioCancelProcessingEvent event,
    Emitter<AudioRecordingState> emit,
  ) {
    _isProcessingCancelled = true;
    _durationSubscription?.cancel();
    _currentFilePath = null;
    emit(const AudioRecordingInitial());
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
    final path = _currentFilePath;
    if (path == null) return;
    await recorderService.pauseRecording();
    emit(AudioRecordingInProgress(
      durationSeconds: recorderService.elapsedSeconds,
      isPaused: true,
      recordingType: _currentRecordingType,
      filePath: path,
    ));
  }

  Future<void> _onResumeRecording(
    AudioResumeRecordingEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    final path = _currentFilePath;
    if (path == null) return;
    await recorderService.resumeRecording();
    emit(AudioRecordingInProgress(
      durationSeconds: recorderService.elapsedSeconds,
      isPaused: false,
      recordingType: _currentRecordingType,
      filePath: path,
    ));
  }

  Future<void> _onStopRecording(
    AudioStopRecordingEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    final recordedSeconds = recorderService.elapsedSeconds;
    _durationSubscription?.cancel();
    final path = await recorderService.stopRecording();
    if (path != null && path.isNotEmpty) {
      _currentFilePath = path;
      _fileName = path.split('/').last;
      emit(AudioRecordingReady(
        filePath: path,
        fileName: _fileName,
        recordingType: _currentRecordingType,
        isImported: false,
        durationSeconds: recordedSeconds,
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

        int durationSecs = 0;
        if (playerService != null) {
          try {
            final dur = await playerService!.getFileDuration(picked.path);
            if (dur != null && dur.inSeconds > 0) {
              durationSecs = dur.inSeconds;
            }
          } catch (_) {}
        }

        emit(AudioRecordingReady(
          filePath: picked.path,
          fileName: picked.name,
          recordingType: _currentRecordingType,
          isImported: true,
          durationSeconds: durationSecs,
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
    _isProcessingCancelled = true;
    _durationSubscription?.cancel();
    _currentFilePath = null;
    emit(const AudioRecordingInitial());
  }

  Future<void> _onUpload(
    AudioUploadEvent event,
    Emitter<AudioRecordingState> emit,
  ) async {
    _isProcessingCancelled = false;
    final filePath = _currentFilePath;
    if (filePath == null) {
      emit(const AudioRecordingFailure(message: 'No audio file available for upload.'));
      return;
    }

    emit(const AudioRecordingUploading(statusMessage: 'Uploading your recording...'));

    // Upload file to /recordings/cough or /recordings/breathing
    final uploadResult = await uploadAudioUseCase(
      path: filePath,
      recordingType: event.recordingType,
    );

    if (_isProcessingCancelled) return;

    await uploadResult.fold(
      (failure) async {
        if (!_isProcessingCancelled) {
          emit(AudioRecordingFailure(
            message: failure.message.isNotEmpty
                ? failure.message
                : 'The recording could not be submitted successfully. Please try again.',
            filePath: filePath,
            recordingType: event.recordingType,
          ));
        }
      },
      (job) async {
        if (_isProcessingCancelled) return;

        final trimmedJobId = job.jobId.trim();
        // The submission is considered successfully accepted only when the server response contains a valid job ID
        if (trimmedJobId.isEmpty) {
          emit(AudioRecordingFailure(
            message: 'The recording could not be submitted successfully. No valid job ID was returned. Please try again.',
            filePath: filePath,
            recordingType: event.recordingType,
          ));
          return;
        }

        // Start backend job processing/polling only after receiving a valid job ID
        emit(AudioRecordingJobPolling(
          jobId: trimmedJobId,
          statusMessage: 'Processing your recording... Please wait.',
        ));

        await _pollJobStatus(trimmedJobId, emit, filePath, event.recordingType);
      },
    );
  }

  Future<void> _pollJobStatus(
    String jobId,
    Emitter<AudioRecordingState> emit,
    String filePath,
    String recordingType,
  ) async {
    final trimmedJobId = jobId.trim();
    if (trimmedJobId.isEmpty) {
      emit(AudioRecordingFailure(
        message: 'Cannot check status: invalid recording reference.',
        filePath: filePath,
        recordingType: recordingType,
      ));
      return;
    }

    const maxPollAttempts = 30; // 30 attempts * 2s = 60s max
    int attempt = 0;

    while (attempt < maxPollAttempts) {
      if (_isProcessingCancelled) return;
      attempt++;
      await Future.delayed(const Duration(seconds: 2));
      if (_isProcessingCancelled) return;

      final jobResult = await getJobStatusUseCase(jobId);
      if (_isProcessingCancelled) return;

      bool isDone = false;

      jobResult.fold(
        (failure) {
          if (_isProcessingCancelled) return;
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
          if (_isProcessingCancelled) return;
          if (job.isCompleted) {
            emit(AudioRecordingSuccess(
              job: job,
              filePath: filePath,
              recordingType: recordingType,
            ));
            isDone = true;
          } else if (job.isFailed) {
            emit(AudioRecordingFailure(
              message: job.error ?? 'Recording analysis could not be completed.',
              jobId: jobId,
              filePath: filePath,
              recordingType: recordingType,
            ));
            isDone = true;
          } else {
            emit(AudioRecordingJobPolling(
              jobId: jobId,
              statusMessage: 'Analyzing your recording... Please wait.',
            ));
          }
        },
      );

      if (isDone) break;
    }

    if (!_isProcessingCancelled && attempt >= maxPollAttempts && state is AudioRecordingJobPolling) {
      emit(AudioRecordingFailure(
        message: 'Analysis timed out. Please try again.',
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
    _isProcessingCancelled = true;
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
