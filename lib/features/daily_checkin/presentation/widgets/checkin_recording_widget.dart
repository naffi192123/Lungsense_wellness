import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_event.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../../../recording/data/services/audio_player_service.dart';
import '../../../recording/presentation/bloc/audio_recording_bloc.dart';
import '../../../recording/presentation/bloc/audio_recording_event.dart';
import '../../../recording/presentation/bloc/audio_recording_state.dart';

class CheckinRecordingWidget extends StatefulWidget {
  final String recordingType; // 'cough' or 'breathing'
  final int maxDurationSeconds; // 20 for cough, 30 for breathing
  final ValueChanged<AudioAnalysisEntity> onCompleted;

  const CheckinRecordingWidget({
    super.key,
    required this.recordingType,
    required this.maxDurationSeconds,
    required this.onCompleted,
  });

  @override
  State<CheckinRecordingWidget> createState() => _CheckinRecordingWidgetState();
}

class _CheckinRecordingWidgetState extends State<CheckinRecordingWidget> {
  late final AudioPlayerService _audioPlayerService;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _playerPositionSubscription;
  StreamSubscription<Duration>? _playerDurationSubscription;

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  bool get _isCough => widget.recordingType.toLowerCase() == 'cough';
  String get _typeName => _isCough ? 'Cough' : 'Breathing';

  @override
  void initState() {
    super.initState();
    _audioPlayerService = sl<AudioPlayerService>();

    _playerStateSubscription = _audioPlayerService.stateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _playerPositionSubscription = _audioPlayerService.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });

    _playerDurationSubscription = _audioPlayerService.durationStream.listen((dur) {
      if (mounted) {
        setState(() {
          _duration = dur;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _playerPositionSubscription?.cancel();
    _playerDurationSubscription?.cancel();
    _audioPlayerService.stop();
    super.dispose();
  }

  Future<void> _toggleAudioPlayback(String filePath) async {
    if (_isPlaying) {
      await _audioPlayerService.pause();
    } else {
      await _audioPlayerService.play(filePath);
    }
  }

  String _formatSeconds(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AudioRecordingBloc, AudioRecordingState>(
      listener: (context, state) {
        // Auto-stop when reaching max duration
        if (state is AudioRecordingInProgress) {
          if (state.durationSeconds >= widget.maxDurationSeconds) {
            context.read<AudioRecordingBloc>().add(const AudioStopRecordingEvent());
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Maximum recording duration (${widget.maxDurationSeconds}s) reached.',
                ),
                backgroundColor: AppColors.primary,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        } else if (state is AudioRecordingSuccess) {
          _handleSuccess(context, state);
        } else if (state is AudioRecordingFailure) {
          _showErrorDialog(context, state);
        }
      },
      builder: (context, state) {
        if (state is AudioRecordingUploading || state is AudioRecordingJobPolling) {
          return _buildProcessingView(context, state);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // Header Card with Instructions
              _buildInstructionCard(),
              const SizedBox(height: 24),

              // Permission Warning (if denied)
              if (state is AudioRecordingPermissionDenied)
                _buildPermissionWarning(context, state),

              // Microphone Indicator
              _buildMicrophoneIndicator(
                state is AudioRecordingInProgress && !state.isPaused,
              ),
              const SizedBox(height: 24),

              // Timer Section with Max Duration Limit
              _buildTimerSection(state),
              const SizedBox(height: 32),

              // Controls or Playback Panel
              if (state is AudioRecordingReady) ...[
                _buildPlaybackPanel(context, state),
                const SizedBox(height: 20),
                _buildSubmitButton(context, state),
              ] else ...[
                _buildRecordingControls(context, state),
                const SizedBox(height: 20),
                _buildFilePickerAndTips(context, state),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInstructionCard() {
    final themeColor = _isCough ? AppColors.primary : AppColors.secondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isCough ? Icons.sick_outlined : Icons.air_rounded,
              color: themeColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_typeName Sound Recording',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isCough
                      ? 'Hold phone 15-20cm away. Cough 3-5 times clearly (max 20s).'
                      : 'Hold phone close to chest or mouth. Breathe deeply (max 30s).',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophoneIndicator(bool isRecording) {
    final themeColor = _isCough ? AppColors.primary : AppColors.secondary;

    return Stack(
      alignment: Alignment.center,
      children: [
        if (isRecording)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.2),
            duration: const Duration(milliseconds: 800),
            builder: (context, val, child) {
              return Container(
                width: 160 * val,
                height: 160 * val,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: themeColor.withValues(alpha: 0.1 / val),
                ),
              );
            },
          ),
        Container(
          width: 130,
          height: 130,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(
              color: isRecording ? themeColor : AppColors.border,
              width: isRecording ? 3.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isRecording
                    ? themeColor.withValues(alpha: 0.25)
                    : AppColors.text.withValues(alpha: 0.04),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            _isCough ? Icons.sick_outlined : Icons.air_rounded,
            size: 50,
            color: isRecording ? themeColor : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSection(AudioRecordingState state) {
    int elapsed = 0;
    String status = 'Ready to Record';

    if (state is AudioRecordingInProgress) {
      elapsed = state.durationSeconds;
      status = state.isPaused ? 'Recording Paused' : 'Recording in Progress...';
    } else if (state is AudioRecordingReady) {
      elapsed = 12;
      status = 'Recording Complete';
    }

    return Column(
      children: [
        Text(
          _formatSeconds(elapsed),
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.border.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                status,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Max: ${widget.maxDurationSeconds}s',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecordingControls(BuildContext context, AudioRecordingState state) {
    final bloc = context.read<AudioRecordingBloc>();
    final isRecording = state is AudioRecordingInProgress;
    final isPaused = isRecording && state.isPaused;

    if (!isRecording) {
      return Center(
        child: InkWell(
          onTap: () {
            _audioPlayerService.stop();
            bloc.add(AudioStartRecordingEvent(recordingType: widget.recordingType));
          },
          borderRadius: BorderRadius.circular(35),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.supportingGreen],
              ),
              borderRadius: BorderRadius.circular(35),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.mic, color: AppColors.surface, size: 24),
                const SizedBox(width: 10),
                Text(
                  'Start $_typeName Recording',
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cancel / Delete
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          onPressed: () => bloc.add(const AudioCancelRecordingEvent()),
        ),
        const SizedBox(width: 24),

        // Pause / Resume
        InkWell(
          onTap: () {
            if (isPaused) {
              bloc.add(const AudioResumeRecordingEvent());
            } else {
              bloc.add(const AudioPauseRecordingEvent());
            }
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(
              isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
              color: AppColors.text,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 24),

        // Stop
        InkWell(
          onTap: () => bloc.add(const AudioStopRecordingEvent()),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stop_rounded,
              color: AppColors.surface,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilePickerAndTips(BuildContext context, AudioRecordingState state) {
    final bloc = context.read<AudioRecordingBloc>();

    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () {
            _audioPlayerService.stop();
            bloc.add(AudioPickFileEvent(recordingType: widget.recordingType));
          },
          icon: const Icon(Icons.file_upload_outlined, size: 18, color: AppColors.primary),
          label: const Text(
            'Import Audio File From Device',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackPanel(BuildContext context, AudioRecordingReady state) {
    final bloc = context.read<AudioRecordingBloc>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.fileName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.isImported ? 'Imported from device' : 'Recorded live via microphone',
                      style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                onPressed: () {
                  _audioPlayerService.stop();
                  bloc.add(const AudioRemoveFileEvent());
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              IconButton(
                icon: Icon(
                  _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                  color: AppColors.primary,
                  size: 38,
                ),
                onPressed: () => _toggleAudioPlayback(state.filePath),
              ),
              Expanded(
                child: Slider(
                  value: _duration.inMilliseconds > 0
                      ? (_position.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0)
                      : 0.0,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.border,
                  onChanged: (val) {
                    final targetMs = (val * _duration.inMilliseconds).toInt();
                    _audioPlayerService.seek(Duration(milliseconds: targetMs));
                  },
                ),
              ),
              Text(
                '${_position.inSeconds}s / ${_duration.inSeconds}s',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(BuildContext context, AudioRecordingReady state) {
    final bloc = context.read<AudioRecordingBloc>();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.supportingGreen],
        ),
      ),
      child: ElevatedButton(
        onPressed: () {
          _audioPlayerService.stop();
          bloc.add(AudioUploadEvent(recordingType: widget.recordingType));
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.surface,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        child: Text(
          'Analyze & Continue ($_typeName)',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildProcessingView(BuildContext context, AudioRecordingState state) {
    String msg = 'Processing audio signature...';
    int step = 1;
    if (state is AudioRecordingUploading) {
      msg = state.statusMessage;
      step = 1;
    } else if (state is AudioRecordingJobPolling) {
      msg = state.statusMessage;
      step = 2;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.12),
            ),
            child: const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Analyzing $_typeName Audio',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),
          _buildPipelineStep(
            stepNum: 1,
            title: 'Uploading Audio Signature',
            isComplete: step > 1,
            isActive: step == 1,
          ),
          const SizedBox(height: 10),
          _buildPipelineStep(
            stepNum: 2,
            title: 'Acoustic Feature Extraction',
            isComplete: step > 2,
            isActive: step == 2,
          ),
          const SizedBox(height: 10),
          _buildPipelineStep(
            stepNum: 3,
            title: 'Acoustic Scoring & Verification',
            isComplete: false,
            isActive: step == 3,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AudioRecordingBloc>().add(const AudioCancelProcessingEvent());
              },
              icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 18),
              label: const Text(
                'Cancel Processing',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineStep({
    required int stepNum,
    required String title,
    required bool isComplete,
    required bool isActive,
  }) {
    final color = isComplete
        ? AppColors.supportingGreen
        : (isActive ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.4));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isActive ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.15),
            child: isComplete
                ? const Icon(Icons.check_rounded, color: AppColors.supportingGreen, size: 14)
                : (isActive
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                      )
                    : Text('$stepNum', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive || isComplete ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
                color: isComplete || isActive ? AppColors.text : AppColors.textSecondary,
              ),
            ),
          ),
          if (isComplete)
            const Text(
              'Done ✓',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.supportingGreen),
            )
          else if (isActive)
            const Text(
              'In Progress...',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionWarning(BuildContext context, AudioRecordingPermissionDenied state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20.0),
      padding: const EdgeInsets.all(14.0),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              state.message,
              style: const TextStyle(color: AppColors.text, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSuccess(BuildContext context, AudioRecordingSuccess state) {
    final job = state.job;
    final typeName = _typeName;
    final isCough = _isCough;
    final audioPath = state.filePath;

    final double? normQ = job.normalizedQualityScore;
    final int qScoreInt = (normQ ?? 85.0).round();
    final String classification = job.classification ?? '$typeName Acoustic Signature Analyzed';

    final analysisEntity = AudioAnalysisEntity(
      id: job.jobId,
      title: '$typeName Recording',
      type: typeName,
      status: job.status.toLowerCase(),
      duration: (job.durationSeconds ?? (isCough ? 12 : 20)).toInt(),
      durationSeconds: job.durationSeconds,
      confidence: qScoreInt,
      lungsScore: qScoreInt,
      insight: 'Acoustic parameters processed: Breathing Rate = ${job.breathingRateBpm != null ? '${job.breathingRateBpm!.toStringAsFixed(1)} BPM' : 'N/A'}, Dominant Frequency = ${job.dominantFrequencyHz != null ? '${job.dominantFrequencyHz!.toStringAsFixed(1)} Hz' : 'N/A'}, Classification = $classification.',
      intensity: 'Normal',
      breathingRate: (job.breathingRateBpm ?? 0).toInt(),
      breathingRateBpm: job.breathingRateBpm,
      breathCycleSeconds: job.breathCycleSeconds,
      coughEventCount: isCough ? job.coughEventCount : null,
      rhythm: classification,
      signalQuality: normQ != null ? 'Quality: ${normQ.toStringAsFixed(1)}%' : 'Quality: $qScoreInt%',
      backgroundNoise: 'Low',
      timestamp: job.createdAt ?? DateTime.now(),
      completedAt: job.completedAt ?? DateTime.now(),
      tags: ['FastAPI Engine', classification],
      localAudioPath: audioPath,
      jobId: job.jobId,
      qualityScore: job.qualityScore,
      dominantFrequencyHz: job.dominantFrequencyHz,
      rmsEnergy: job.rmsEnergy,
      zeroCrossingRate: job.zeroCrossingRate,
      classification: classification,
      errorMessage: job.error,
      spectralSummary: job.spectralSummary,
      qualityBreakdown: job.qualityBreakdown,
      segmentation: job.segmentation,
      mfccMeans: job.mfccMeans,
    );

    // Save to BLoC repository so dashboard & history update
    context.read<WellnessBloc>().add(WellnessSaveAudioAnalysisEvent(analysisEntity));

    // Reset AudioRecordingBloc so next recording step starts fresh
    context.read<AudioRecordingBloc>().add(const AudioResetEvent());

    // Advance daily checkin workflow
    widget.onCompleted(analysisEntity);
  }

  void _showErrorDialog(BuildContext context, AudioRecordingFailure state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
            SizedBox(width: 10),
            Text('Processing Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Text(
          state.message,
          style: const TextStyle(fontSize: 13.5, color: AppColors.text, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AudioRecordingBloc>().add(const AudioRemoveFileEvent());
            },
            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AudioRecordingBloc>().add(const AudioRemoveFileEvent());
            },
            icon: const Icon(Icons.mic_rounded, size: 16),
            label: const Text('Try Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}
