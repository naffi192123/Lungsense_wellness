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
import '../../../recording/presentation/widgets/recording_progress_timeline_widget.dart';

class CheckinRecordingWidget extends StatefulWidget {
  final String recordingType; // 'cough' or 'breathing'
  final int minDurationSeconds; // 8 for cough, 12 for breathing
  final int maxDurationSeconds; // 10 for cough, 15 for breathing
  final ValueChanged<AudioAnalysisEntity> onCompleted;

  const CheckinRecordingWidget({
    super.key,
    required this.recordingType,
    int? minDurationSeconds,
    int? maxDurationSeconds,
    required this.onCompleted,
  })  : minDurationSeconds = minDurationSeconds ?? (recordingType == 'cough' ? 8 : 12),
        maxDurationSeconds = maxDurationSeconds ?? (recordingType == 'cough' ? 10 : 15);

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
                  'Maximum recording duration reached (${widget.maxDurationSeconds}s).',
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

        int elapsed = 0;
        if (state is AudioRecordingInProgress) {
          elapsed = state.durationSeconds;
        } else if (state is AudioRecordingReady) {
          elapsed = state.durationSeconds > 0
              ? state.durationSeconds
              : (_duration.inSeconds > 0 ? _duration.inSeconds : 0);
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            children: [
              // Header Card with Highly Prominent Instructions
              _buildInstructionCard(),
              const SizedBox(height: 16),

              // Real-time Recording Progress Indicator Timeline
              RecordingProgressTimelineWidget(
                elapsedSeconds: elapsed,
                minDurationSeconds: widget.minDurationSeconds,
                maxDurationSeconds: widget.maxDurationSeconds,
                isRecording: state is AudioRecordingInProgress && !state.isPaused,
                isPaused: (state is AudioRecordingInProgress && state.isPaused),
                isCompleted: state is AudioRecordingReady,
                recordingType: widget.recordingType,
              ),
              const SizedBox(height: 24),

              // Permission Warning (if denied)
              if (state is AudioRecordingPermissionDenied)
                _buildPermissionWarning(context, state),

              // Microphone Indicator
              _buildMicrophoneIndicator(
                state is AudioRecordingInProgress && !state.isPaused,
              ),
              const SizedBox(height: 24),

              // Timer Section with Duration Limits
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
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: themeColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: themeColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  _isCough ? Icons.sick_outlined : Icons.air_rounded,
                  color: themeColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCough
                          ? 'Voluntary Cough Recording'
                          : 'Deep Breathing Recording',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: themeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _isCough
                            ? 'REQUIRED: ${widget.minDurationSeconds}s – ${widget.maxDurationSeconds}s'
                            : 'REQUIRED: ${widget.minDurationSeconds}s – ${widget.maxDurationSeconds}s',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12.5, color: AppColors.text, height: 1.35),
                          children: _isCough
                              ? const [
                                  TextSpan(text: 'Please produce '),
                                  TextSpan(
                                    text: '3 to 5 deliberate, voluntary coughs ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  TextSpan(text: 'clearly into your phone\'s microphone.'),
                                ]
                              : const [
                                  TextSpan(text: 'Take '),
                                  TextSpan(
                                    text: 'slow, steady, deep breaths ',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary),
                                  ),
                                  TextSpan(text: 'through your mouth or hold phone close to chest.'),
                                ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(color: themeColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    Expanded(
                      child: Text(
                        _isCough
                            ? 'Hold your phone ~15–20 cm (6–8 inches) away in a quiet room.'
                            : 'Ensure a quiet environment without background noise or talking.',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionWarning(BuildContext context, AudioRecordingPermissionDenied state) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.mic_off_rounded, color: AppColors.error, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  state.message,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.read<AudioRecordingBloc>().add(
                      AudioStartRecordingEvent(recordingType: widget.recordingType),
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                state.isPermanentlyDenied ? 'Open Settings' : 'Grant Permission',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
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
      elapsed = state.durationSeconds > 0
          ? state.durationSeconds
          : (_duration.inSeconds > 0 ? _duration.inSeconds : 0);
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
                '${widget.minDurationSeconds}s - ${widget.maxDurationSeconds}s',
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
                  'Start ${_typeName} Recording',
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
        // Cancel/Delete Action
        IconButton(
          iconSize: 32,
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          onPressed: () {
            bloc.add(const AudioCancelRecordingEvent());
          },
        ),
        const SizedBox(width: 24),

        // Pause/Resume Action
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

        // Stop/Finish Action
        InkWell(
          onTap: () {
            final int currentSeconds = state.durationSeconds;
            if (currentSeconds < widget.minDurationSeconds) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${_typeName} recording is too short (${currentSeconds}s). Minimum required is ${widget.minDurationSeconds}s.',
                  ),
                  backgroundColor: AppColors.warning,
                  duration: const Duration(seconds: 2),
                ),
              );
              return;
            }
            bloc.add(const AudioStopRecordingEvent());
          },
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppColors.supportingGreen,
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
            'Import Recorded Audio File',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 16, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Optimal Recording Guidelines',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: AppColors.text),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _buildBulletPoint('Hold your phone roughly 15-20 cm away from your mouth.'),
              _buildBulletPoint('Ensure background noise (fans, TV, traffic) is minimized.'),
              _buildBulletPoint(_isCough
                  ? 'Perform 3-5 distinct, deliberate voluntary coughs during the session.'
                  : 'Take deep, controlled inhalations and exhalations through mouth.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackPanel(BuildContext context, AudioRecordingReady state) {
    final bloc = context.read<AudioRecordingBloc>();
    final int displayDuration = state.durationSeconds > 0 ? state.durationSeconds : _duration.inSeconds;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.isImported
                          ? 'Imported from device (${displayDuration}s)'
                          : 'Recorded live (${displayDuration}s)',
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
                '${_position.inSeconds}s / ${displayDuration > 0 ? displayDuration : _duration.inSeconds}s',
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
          final int recordedDuration = state.durationSeconds > 0
              ? state.durationSeconds
              : (_duration.inSeconds > 0 ? _duration.inSeconds : widget.minDurationSeconds);
          if (recordedDuration < widget.minDurationSeconds && !state.isImported) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '${_typeName} recording is too short (${recordedDuration}s). A minimum of ${widget.minDurationSeconds}s is required for accurate acoustic analysis. Please re-record.',
                ),
                backgroundColor: AppColors.error,
                duration: const Duration(seconds: 3),
              ),
            );
            return;
          }
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
    String msg = 'Processing your recording...';
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
            'Analyzing $_typeName Recording',
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
            title: 'Uploading your recording...',
            isComplete: step > 1,
            isActive: step == 1,
          ),
          const SizedBox(height: 10),
          _buildPipelineStep(
            stepNum: 2,
            title: 'Processing your recording...',
            isComplete: step > 2,
            isActive: step == 2,
          ),
          const SizedBox(height: 10),
          _buildPipelineStep(
            stepNum: 3,
            title: 'Analyzing your recording...',
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
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
    Color bg = AppColors.surface;
    Color border = AppColors.border;
    Color textColor = AppColors.textSecondary;
    Widget leading = Text('$stepNum', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary));

    if (isComplete) {
      bg = AppColors.supportingGreen.withValues(alpha: 0.1);
      border = AppColors.supportingGreen;
      textColor = AppColors.text;
      leading = const Icon(Icons.check_circle_rounded, color: AppColors.supportingGreen, size: 20);
    } else if (isActive) {
      bg = AppColors.primary.withValues(alpha: 0.1);
      border = AppColors.primary;
      textColor = AppColors.primary;
      leading = const SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: textColor,
              ),
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
      duration: (job.durationSeconds ?? (isCough ? 16 : 30)).toInt(),
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
      tags: ['Acoustic Analysis', classification],
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
    String displayMessage = state.message.replaceAll('Exception: ', '').trim();
    if (displayMessage.contains('FormatException') || displayMessage.contains('<!DOCTYPE') || displayMessage.contains('<html>')) {
      displayMessage = 'The server is currently starting up or temporarily busy. Please wait a few seconds and try again.';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: AppColors.error, size: 28),
              SizedBox(width: 10),
              Text('Processing Failed', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayMessage,
                style: const TextStyle(fontSize: 14, color: AppColors.text, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                'Please ensure you have a stable network connection and try submitting again.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                context.read<AudioRecordingBloc>().add(const AudioResetEvent());
              },
              child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                final path = state.filePath;
                if (path != null && path.isNotEmpty) {
                  context.read<AudioRecordingBloc>().add(
                        AudioUploadEvent(recordingType: state.recordingType ?? widget.recordingType),
                      );
                } else {
                  context.read<AudioRecordingBloc>().add(
                        AudioStartRecordingEvent(recordingType: widget.recordingType),
                      );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                state.filePath != null ? 'Try Again' : 'Record Again',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }
}
