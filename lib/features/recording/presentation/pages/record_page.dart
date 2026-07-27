import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_event.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../data/services/audio_player_service.dart';
import '../../data/services/audio_recorder_service.dart';
import '../bloc/audio_recording_bloc.dart';
import '../bloc/audio_recording_event.dart';
import '../bloc/audio_recording_state.dart';

/// Screen managing dual-mode cough and breathing audio recordings.
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int _selectedTabIndex = 0; // 0 = Cough, 1 = Breathing
  late final AudioPlayerService _audioPlayerService;
  
  bool _isPlaying = false;
  double _playProgress = 0.0;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playerPositionSubscription;
  StreamSubscription? _playerDurationSubscription;

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
      if (mounted && _duration.inMilliseconds > 0) {
        setState(() {
          _position = pos;
          _playProgress = (pos.inMilliseconds / _duration.inMilliseconds).clamp(0.0, 1.0);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Record Session'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
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
      body: BlocListener<AudioRecordingBloc, AudioRecordingState>(
        listener: (context, state) {
          if (state is AudioRecordingUploading || state is AudioRecordingJobPolling) {
            // Show non-dismissible loading dialog if not already shown
            _showProcessingDialog(context, state);
          } else if (state is AudioRecordingSuccess) {
            // Pop processing dialog
            Navigator.of(context, rootNavigator: true).pop();
            _handleSuccessAnalysis(context, state);
          } else if (state is AudioRecordingFailure) {
            // Pop processing dialog if open
            Navigator.of(context, rootNavigator: true).pop();
            _showErrorDialog(context, state);
          }
        },
        child: Column(
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
                    BlocBuilder<AudioRecordingBloc, AudioRecordingState>(
                      builder: (context, state) {
                        if (state is AudioRecordingPermissionDenied) {
                          return _buildPermissionWarning(context, state);
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Central Visual Microphone circle
                    BlocBuilder<AudioRecordingBloc, AudioRecordingState>(
                      builder: (context, state) {
                        final isRecording = state is AudioRecordingInProgress && !state.isPaused;
                        return _buildMicrophoneIndicator(isRecording);
                      },
                    ),
                    const SizedBox(height: 32),

                    // Time display & status label
                    BlocBuilder<AudioRecordingBloc, AudioRecordingState>(
                      builder: (context, state) {
                        return _buildTimerSection(state);
                      },
                    ),
                    const SizedBox(height: 40),

                    // Controls or Playback widgets depending on state
                    BlocBuilder<AudioRecordingBloc, AudioRecordingState>(
                      builder: (context, state) {
                        if (state is AudioRecordingReady) {
                          return Column(
                            children: [
                              _buildPlaybackPanel(context, state),
                              const SizedBox(height: 24),
                              _buildSubmitButton(context, state),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              _buildRecordingControls(context, state),
                              const SizedBox(height: 24),
                              _buildEnvironmentTipsAndPicker(context, state),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Navigation bar alignment
            _buildBottomNavMenu(),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionWarning(BuildContext context, AudioRecordingPermissionDenied state) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_off_rounded, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              state.message,
              style: const TextStyle(fontSize: 13, color: AppColors.text),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (state.isPermanentlyDenied) {
                sl<AudioRecorderService>().openAppSettings();
              } else {
                context.read<AudioRecordingBloc>().add(
                      AudioStartRecordingEvent(recordingType: _currentRecordingType),
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
            ),
            child: Text(state.isPermanentlyDenied ? 'Settings' : 'Grant'),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTabs() {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(26.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _onToggleTab(0),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(22.0),
                ),
                child: Text(
                  'Cough Recording',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 0 ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _onToggleTab(1),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(22.0),
                ),
                child: Text(
                  'Breathing Recording',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _selectedTabIndex == 1 ? AppColors.primary : AppColors.textSecondary,
                    fontSize: 14,
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
          Container(
            height: 200,
            width: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.supportingGreen.withOpacity(0.25), width: 3),
            ),
          ),
        Container(
          height: 150,
          width: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isRecording ? AppColors.supportingGreen : AppColors.supportingGreen.withOpacity(0.12),
            boxShadow: [
              BoxShadow(
                color: AppColors.supportingGreen.withOpacity(isRecording ? 0.35 : 0.05),
                blurRadius: 24,
                spreadRadius: 6,
              ),
            ],
          ),
          child: Icon(
            Icons.mic_none_rounded,
            size: 60,
            color: isRecording ? AppColors.surface : AppColors.supportingGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildTimerSection(AudioRecordingState state) {
    String statusLabel = 'READY TO RECORD';
    String timerText = '00:00';

    if (state is AudioRecordingInProgress) {
      statusLabel = state.isPaused ? 'PAUSED' : 'RECORDING...';
      timerText = _formatSeconds(state.durationSeconds);
    } else if (state is AudioRecordingReady) {
      statusLabel = state.isImported ? 'AUDIO FILE IMPORTED' : 'RECORDING COMPLETED';
    }

    return Column(
      children: [
        Text(
          timerText,
          style: const TextStyle(
            fontSize: 44,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          statusLabel,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingControls(BuildContext context, AudioRecordingState state) {
    final bloc = context.read<AudioRecordingBloc>();
    final inProgress = state is AudioRecordingInProgress;

    if (!inProgress) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.supportingGreen,
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            bloc.add(AudioStartRecordingEvent(recordingType: _currentRecordingType));
          },
          icon: const Icon(Icons.play_arrow_rounded, color: AppColors.surface),
          label: const Text(
            'Start Recording',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.surface, fontSize: 16),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
          ),
        ),
      );
    }

    final isPaused = state.isPaused;

    return Row(
      children: [
        // Discard / Cancel button
        IconButton(
          onPressed: () => bloc.add(const AudioCancelRecordingEvent()),
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 28),
          tooltip: 'Discard',
        ),
        const SizedBox(width: 12),

        // Pause / Resume button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              if (isPaused) {
                bloc.add(const AudioResumeRecordingEvent());
              } else {
                bloc.add(const AudioPauseRecordingEvent());
              }
            },
            icon: Icon(isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded, color: AppColors.primary),
            label: Text(isPaused ? 'Resume' : 'Pause'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Stop button
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => bloc.add(const AudioStopRecordingEvent()),
            icon: const Icon(Icons.stop_rounded, color: AppColors.surface),
            label: const Text('Stop'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.surface,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEnvironmentTipsAndPicker(BuildContext context, AudioRecordingState state) {
    final bloc = context.read<AudioRecordingBloc>();
    final isRecording = state is AudioRecordingInProgress;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Ensure you are in a quiet environment for optimal acoustic signature analysis.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12, height: 1.4),
          ),
        ),
        const SizedBox(height: 16),
        _buildPickFileButton(context),
      ],
    );
  }

  Widget _buildPickFileButton(BuildContext context) {
    final bloc = context.read<AudioRecordingBloc>();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: TextButton.icon(
        onPressed: _isUploading
            ? null
            : () {
                bloc.add(AudioPickFileEvent(recordingType: _currentRecordingType));
              },
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
        ),
        icon: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary, size: 22),
        label: const Text(
          'Upload Audio File from Device (.m4a, .wav, .mp3)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildPlaybackPanel(BuildContext context, AudioRecordingReady state) {
    final bloc = context.read<AudioRecordingBloc>();

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                state.isImported ? Icons.audio_file_rounded : Icons.mic_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  state.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
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
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.primary, size: 28),
                onPressed: () => _toggleAudioPlayback(state.filePath),
              ),
              Expanded(
                child: Slider(
                  value: _playProgress,
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
        onPressed: _isUploading
            ? null
            : () {
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

  void _showProcessingDialog(BuildContext context, AudioRecordingState state) {
    String msg = 'Processing audio...';
    if (state is AudioRecordingUploading) msg = state.statusMessage;
    if (state is AudioRecordingJobPolling) msg = state.statusMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: AppColors.primary),
                const SizedBox(height: 20),
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  onPressed: () {
                    context.read<AudioRecordingBloc>().add(const AudioCancelProcessingEvent());
                    Navigator.of(dialogContext, rootNavigator: true).pop();
                  },
                  icon: const Icon(Icons.cancel_outlined, color: AppColors.error, size: 18),
                  label: const Text('Cancel Processing', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.error),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
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
            Text('Upload Failed'),
          ],
        ),
        content: Text(
          state.message,
          style: const TextStyle(fontSize: 14, color: AppColors.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AudioRecordingBloc>().add(AudioUploadEvent(recordingType: _currentRecordingType));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.surface,
            ),
            child: const Text('Retry Upload'),
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
