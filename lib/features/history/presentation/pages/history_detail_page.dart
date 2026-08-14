import 'dart:async';
import 'dart:io';
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
  bool _hasAudioFile = false;

  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playerPositionSubscription;
  StreamSubscription? _playerDurationSubscription;

  @override
  void initState() {
    super.initState();
    _audioPlayerService = sl<AudioPlayerService>();

    if (widget.logType == 'audio' && widget.itemData is AudioAnalysisEntity) {
      final audio = widget.itemData as AudioAnalysisEntity;
      final path = audio.localAudioPath;
      if (path != null && path.isNotEmpty && File(path).existsSync()) {
        _hasAudioFile = true;
      }
    }

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
    final isComplete = item.status.toLowerCase() == 'complete';
    final isFailed = item.status.toLowerCase() == 'failed';
    final statusColor = isComplete
        ? AppColors.supportingGreen
        : (isFailed ? AppColors.error : AppColors.secondary);

    final isCough = item.type.toLowerCase() == 'cough';
    final typeName = isCough ? 'Cough' : 'Breathing';
    final themeColor = isCough ? AppColors.supportingGreen : AppColors.secondary;

    final normQ = item.normalizedQualityScore;
    final qualityStr = normQ != null
        ? '${normQ.toStringAsFixed(1)}%'
        : (item.confidence > 0 ? '${item.confidence}%' : 'N/A');

    final durationStr = item.durationSeconds != null
        ? '${item.durationSeconds!.toStringAsFixed(2)}s'
        : '${item.duration}s';

    final breathingRateStr = item.breathingRateBpm != null
        ? '${item.breathingRateBpm!.toStringAsFixed(1)} BPM'
        : (item.breathingRate > 0 ? '${item.breathingRate} BPM' : 'N/A');

    final breathCycleStr = item.breathCycleSeconds != null
        ? '${item.breathCycleSeconds!.toStringAsFixed(2)}s'
        : 'N/A';

    final dominantFreqStr = item.dominantFrequencyHz != null
        ? '${item.dominantFrequencyHz!.toStringAsFixed(1)} Hz'
        : 'N/A';

    final rmsStr = item.rmsEnergy != null
        ? item.rmsEnergy!.toStringAsFixed(3)
        : 'N/A';

    final zcrStr = item.zeroCrossingRate != null
        ? item.zeroCrossingRate!.toStringAsFixed(4)
        : 'N/A';

    final centroidStr = item.spectralCentroidHz != null
        ? '${item.spectralCentroidHz!.toStringAsFixed(1)} Hz'
        : null;

    final bandwidthStr = item.spectralBandwidthHz != null
        ? '${item.spectralBandwidthHz!.toStringAsFixed(1)} Hz'
        : null;

    final rolloffStr = item.spectralRolloffHz != null
        ? '${item.spectralRolloffHz!.toStringAsFixed(1)} Hz'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Top Header Card
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.text.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: themeColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            isCough ? Icons.sick_outlined : Icons.air_rounded,
                            color: themeColor,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '$typeName Recording',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.text),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _formatDate(item.timestamp),
                                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isComplete ? Icons.check_circle_rounded : (isFailed ? Icons.error_rounded : Icons.pending_rounded),
                          color: statusColor,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.status.toUpperCase(),
                          style: TextStyle(fontWeight: FontWeight.bold, color: statusColor, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (item.jobId != null && item.jobId!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Job ID: ${item.jobId}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontFamily: 'monospace'),
                ),
              ],
              if (isFailed && item.errorMessage != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Failure Reason: ${item.errorMessage}',
                          style: const TextStyle(color: AppColors.error, fontSize: 12.5, height: 1.3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),

        // 2. Audio Playback Section
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
                  const Text(
                    'Audio Playback',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                  ),
                  if (!_hasAudioFile && (item.localAudioPath == null || item.localAudioPath!.isEmpty))
                    const Text(
                      'Playback unavailable',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  IconButton(
                    iconSize: 44,
                    icon: Icon(
                      _isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded,
                      color: (_hasAudioFile || (item.localAudioPath != null && item.localAudioPath!.isNotEmpty))
                          ? AppColors.primary
                          : AppColors.textSecondary.withValues(alpha: 0.4),
                    ),
                    onPressed: () async {
                      final path = item.localAudioPath;
                      if (path == null || path.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Original recording audio file not found on device.')),
                        );
                        return;
                      }
                      if (_isPlaying) {
                        await _audioPlayerService.pause();
                      } else {
                        await _audioPlayerService.play(path);
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
                              Text(durationStr, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
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

        // 3. Recording Information Section
        const Text(
          'Recording Information',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
        ),
        const SizedBox(height: 10),
        _buildFeatureGrid([
          _FeatureItem('Type', typeName, Icons.category_outlined),
          _FeatureItem('Status', item.status.toUpperCase(), Icons.check_circle_outline_rounded),
          _FeatureItem('Duration', durationStr, Icons.timer_outlined),
          _FeatureItem('Date', '${item.timestamp.month}/${item.timestamp.day}/${item.timestamp.year}', Icons.calendar_today_outlined),
        ]),
        const SizedBox(height: 20),

        // 4. Primary Acoustic Analysis Section (Cough vs Breathing)
        Text(
          isCough ? 'Cough Analysis' : 'Breathing Analysis',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
        ),
        const SizedBox(height: 10),
        _buildFeatureGrid([
          _FeatureItem('Quality Score', qualityStr, Icons.speed_rounded),
          if (isCough)
            _FeatureItem('Cough Events', item.coughEventCount != null ? '${item.coughEventCount}' : 'N/A', Icons.graphic_eq_rounded),
          _FeatureItem('Breathing Rate', breathingRateStr, Icons.air_rounded),
          _FeatureItem('Breath Cycle', breathCycleStr, Icons.loop_rounded),
          _FeatureItem('Dominant Frequency', dominantFreqStr, Icons.waves_rounded),
          _FeatureItem('Classification', item.classification ?? (item.rhythm.isNotEmpty ? item.rhythm : 'Optimal'), Icons.insights_rounded),
        ]),
        const SizedBox(height: 20),

        // 5. Extracted Audio & Spectral Features Section
        const Text(
          'Audio & Spectral Features',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
        ),
        const SizedBox(height: 10),
        _buildFeatureGrid([
          _FeatureItem('RMS Energy', rmsStr, Icons.multiline_chart_rounded),
          _FeatureItem('Zero Crossing Rate', zcrStr, Icons.show_chart_rounded),
          if (centroidStr != null)
            _FeatureItem('Spectral Centroid', centroidStr, Icons.grain_rounded),
          if (bandwidthStr != null)
            _FeatureItem('Spectral Bandwidth', bandwidthStr, Icons.tune_rounded),
          if (rolloffStr != null)
            _FeatureItem('Spectral Rolloff', rolloffStr, Icons.linear_scale_rounded),
          _FeatureItem('Signal Quality', item.signalQuality.isNotEmpty ? item.signalQuality : 'Quality: $qualityStr', Icons.equalizer_rounded),
        ]),

        // 6. Advanced MFCCs (if available)
        if (item.mfccMeans != null && item.mfccMeans!.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text(
            'MFCC Acoustic Coefficients',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(item.mfccMeans!.length, (index) {
                final val = item.mfccMeans![index];
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    'MFCC ${index + 1}: ${val.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.text),
                  ),
                );
              }),
            ),
          ),
        ],

        const SizedBox(height: 24),
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
                  color: AppColors.primary.withValues(alpha: 0.12),
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
                    if (log.id.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ID: ${log.id}',
                        style: const TextStyle(fontSize: 10, color: AppColors.textSecondary, fontFamily: 'monospace'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Respiratory Symptoms (0-3 Severity Scale)
        const Text(
          'Recorded Symptoms (Clinical Scale: 0 - 3)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        _buildSymptomRow('Cough Severity', log.coughSeverity.toInt(), Icons.sick_outlined),
        _buildSymptomRow('Breathlessness', log.breathlessness.toInt(), Icons.air_rounded),
        _buildSymptomRow('Chest Tightness', log.chestTightness.toInt(), Icons.compress_rounded),
        _buildSymptomRow('Chest Discomfort Breathing', log.chestDiscomfortBreathing.toInt(), Icons.medical_services_outlined),
        _buildSymptomRow('Wheezing', log.wheezing.toInt(), Icons.insights_rounded),
        _buildSymptomRow('Mucus', log.mucus.toInt(), Icons.water_drop_outlined),
        _buildSymptomRow('Sleep Disruption', log.sleepDisruption.toInt(), Icons.bedtime_outlined),
        _buildSymptomRow('Chest Pain', log.chestPain.toInt(), Icons.favorite_border_rounded),
        _buildSymptomRow('Activity Limitation', log.activityLimitation.toInt(), Icons.directions_walk_rounded),
        _buildSymptomRow('Change From Usual', log.changeFromUsual.toInt(), Icons.trending_up_rounded),
        _buildSymptomRow('Fever', log.fever.toInt(), Icons.thermostat_outlined),
        const SizedBox(height: 20),

        // Daily Lifestyle Factors
        const Text(
          'Lifestyle & Vital Statistics',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
        ),
        const SizedBox(height: 12),
        _buildFeatureGrid([
          _FeatureItem('Smoking Today', log.smokedToday ? 'Yes (Smoked)' : 'No (Non-smoking)', Icons.smoke_free_outlined),
          _FeatureItem('Exercise Duration', '${log.exerciseMinutes.toInt()} mins', Icons.fitness_center_rounded),
          _FeatureItem('Sleep Duration', '${log.sleepHours.toStringAsFixed(1)} hrs', Icons.nightlight_round),
          _FeatureItem('Water Intake', '${log.waterIntakeLiters.toStringAsFixed(1)} L', Icons.water_drop_outlined),
        ]),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildScoreDetails(ScoreHistoryEntity score) {
    Color bandColor = AppColors.supportingGreen;
    if (score.band.toLowerCase() == 'attention' || score.band.toLowerCase() == 'low') {
      bandColor = AppColors.error;
    } else if (score.band.toLowerCase() == 'fair' || score.band.toLowerCase() == 'moderate') {
      bandColor = AppColors.secondary;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall Score Highlight Card
        Container(
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Overall Lung Wellness Score',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(score.timestamp),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: bandColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      score.band.toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.bold, color: bandColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(alpha: 0.08),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '${score.score}',
                      style: const TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
              if (score.message != null && score.message!.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  score.message!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Component Sub-Scores
        if (score.breakdown != null && score.breakdown!.isNotEmpty) ...[
          const Text(
            'Score Component Breakdown',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
          ),
          const SizedBox(height: 12),
          ...score.breakdown!.entries.map((entry) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatComponentName(entry.key),
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.text),
                  ),
                  Text(
                    '${entry.value}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primary),
                  ),
                ],
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildGenericDetails() {
    return const Center(
      child: Text('No detailed record found for this entry.', style: TextStyle(color: AppColors.textSecondary)),
    );
  }

  Widget _buildSymptomRow(String name, int severity, IconData icon) {
    String label = 'None';
    Color badgeColor = AppColors.supportingGreen;
    if (severity == 1) {
      label = 'Mild';
      badgeColor = AppColors.secondary;
    } else if (severity == 2) {
      label = 'Moderate';
      badgeColor = AppColors.warning;
    } else if (severity == 3) {
      label = 'Severe';
      badgeColor = AppColors.error;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
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

  String _formatComponentName(String key) {
    switch (key.toLowerCase()) {
      case 'c':
      case 'cough':
      case 'cough_score':
        return 'Cough Acoustic Score';
      case 'b':
      case 'breathing':
      case 'breathing_score':
        return 'Breathing Acoustic Score';
      case 's':
      case 'symptom':
      case 'symptom_score':
        return 'Symptom Score';
      case 't':
      case 'trend':
      case 'trend_score':
        return 'Personal Trend Score';
      default:
        return key.replaceAll('_', ' ').split(' ').map((word) => word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '').join(' ');
    }
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
