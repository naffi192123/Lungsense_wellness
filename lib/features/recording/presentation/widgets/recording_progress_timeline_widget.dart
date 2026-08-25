import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Real-time horizontal recording timeline and progress indicator.
///
/// Displays:
/// - Clean rounded container matching the LungSense theme.
/// - Live header with status pill and elapsed/max duration display (e.g. 00:08 / 00:30).
/// - Horizontal progress bar filled with LungSense green gradient.
/// - Smooth animated thumb indicator at the active position.
/// - Discrete tick marks and labels at 0s, 5s, 10s, 15s, 20s (cough) or up to 30s (breathing).
/// - Active ticks turn bold LungSense green when reached.
class RecordingProgressTimelineWidget extends StatelessWidget {
  final int elapsedSeconds;
  final int minDurationSeconds;
  final int maxDurationSeconds;
  final bool isRecording;
  final bool isPaused;
  final bool isCompleted;
  final String recordingType;

  const RecordingProgressTimelineWidget({
    super.key,
    required this.elapsedSeconds,
    this.minDurationSeconds = 16,
    required this.maxDurationSeconds,
    required this.isRecording,
    required this.isPaused,
    required this.isCompleted,
    required this.recordingType,
  });

  String _formatTime(int seconds) {
    final mins = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  List<int> _generateTicks() {
    final List<int> ticks = [];
    for (int t = 0; t <= maxDurationSeconds; t += 5) {
      ticks.add(t);
    }
    if (!ticks.contains(maxDurationSeconds)) {
      ticks.add(maxDurationSeconds);
    }
    return ticks;
  }

  @override
  Widget build(BuildContext context) {
    final clampedElapsed = elapsedSeconds.clamp(0, maxDurationSeconds);
    final progressFraction = maxDurationSeconds > 0
        ? (clampedElapsed / maxDurationSeconds).clamp(0.0, 1.0)
        : 0.0;
    final minFraction = maxDurationSeconds > 0
        ? (minDurationSeconds / maxDurationSeconds).clamp(0.0, 1.0)
        : 0.0;
    final isMinReached = clampedElapsed >= minDurationSeconds;
    final ticks = _generateTicks();
    final isCough = recordingType.toLowerCase().contains('cough');
    final typeLabel = isCough ? 'Cough Audio' : 'Breathing Audio';

    Color statusColor;
    String statusText;
    IconData statusIcon;

    if (isCompleted) {
      statusColor = AppColors.supportingGreen;
      statusText = 'COMPLETED';
      statusIcon = Icons.check_circle_rounded;
    } else if (isRecording) {
      statusColor = isMinReached ? AppColors.supportingGreen : AppColors.primary;
      statusText = 'RECORDING';
      statusIcon = Icons.radio_button_checked_rounded;
    } else if (isPaused) {
      statusColor = AppColors.warning;
      statusText = 'PAUSED';
      statusIcon = Icons.pause_circle_filled_rounded;
    } else {
      statusColor = AppColors.textSecondary;
      statusText = 'READY';
      statusIcon = Icons.timer_outlined;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18.0),
        border: Border.all(
          color: isRecording
              ? (isMinReached ? AppColors.supportingGreen.withValues(alpha: 0.45) : AppColors.primary.withValues(alpha: 0.35))
              : AppColors.border,
          width: isRecording ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isRecording
                ? (isMinReached ? AppColors.supportingGreen.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.08))
                : AppColors.text.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Type + Status Pill on Left, Digital Time & Range on Right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: statusColor, size: 11),
                          const SizedBox(width: 3),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        typeLabel,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.text,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),

              // Time indicator: 00:18 / 00:20
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(clampedElapsed),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: isMinReached ? AppColors.supportingGreen : AppColors.primary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const Text(
                      ' / ',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatTime(maxDurationSeconds),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Horizontal Progress Bar & Timeline
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progressFraction),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, currentFraction, child) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  final totalWidth = constraints.maxWidth;
                  const trackHeight = 8.0;
                  const thumbRadius = 6.0;
                  final thumbX = (currentFraction * totalWidth).clamp(
                    thumbRadius,
                    totalWidth - thumbRadius,
                  );
                  final minMarkerX = (minFraction * totalWidth).clamp(0.0, totalWidth);

                  return Column(
                    children: [
                      // Track with Minimum Marker & Thumb
                      SizedBox(
                        height: 22,
                        child: Stack(
                          alignment: Alignment.centerLeft,
                          children: [
                            // Base inactive track
                            Container(
                              width: totalWidth,
                              height: trackHeight,
                              decoration: BoxDecoration(
                                color: AppColors.border.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(trackHeight / 2),
                              ),
                            ),

                            // Filled LungSense Green gradient track
                            Container(
                              width: totalWidth * currentFraction,
                              height: trackHeight,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: isMinReached
                                      ? [AppColors.primary, AppColors.supportingGreen]
                                      : [AppColors.primary, AppColors.primary],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(trackHeight / 2),
                                boxShadow: currentFraction > 0.02
                                    ? [
                                        BoxShadow(
                                          color: (isMinReached ? AppColors.supportingGreen : AppColors.primary).withValues(alpha: 0.35),
                                          blurRadius: 6,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                            ),

                            // Tick notches directly on the track
                            ...ticks.map((tickVal) {
                              final tickFrac = tickVal / maxDurationSeconds;
                              final tickX = tickFrac * totalWidth;
                              final isPassed = clampedElapsed >= tickVal;

                              return Positioned(
                                left: (tickX - 1.0).clamp(0.0, totalWidth - 2.0),
                                top: (22 - trackHeight) / 2 - 2,
                                child: Container(
                                  width: 2.0,
                                  height: trackHeight + 4,
                                  decoration: BoxDecoration(
                                    color: isPassed
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : AppColors.surface,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              );
                            }),

                            // Minimum threshold indicator line
                            Positioned(
                              left: (minMarkerX - 1.5).clamp(0.0, totalWidth - 3.0),
                              top: 0,
                              child: Container(
                                width: 3.0,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: isMinReached ? AppColors.supportingGreen : AppColors.warning,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isMinReached ? AppColors.supportingGreen : AppColors.warning).withValues(alpha: 0.5),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Active Thumb / Indicator Dot
                            if (currentFraction > 0.0)
                              Positioned(
                                left: thumbX - thumbRadius,
                                child: Container(
                                  width: thumbRadius * 2,
                                  height: thumbRadius * 2,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isMinReached ? AppColors.supportingGreen : AppColors.primary,
                                      width: 2.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: (isMinReached ? AppColors.supportingGreen : AppColors.primary).withValues(alpha: 0.4),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Tick labels row positioned below the track
                      SizedBox(
                        height: 18,
                        child: Stack(
                          children: [
                            ...ticks.map((tickVal) {
                              final tickFrac = tickVal / maxDurationSeconds;
                              final isPassed = clampedElapsed >= tickVal;
                              const labelWidth = 32.0;
                              double labelLeft = (tickFrac * totalWidth) - (labelWidth / 2);
                              if (labelLeft < 0) labelLeft = 0;
                              if (labelLeft + labelWidth > totalWidth) {
                                labelLeft = totalWidth - labelWidth;
                              }

                              return Positioned(
                                left: labelLeft,
                                width: labelWidth,
                                child: Text(
                                  '${tickVal}s',
                                  textAlign: tickVal == 0
                                      ? TextAlign.left
                                      : (tickVal == maxDurationSeconds
                                          ? TextAlign.right
                                          : TextAlign.center),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isPassed ? FontWeight.w800 : FontWeight.w500,
                                    color: isPassed
                                        ? AppColors.primary
                                        : AppColors.textSecondary.withValues(alpha: 0.65),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),

          // Subtext hint with Minimum and Maximum status
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: (isRecording || isPaused)
                    ? Text(
                        !isMinReached
                            ? '${minDurationSeconds - clampedElapsed}s to min (${minDurationSeconds}s)'
                            : '✓ Min reached (${maxDurationSeconds - clampedElapsed}s to max)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPaused
                              ? AppColors.warning
                              : (!isMinReached ? AppColors.primary : AppColors.supportingGreen),
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        'Min: ${minDurationSeconds}s • Max: ${maxDurationSeconds}s',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
              const SizedBox(width: 6),
              Text(
                'Auto-stops at ${maxDurationSeconds}s',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
