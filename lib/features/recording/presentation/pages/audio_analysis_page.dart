import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_event.dart';
import '../../../dashboard/presentation/bloc/wellness_state.dart';

/// Page displaying full respiratory audio analysis details, charts, and baseline scoring.
class AudioAnalysisPage extends StatefulWidget {
  const AudioAnalysisPage({super.key});

  @override
  State<AudioAnalysisPage> createState() => _AudioAnalysisPageState();
}

class _AudioAnalysisPageState extends State<AudioAnalysisPage> {
  bool _isPlaying = false;
  double _playProgress = 0.0;

  void _generateLungHealthScore() {
    final analysis = AudioAnalysisEntity(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Excellent Airflow',
      type: 'Cough',
      duration: 12,
      confidence: 98,
      lungsScore: 92,
      insight: 'Your recording shows a crisp, dry cough pattern with a clear respiratory rhythm. No significant wheezing or crackling was detected by the algorithm. This profile is consistent with minor throat irritation rather than deep lung congestion.',
      intensity: 'Moderate',
      breathingRate: 16,
      rhythm: 'Steady',
      signalQuality: 'Excellent',
      backgroundNoise: 'Low (Minimal Interference)',
      timestamp: DateTime.now(),
      tags: const ['No Congestion', 'High Energy'],
    );

    context.read<WellnessBloc>().add(WellnessSaveAudioAnalysisEvent(analysis));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Audio Analysis'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/dashboard'),
        ),
      ),
      body: BlocListener<WellnessBloc, WellnessState>(
        listener: (context, state) {
          if (state.status == WellnessStatus.saveSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Audio analysis saved successfully!'),
                backgroundColor: AppColors.success,
              ),
            );
            context.go('/dashboard');
          }
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Analysis Header
              _buildAnalysisHeader(),
              const SizedBox(height: 20),

              // Waveform Timeline Player
              _buildPlayerCard(),
              const SizedBox(height: 20),

              // Lungs score circle
              _buildLungsScoreCard(),
              const SizedBox(height: 20),

              // Heatmap Spectrogram
              _buildSpectrogramCard(),
              const SizedBox(height: 20),

              // AI Insight card
              _buildInsightCard(),
              const SizedBox(height: 20),

              // Details Grid
              _buildDetailsGrid(),
              const SizedBox(height: 20),



              // Findings & Tips
              _buildFindingsCard(),
              const SizedBox(height: 32),

              // Save Actions
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisHeader() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.supportingGreen,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analysis Complete',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.surface, fontSize: 16),
              ),
              SizedBox(height: 4),
              Text(
                'Type: Cough  •  Duration: 12s',
                style: TextStyle(color: AppColors.surface, fontSize: 13),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            decoration: BoxDecoration(
              color: AppColors.surface.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: const Text(
              'High Confidence',
              style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.surface, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Audio Fingerprint', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text(
                '0:0${(_playProgress * 12).toInt()} / 0:12',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Waveform bar indicator
          Slider(
            value: _playProgress,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.border,
            onChanged: (val) {
              setState(() {
                _playProgress = val;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded, color: AppColors.primary),
                onPressed: () {
                  setState(() {
                    _playProgress = (_playProgress - 0.1).clamp(0.0, 1.0);
                  });
                },
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isPlaying = !_isPlaying;
                  });
                },
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary,
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: AppColors.surface,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded, color: AppColors.primary),
                onPressed: () {
                  setState(() {
                    _playProgress = (_playProgress + 0.1).clamp(0.0, 1.0);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLungsScoreCard() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Text(
            'Lungs Health Score',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.text),
          ),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: 0.89,
                  strokeWidth: 12,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.supportingGreen),
                ),
              ),
              const Column(
                children: [
                  Text(
                    '89',
                    style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.text),
                  ),
                  Text(
                    'SCORE / 100',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: AppColors.supportingGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: AppColors.supportingGreen, size: 16),
                SizedBox(width: 6),
                Text(
                  'Healthy Baseline',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.supportingGreen, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectrogramCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Heatmap Spectrogram', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              IconButton(
                icon: const Icon(Icons.info_outline_rounded, color: AppColors.textSecondary, size: 20),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Spectrogram visualization card
          Container(
            height: 120,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F0E26), // Dark blue spectrogram backdrop
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: CustomPaint(
              painter: _SpectrogramPainter(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Energy distribution remains within expected clinical ranges for a non-productive cough signature.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.primary.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.primary, size: 22),
              SizedBox(width: 8),
              Text(
                'AI Insight',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Your recording shows a crisp, dry cough pattern with a clear respiratory rhythm. No significant wheezing or crackling was detected by the algorithm. This profile is consistent with minor throat irritation rather than deep lung congestion.',
            style: TextStyle(color: AppColors.text, fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.2,
      children: [
        _buildDetailTile('Cough Intensity', 'Moderate', Icons.volume_up_outlined),
        _buildDetailTile('Breathing Rate', '16 bpm', Icons.speed_rounded),
        _buildDetailTile('Rhythm', 'Steady', Icons.sync_rounded),
        _buildDetailTile('Signal Quality', 'Excellent', Icons.check_circle_outline_rounded),
      ],
    );
  }

  Widget _buildDetailTile(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.secondary, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.text),
              ),
            ],
          ),
        ],
      ),
    );
  }



  Widget _buildFindingsCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personalized Findings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 16),
          _buildFindingRow('1', 'No evidence of nocturnal wheezing detected in this sample.'),
          const SizedBox(height: 12),
          _buildFindingRow('2', 'Your breath recovery time is under 1.5 seconds, which is optimal.'),
          const Divider(color: AppColors.border, height: 24),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.secondary, size: 18),
              SizedBox(width: 8),
              Text(
                'Wellness Tip',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Stay hydrated to soothe throat-based coughs detected in this report.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFindingRow(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 9,
          backgroundColor: AppColors.supportingGreen.withOpacity(0.15),
          child: Text(
            number,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.supportingGreen),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.4),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            gradient: const LinearGradient(
              colors: [AppColors.primary, AppColors.supportingGreen],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ElevatedButton(
            onPressed: _generateLungHealthScore,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              foregroundColor: AppColors.surface,
              shadowColor: Colors.transparent,
              minimumSize: const Size(double.infinity, 52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            child: const Text(
              'Generate Lung Health Score',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go('/dashboard'),
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.share_outlined),
                label: const Text('Share'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.text,
                  side: const BorderSide(color: AppColors.border),
                  padding: const EdgeInsets.symmetric(vertical: 14.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Custom Spectrogram wave animation canvas.
class _SpectrogramPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()..style = PaintingStyle.fill;
    
    // Paint visual bars matching spectrogram
    for (int i = 0; i < size.width; i += 6) {
      final heightFactor = (i % 24 == 0) ? 0.8 : (i % 12 == 0) ? 0.5 : 0.3;
      final waveHeight = size.height * heightFactor;
      
      wavePaint.shader = LinearGradient(
        colors: [
          const Color(0xFFF25C05).withOpacity(0.8), // Orange/red high intensity energy
          const Color(0xFF02735E).withOpacity(0.2), // Teal low intensity energy
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      ).createShader(Rect.fromLTRB(i.toDouble(), size.height - waveHeight, i + 4.0, size.height));
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(i.toDouble(), size.height - waveHeight, i + 4.0, size.height),
          const Radius.circular(2.0),
        ),
        wavePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


