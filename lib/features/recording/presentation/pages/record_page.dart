import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_event.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../../data/services/audio_player_service.dart';
import '../bloc/audio_recording_bloc.dart';
import '../bloc/audio_recording_event.dart';
import '../bloc/audio_recording_state.dart';

/// Interactive audio recording and acoustic screening page.
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0; // 0 = Cough, 1 = Breathing
  late final AudioPlayerService _audioPlayerService;

  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _playerPositionSubscription;
  StreamSubscription<Duration>? _playerDurationSubscription;

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

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

  String get _currentRecordingType => _selectedTabIndex == 0 ? 'cough' : 'breathing';

  void _onToggleTab(int index) {
    final bloc = context.read<AudioRecordingBloc>();
    if (bloc.state is AudioRecordingInProgress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please stop or cancel the active recording before switching tabs.'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    setState(() {
      _selectedTabIndex = index;
    });
    bloc.add(const AudioResetEvent());
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

  void _onBack() {
    _audioPlayerService.stop();
    final bloc = context.read<AudioRecordingBloc>();
    if (bloc.state is AudioRecordingInProgress || bloc.state is AudioRecordingReady) {
      bloc.add(const AudioResetEvent());
    }
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Record Session'),
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _onBack,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary),
              onPressed: () {},
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16.0, left: 8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person, size: 18, color: AppColors.surface),
              ),
            ),
          ],
        ),
        body: BlocConsumer<AudioRecordingBloc, AudioRecordingState>(
          listener: (context, state) {
            if (state is AudioRecordingSuccess) {
              _handleSuccessAnalysis(context, state);
            } else if (state is AudioRecordingFailure) {
              _showErrorDialog(context, state);
            }
          },
          builder: (context, state) {
            // If currently uploading or polling, show in-place pipeline processing view
            if (state is AudioRecordingUploading || state is AudioRecordingJobPolling) {
              return _buildProcessingOverlay(context, state);
            }

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    child: Column(
                      children: [
                        // Tabs Pill Selector
                        _buildToggleTabs(),
                        const SizedBox(height: 32),

                        // Permission Warning (If Denied)
                        if (state is AudioRecordingPermissionDenied)
                          _buildPermissionWarning(context, state),

                        // Central Visual Microphone circle
                        _buildMicrophoneIndicator(state is AudioRecordingInProgress && !state.isPaused),
                        const SizedBox(height: 32),

                        // Time display & status label
                        _buildTimerSection(state),
                        const SizedBox(height: 40),

                        // Controls or Playback widgets depending on state
                        if (state is AudioRecordingReady)
                          Column(
                            children: [
                              _buildPlaybackPanel(context, state),
                              const SizedBox(height: 24),
                              _buildSubmitButton(context, state),
                            ],
                          )
                        else
                          Column(
                            children: [
                              _buildRecordingControls(context, state),
                              const SizedBox(height: 24),
                              _buildEnvironmentTipsAndPicker(context, state),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),

                // Navigation bar alignment
                _buildBottomNavMenu(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProcessingOverlay(BuildContext context, AudioRecordingState state) {
    String msg = 'Processing audio signature...';
    int currentStep = 1;
    if (state is AudioRecordingUploading) {
      msg = state.statusMessage;
      currentStep = 1;
    } else if (state is AudioRecordingJobPolling) {
      msg = state.statusMessage;
      currentStep = 2;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated Pulse Indicator
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.12),
            ),
            child: const Center(
              child: SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'Analyzing ${_currentRecordingType.toUpperCase()} Audio',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),

          // 3 Step Pipeline Progress Cards
          _buildProcessingStepItem(
            stepNumber: 1,
            title: 'Upload & Consent Check',
            isComplete: currentStep > 1,
            isActive: currentStep == 1,
          ),
          const SizedBox(height: 12),
          _buildProcessingStepItem(
            stepNumber: 2,
            title: 'Acoustic Feature Extraction',
            isComplete: currentStep > 2,
            isActive: currentStep == 2,
          ),
          const SizedBox(height: 12),
          _buildProcessingStepItem(
            stepNumber: 3,
            title: 'Neural Respiratory Classification',
            isComplete: false,
            isActive: currentStep == 3,
          ),
          const SizedBox(height: 40),

          // Immediate Cancel Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              onPressed: () {
                context.read<AudioRecordingBloc>().add(const AudioCancelProcessingEvent());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Processing cancelled. You can record a new audio.'),
                    backgroundColor: AppColors.warning,
                  ),
                );
              },
              icon: const Icon(Icons.close_rounded, color: AppColors.error, size: 20),
              label: const Text(
                'Cancel Processing',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.error, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingStepItem({
    required int stepNumber,
    required String title,
    required bool isComplete,
    required bool isActive,
  }) {
    final color = isComplete
        ? AppColors.supportingGreen
        : (isActive ? AppColors.primary : AppColors.textSecondary.withOpacity(0.4));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(
          color: isActive ? AppColors.primary.withOpacity(0.5) : AppColors.border,
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: color.withOpacity(0.15),
            child: isComplete
                ? const Icon(Icons.check_rounded, color: AppColors.supportingGreen, size: 16)
                : (isActive
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
                      )
                    : Text('$stepNumber', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isActive || isComplete ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
                color: isComplete || isActive ? AppColors.text : AppColors.textSecondary,
              ),
            ),
          ),
          if (isComplete)
            const Text(
              'Done',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.supportingGreen),
            )
          else if (isActive)
            const Text(
              'In Progress...',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
        ],
      ),
    );
  }

  Widget _buildPermissionWarning(BuildContext context, AudioRecordingPermissionDenied state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Microphone Access Required',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  state.message,
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTabs() {
    return Container(
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: AppColors.border.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onToggleTab(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: _selectedTabIndex == 0
                      ? [
                          BoxShadow(
                            color: AppColors.text.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Cough Sound',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedTabIndex == 0 ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onToggleTab(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? AppColors.surface : Colors.transparent,
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: _selectedTabIndex == 1
                      ? [
                          BoxShadow(
                            color: AppColors.text.withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    'Breathing Audio',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _selectedTabIndex == 1 ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMicrophoneIndicator(bool isRecording) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (isRecording)
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.2),
            duration: const Duration(milliseconds: 800),
            builder: (context, val, child) {
              return Container(
                width: 170 * val,
                height: 170 * val,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary.withOpacity(0.08 / val),
                ),
              );
            },
          ),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(
              color: isRecording ? AppColors.primary : AppColors.border,
              width: isRecording ? 3.0 : 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isRecording ? AppColors.primary.withOpacity(0.2) : AppColors.text.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            _selectedTabIndex == 0 ? Icons.sick_outlined : Icons.air_rounded,
            size: 54,
            color: isRecording ? AppColors.primary : AppColors.textSecondary,
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
      elapsed = 12; // Duration captured
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
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.border.withOpacity(0.3),
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
            bloc.add(AudioStartRecordingEvent(recordingType: _currentRecordingType));
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
                  color: AppColors.primary.withOpacity(0.3),
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
                  'Start ${_selectedTabIndex == 0 ? "Cough" : "Breathing"} Recording',
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
        // Cancel Action
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

        // Stop Action
        InkWell(
          onTap: () {
            bloc.add(const AudioStopRecordingEvent());
          },
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

  Widget _buildEnvironmentTipsAndPicker(BuildContext context, AudioRecordingState state) {
    final bloc = context.read<AudioRecordingBloc>();

    return Column(
      children: [
        // Upload from Device File Button
        OutlinedButton.icon(
          onPressed: () {
            _audioPlayerService.stop();
            bloc.add(AudioPickFileEvent(recordingType: _currentRecordingType));
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
        const SizedBox(height: 20),

        // Tips Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.tips_and_updates_outlined, size: 18, color: AppColors.primary),
                  SizedBox(width: 8),
                  Text(
                    'Optimal Recording Guidelines',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildBulletPoint('Hold your phone roughly 15-20 cm away from your mouth.'),
              _buildBulletPoint('Ensure background noise (fans, TV, traffic) is minimized.'),
              _buildBulletPoint(_selectedTabIndex == 0
                  ? 'Perform 3-5 distinct, natural coughs during the session.'
                  : 'Take deep, controlled inhalations and exhalations through mouth.'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackPanel(BuildContext context, AudioRecordingReady state) {
    final bloc = context.read<AudioRecordingBloc>();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
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
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
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
          const SizedBox(height: 16),

          // Audio Slider & Play Button
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

  Widget _buildSubmitButton(BuildContext context, AudioRecordingState state) {
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
          bloc.add(AudioUploadEvent(recordingType: _currentRecordingType));
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
          'Submit & Analyze Acoustic Signature (${_currentRecordingType.toUpperCase()})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  void _handleSuccessAnalysis(BuildContext context, AudioRecordingSuccess state) {
    final job = state.job;
    final qualityScore = ((job.qualityScore ?? 0.95) * 100).toInt();
    final classification = job.classification ?? 'Optimal Respiratory Sound';

    final analysisEntity = AudioAnalysisEntity(
      id: job.jobId,
      title: 'Acoustic Signature Analysis',
      type: _currentRecordingType.toUpperCase(),
      duration: (job.durationSeconds ?? 12).toInt(),
      confidence: qualityScore,
      lungsScore: qualityScore,
      insight: 'Acoustic parameters processed: Breathing Rate = ${job.breathingRateBpm ?? 16} BPM, Frequency = ${job.dominantFrequencyHz ?? 440} Hz, Classification = $classification.',
      intensity: 'Normal',
      breathingRate: (job.breathingRateBpm ?? 16).toInt(),
      rhythm: classification,
      signalQuality: 'Quality score: $qualityScore%',
      backgroundNoise: 'Low',
      timestamp: DateTime.now(),
      tags: ['FastAPI Engine', classification],
    );

    context.read<WellnessBloc>().add(WellnessSaveAudioAnalysisEvent(analysisEntity));

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
            SizedBox(width: 8),
            Text('Analysis Complete'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Job ID: ${job.jobId}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            _buildResultRow('Classification', classification),
            _buildResultRow('Quality Score', '$qualityScore%'),
            if (job.breathingRateBpm != null)
              _buildResultRow('Breathing Rate', '${job.breathingRateBpm!.toStringAsFixed(1)} BPM'),
            if (job.dominantFrequencyHz != null)
              _buildResultRow('Dominant Freq', '${job.dominantFrequencyHz!.toStringAsFixed(1)} Hz'),
            if (job.rmsEnergy != null)
              _buildResultRow('RMS Energy', job.rmsEnergy!.toStringAsFixed(3)),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AudioRecordingBloc>().add(const AudioRemoveFileEvent());
              context.go('/dashboard');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('View Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 13)),
        ],
      ),
    );
  }

  void _showErrorDialog(BuildContext context, AudioRecordingFailure state) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.error_outline_rounded, color: AppColors.error, size: 28),
            SizedBox(width: 8),
            Text('Processing Failed'),
          ],
        ),
        content: Text(
          state.message,
          style: const TextStyle(fontSize: 14, color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AudioRecordingBloc>().add(const AudioRemoveFileEvent());
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Clean up previous failed file and return to live microphone recording mode
              context.read<AudioRecordingBloc>().add(const AudioRemoveFileEvent());
            },
            icon: const Icon(Icons.mic_rounded, size: 18),
            label: const Text('Record Again'),
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

  Widget _buildBottomNavMenu() {
    return BottomNavigationBar(
      currentIndex: 1, // Record is selected
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      onTap: (index) {
        if (index == 1) return; // Already on recording page
        context.go('/dashboard?tab=$index');
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.mic),
          label: 'Record',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history_rounded),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}
