import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../recording/data/services/audio_player_service.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// Screen displaying the complete, authentic details of a specific history log.
class HistoryDetailPage extends StatefulWidget {
  final String logType; // 'audio', 'checkin', 'score'
  final dynamic itemData;

  const HistoryDetailPage({
    super.key,
    required this.logType,
    required this.itemData,
  });

  @override
  State<HistoryDetailPage> createState() => _HistoryDetailPageState();
}

class _HistoryDetailPageState extends State<HistoryDetailPage> {
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

  void _onBack() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/dashboard?tab=2');
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
          title: Text(_getTitle()),
          centerTitle: false,
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0.5,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _onBack,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.logType == 'audio' && widget.itemData is AudioAnalysisEntity)
                _buildAudioDetails(widget.itemData as AudioAnalysisEntity)
              else if (widget.logType == 'checkin' && widget.itemData is DailyLogEntity)
                _buildCheckInDetails(widget.itemData as DailyLogEntity)
              else if (widget.logType == 'score' && widget.itemData is ScoreHistoryEntity)
                _buildScoreDetails(widget.itemData as ScoreHistoryEntity)
              else
                _buildGenericDetails(),
            ],
          ),
        ),
      ),
    );
  }

  String _getTitle() {
    switch (widget.logType) {
      case 'audio':
        return 'Recording Details';
      case 'checkin':
        return 'Symptom Check-in';
      case 'score':
        return 'Wellness Score Details';
      default:
        return 'History Details';
    }
  }

  Widget _buildAudioDetails(AudioAnalysisEntity item) {
    final isGood = item.lungsScore >= 90;
    final statusColor = isGood ? AppColors.supportingGreen : AppColors.secondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header card
        Container(
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
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.mic_rounded, color: statusColor, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title.isNotEmpty ? item.title : '${item.type} Recording',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(item.timestamp),
                            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Score ${item.lungsScore}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 13),
                    ),
                  ),
                ],
              ),
              if (item.insight.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(color: AppColors.border),
                const SizedBox(height: 12),
                Text(
                  item.insight,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Audio Player Section
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Audio Playback',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    iconSize: 44,
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      color: AppColors.primary,
                    ),
                    onPressed: () async {
                      if (_isPlaying) {
                        await _audioPlayerService.pause();
                      } else {
                        // Play local file or asset if available
                        if (item.id.isNotEmpty) {
                          await _audioPlayerService.play(item.id);
                        }
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            trackHeight: 4,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          ),
                          child: Slider(
                            value: _playProgress,
                            activeColor: AppColors.primary,
                            inactiveColor: AppColors.border,
                            onChanged: (val) {
                              if (_duration.inMilliseconds > 0) {
                                final seekPos = Duration(milliseconds: (val * _duration.inMilliseconds).round());
                                _audioPlayerService.seek(seekPos);
                              }
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(_formatDuration(_position), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                              Text('${item.duration}s', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Extracted Acoustic Features Section
        const Text(
          'Extracted Acoustic Features',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        _buildFeatureGrid([
          _FeatureItem('Recording Type', item.type, Icons.category_outlined),
          _FeatureItem('Duration', '${item.duration}s', Icons.timer_outlined),
          _FeatureItem('Breathing Rate', item.breathingRate > 0 ? '${item.breathingRate} bpm' : 'N/A', Icons.air_rounded),
          _FeatureItem('Signal Quality', item.signalQuality.isNotEmpty ? item.signalQuality : 'Good', Icons.graphic_eq_rounded),
          _FeatureItem('Intensity', item.intensity.isNotEmpty ? item.intensity : 'Normal', Icons.speed_rounded),
          _FeatureItem('Background Noise', item.backgroundNoise.isNotEmpty ? item.backgroundNoise : 'Low', Icons.volume_down_outlined),
        ]),
      ],
    );
  }

  Widget _buildCheckInDetails(DailyLogEntity log) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fact_check_outlined, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Symptom Check-in',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Logged on ${_formatDate(log.timestamp)}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Respiratory Symptoms (0-10)
        const Text(
          'Recorded Symptoms (Scale: 0 - 10)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        _buildSymptomRow('Cough Severity', log.coughSeverity.toInt(), Icons.sick_outlined),
        _buildSymptomRow('Breathlessness', log.breathlessness.toInt(), Icons.air_rounded),
        _buildSymptomRow('Chest Tightness', log.chestTightness.toInt(), Icons.compress_rounded),
        _buildSymptomRow('Chest Discomfort Breathing', log.chestDiscomfortBreathing.toInt(), Icons.medical_services_outlined),
        _buildSymptomRow('Wheezing', log.wheezing.toInt(), Icons.insights_rounded),
        _buildSymptomRow('Mucus / Phlegm', log.mucus.toInt(), Icons.water_drop_outlined),
        _buildSymptomRow('Chest Pain', log.chestPain.toInt(), Icons.heart_broken_outlined),
        _buildSymptomRow('Fever Severity', log.fever.toInt(), Icons.thermostat_outlined),
        _buildSymptomRow('Activity Limitation', log.activityLimitation.toInt(), Icons.directions_walk_rounded),
        _buildSymptomRow('Sleep Disruption', log.sleepDisruption.toInt(), Icons.bedtime_outlined),
        const SizedBox(height: 24),

        // Lifestyle Factors
        const Text(
          'Lifestyle & Habits',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        _buildFeatureGrid([
          _FeatureItem('Smoked Today', log.smokedToday ? 'Yes' : 'No', Icons.smoking_rooms_outlined),
          _FeatureItem('Exercise', '${log.exerciseMinutes.toInt()} mins', Icons.fitness_center_rounded),
          _FeatureItem('Sleep Duration', '${log.sleepHours} hrs', Icons.nightlight_round),
          _FeatureItem('Water Intake', '${log.waterIntakeLiters} L', Icons.local_drink_rounded),
        ]),
      ],
    );
  }

  Widget _buildScoreDetails(ScoreHistoryEntity score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Score Header Card
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('LUNG WELLNESS SCORE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${score.score}',
                        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                      const Text('/100', style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Text(_formatDate(score.timestamp), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.supportingGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  score.band.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.supportingGreen, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        if (score.message != null && score.message!.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Text(score.message!, style: const TextStyle(fontSize: 13, color: AppColors.text, height: 1.4)),
          ),
        ],
        const SizedBox(height: 24),

        // Sub-Score Component Breakdown
        if (score.breakdown != null && score.breakdown!.isNotEmpty) ...[
          const Text('Component Sub-Scores', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary)),
          const SizedBox(height: 12),
          _buildFeatureGrid(score.breakdown!.entries.map((e) {
            return _FeatureItem(e.key.replaceAll('_', ' ').toUpperCase(), '${e.value}', Icons.analytics_outlined);
          }).toList()),
        ],
      ],
    );
  }

  Widget _buildGenericDetails() {
    return const Center(child: Text('No details available for this log entry.'));
  }

  Widget _buildSymptomRow(String name, int score, IconData icon) {
    Color badgeColor = AppColors.supportingGreen;
    if (score >= 7) {
      badgeColor = AppColors.error;
    } else if (score >= 4) {
      badgeColor = AppColors.secondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 12),
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$score / 10',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: badgeColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureGrid(List<_FeatureItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Icon(item.icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(item.title, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 2),
                    Text(item.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.text), overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime time) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minuteStr = time.minute.toString().padLeft(2, '0');
    return "${months[time.month - 1]} ${time.day}, ${time.year} at $hour:$minuteStr $period";
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}

class _FeatureItem {
  final String title;
  final String value;
  final IconData icon;

  _FeatureItem(this.title, this.value, this.icon);
}
