import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_event.dart';
import '../../../dashboard/presentation/bloc/wellness_state.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// Screen managing dual-mode cough and breathing audio recordings.
class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  State<RecordPage> createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> {
  int _selectedTabIndex = 0; // 0 = Cough, 1 = Breathing
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;

  bool _hasRecording = false;
  bool _isPlaying = false;
  double _playProgress = 0.0;
  Timer? _playbackTimer;
  int _recordedDuration = 0;

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _playbackTimer?.cancel();
    super.dispose();
  }

  void _startRecording() {
    setState(() {
      _isRecording = true;
      _recordingSeconds = 0;
      _hasRecording = false;
      _isPlaying = false;
      _playProgress = 0.0;
    });

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _recordingSeconds++;
      });
    });
  }

  void _stopRecording() {
    _recordingTimer?.cancel();
    setState(() {
      _isRecording = false;
      _hasRecording = true;
      _recordedDuration = _recordingSeconds == 0 ? 12 : _recordingSeconds;
    });
  }

  void _deleteRecording() {
    _playbackTimer?.cancel();
    setState(() {
      _hasRecording = false;
      _isPlaying = false;
      _playProgress = 0.0;
      _recordingSeconds = 0;
      _recordedDuration = 0;
    });
  }

  void _togglePlayback() {
    if (_isPlaying) {
      _playbackTimer?.cancel();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      _playbackTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        setState(() {
          _playProgress += 0.1 / _recordedDuration;
          if (_playProgress >= 1.0) {
            _playProgress = 0.0;
            _isPlaying = false;
            _playbackTimer?.cancel();
          }
        });
      });
    }
  }

  void _simulateFileUpload() {
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );

    // Simulate file reading/processing delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      Navigator.pop(context); // Pop loading dialog
      setState(() {
        _hasRecording = true;
        _recordedDuration = 15; // Set simulated duration
        _playProgress = 0.0;
        _isPlaying = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio file imported successfully from device!'),
          backgroundColor: AppColors.success,
        ),
      );
    });
  }

  void _saveAndAnalyze() {
    final typeStr = _selectedTabIndex == 0 ? 'Cough' : 'Breathing';
    final lungsScore = _selectedTabIndex == 0 ? 92 : 89;
    final title = _selectedTabIndex == 0 ? 'Excellent Airflow' : 'Steady Breath Rhythm';
    final insight = _selectedTabIndex == 0
        ? 'Your recording shows a crisp, dry cough pattern with a clear respiratory rhythm. No significant wheezing or crackling was detected by the algorithm.'
        : 'Deep breathing patterns show healthy baseline capacity with stable and steady oxygen retention times.';

    final analysis = AudioAnalysisEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      type: typeStr,
      duration: _recordedDuration,
      confidence: 96,
      lungsScore: lungsScore,
      insight: insight,
      intensity: 'Moderate',
      breathingRate: 16,
      rhythm: 'Steady',
      signalQuality: 'Excellent',
      backgroundNoise: 'Low (Minimal Interference)',
      timestamp: DateTime.now(),
      tags: _selectedTabIndex == 0 ? const ['No Congestion', 'High Energy'] : const ['Clear Airways', 'Optimal Rhythm'],
    );

    context.read<WellnessBloc>().add(WellnessSaveAudioAnalysisEvent(analysis));
  }

  String _formatTimerText() {
    final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
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
      body: BlocListener<WellnessBloc, WellnessState>(
        listener: (context, state) {
          if (state.status == WellnessStatus.saveSuccess) {
            context.go('/dashboard');
          }
        },
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                child: Column(
                  children: [
                    // Tabs Pill Selector
                    _buildToggleTabs(),
                    const SizedBox(height: 50),

                    // Central Visual Microphone circle
                    _buildMicrophoneIndicator(),
                    const SizedBox(height: 40),

                    // Time display
                    _buildTimerSection(),
                    const SizedBox(height: 50),

                    // Recording controls & Playback widgets
                    if (!_hasRecording) ...[
                      // Start/Stop button
                      _buildStartStopButton(),
                      const SizedBox(height: 24),
                      // Tips & Upload
                      _buildEnvironmentTips(),
                    ] else ...[
                      // Playback panel
                      _buildPlaybackPanel(),
                      const SizedBox(height: 32),
                      // Save and Analyze
                      _buildAnalyzeActionCard(),
                    ],
                  ],
                ),
              ),
            ),

            // Embedded Mock bottom navigation bar to align with screen references
            _buildBottomNavMenu(),
          ],
        ),
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
              onTap: () {
                if (!_isRecording) setState(() => _selectedTabIndex = 0);
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 0 ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
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
              onTap: () {
                if (!_isRecording) setState(() => _selectedTabIndex = 1);
              },
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _selectedTabIndex == 1 ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
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

  Widget _buildMicrophoneIndicator() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Wave pulse animations when recording
        if (_isRecording)
          _buildPulseWaves(),
        
        Container(
          height: 160,
          width: 160,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isRecording ? AppColors.supportingGreen : AppColors.supportingGreen.withOpacity(0.15),
            boxShadow: [
              BoxShadow(
                color: AppColors.supportingGreen.withOpacity(_isRecording ? 0.3 : 0.05),
                blurRadius: 24,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Icon(
            Icons.mic_none_rounded,
            size: 64,
            color: _isRecording ? AppColors.surface : AppColors.supportingGreen,
          ),
        ),
      ],
    );
  }

  Widget _buildPulseWaves() {
    return Container(
      height: 220,
      width: 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.supportingGreen.withOpacity(0.2), width: 2),
      ),
    );
  }

  Widget _buildTimerSection() {
    String text = 'READY TO START';
    if (_isRecording) text = 'RECORDING...';
    if (_hasRecording) text = 'RECORDING COMPLETE';

    return Column(
      children: [
        Text(
          _hasRecording ? '00:${_recordedDuration.toString().padLeft(2, '0')}' : _formatTimerText(),
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
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

  Widget _buildStartStopButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _isRecording ? AppColors.error : AppColors.supportingGreen,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: ElevatedButton.icon(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        icon: Icon(_isRecording ? Icons.stop_rounded : Icons.play_arrow_rounded, color: AppColors.surface),
        label: Text(
          _isRecording ? 'Stop Recording' : 'Start Recording',
          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.surface, fontSize: 16),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
      ),
    );
  }

  Widget _buildEnvironmentTips() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Ensure you are in a quiet environment for the best medical analysis results.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary.withOpacity(0.8), fontSize: 12, height: 1.4),
          ),
        ),
        const SizedBox(height: 24),
        TextButton.icon(
          onPressed: _simulateFileUpload,
          icon: const Icon(Icons.upload_file_outlined, color: AppColors.primary),
          label: const Text(
            'Upload audio from device',
            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackPanel() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: AppColors.primary, size: 28),
            onPressed: _togglePlayback,
          ),
          Expanded(
            child: Slider(
              value: _playProgress,
              activeColor: AppColors.primary,
              inactiveColor: AppColors.border,
              onChanged: (val) {
                setState(() {
                  _playProgress = val;
                });
              },
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            onPressed: _deleteRecording,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyzeActionCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.supportingGreen],
        ),
      ),
      child: ElevatedButton(
        onPressed: _saveAndAnalyze,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.surface,
          shadowColor: Colors.transparent,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
        ),
        child: const Text(
          'Analyze Respiratory Track',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
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
        if (index == 0) {
          context.go('/dashboard');
        }
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
