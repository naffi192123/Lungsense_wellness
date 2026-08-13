import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_state.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// Screen listing real historical symptom check-ins, audio logs, and wellness scores.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WellnessBloc, WellnessState>(
      builder: (context, state) {
        // Aggregate all real history events
        final List<_HistoryItemWrapper> allHistory = [];

        for (var audio in state.audioAnalyses) {
          final isComplete = audio.status.toLowerCase() == 'complete';
          final isFailed = audio.status.toLowerCase() == 'failed';
          final statusLabel = isComplete ? 'Completed' : (isFailed ? 'Failed' : 'Processing...');

          allHistory.add(_HistoryItemWrapper(
            type: 'audio',
            id: audio.id,
            title: audio.title.isNotEmpty ? audio.title : '${audio.type} Recording',
            subtitle: '${audio.duration}s session • $statusLabel',
            timestamp: audio.timestamp,
            score: isComplete ? audio.lungsScore : null,
            data: audio,
          ));
        }

        for (var log in state.dailyLogs) {
          final cough = log.coughSeverity.toInt();
          final breath = log.breathlessness.toInt();
          allHistory.add(_HistoryItemWrapper(
            type: 'checkin',
            id: log.id,
            title: 'Symptom Check-in',
            subtitle: 'Cough: $cough/3 • Breathlessness: $breath/3',
            timestamp: log.timestamp,
            score: null,
            data: log,
          ));
        }

        for (var score in state.scoreHistory) {
          allHistory.add(_HistoryItemWrapper(
            type: 'score',
            id: score.id,
            title: 'Lung Wellness Score',
            subtitle: 'Health Band: ${score.band.toUpperCase()}',
            timestamp: score.timestamp,
            score: score.score,
            data: score,
          ));
        }

        // Sort newest first
        allHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header details
                _buildHeader(context),

                // Content Area
                Expanded(
                  child: allHistory.isEmpty
                      ? _buildEmptyState(context)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          itemCount: allHistory.length,
                          itemBuilder: (context, index) {
                            return _buildTimelineItem(context, allHistory[index]);
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
          ),
          const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No history yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your recordings, symptom logs, and wellness activities will appear here once you start using the app.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, _HistoryItemWrapper item) {
    IconData icon;
    Color iconColor;

    switch (item.type) {
      case 'audio':
        icon = Icons.mic_none_rounded;
        iconColor = AppColors.primary;
        break;
      case 'checkin':
        icon = Icons.fact_check_outlined;
        iconColor = AppColors.supportingGreen;
        break;
      case 'score':
        icon = Icons.insights_rounded;
        iconColor = AppColors.secondary;
        break;
      default:
        icon = Icons.history_rounded;
        iconColor = AppColors.textSecondary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          item.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              item.subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(item.timestamp),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (item.score != null)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.supportingGreen.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${item.score}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.supportingGreen),
                ),
              ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
          ],
        ),
        onTap: () {
          context.push('/history-details', extra: {
            'logType': item.type,
            'itemData': item.data,
          });
        },
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time).inDays;

    String dateStr = '';
    if (difference == 0) {
      dateStr = 'Today';
    } else if (difference == 1) {
      dateStr = 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateStr = "${months[time.month - 1]} ${time.day}";
    }

    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minuteStr = time.minute.toString().padLeft(2, '0');

    return "$dateStr, $hour:$minuteStr $period";
  }
}

class _HistoryItemWrapper {
  final String type;
  final String id;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final int? score;
  final dynamic data;

  _HistoryItemWrapper({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.score,
    required this.data,
  });
}
