import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_state.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// Screen listing historical symptom and audio logs.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WellnessBloc, WellnessState>(
      builder: (context, state) {
        final list = state.audioAnalyses;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header details
                _buildHeader(context),

                // Average Score Section
                _buildAverageScoreCard(context, list),

                // Timeline List
                Expanded(
                  child: list.isEmpty
                      ? const Center(child: Text('No historical logs found.'))
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            return _buildTimelineItem(context, list[index], index == list.length - 1);
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
      padding: const EdgeInsets.all(24.0),
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

  Widget _buildAverageScoreCard(BuildContext context, List<AudioAnalysisEntity> list) {
    int averageScore = 92;
    if (list.isNotEmpty) {
      final total = list.map((e) => e.lungsScore).reduce((a, b) => a + b);
      averageScore = (total / list.length).round();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Container(
        padding: const EdgeInsets.all(20.0),
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
                const Text(
                  'AVERAGE SCORE',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$averageScore',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.supportingGreen),
                    ),
                    const Text(
                      ' /100',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
              decoration: BoxDecoration(
                color: AppColors.supportingGreen.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: const Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: AppColors.supportingGreen, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '4%',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.supportingGreen, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, AudioAnalysisEntity item, bool isLast) {
    // Determine status color based on lungs score
    final isGood = item.lungsScore >= 90;
    final dotColor = isGood ? AppColors.supportingGreen : AppColors.secondary;
    final checkIcon = isGood ? Icons.check_circle : Icons.info;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator line
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4.0),
                child: Icon(checkIcon, color: dotColor, size: 22),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2.0,
                    color: AppColors.border,
                    margin: const EdgeInsets.symmetric(vertical: 4.0),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),

          // Log card details
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16.0),
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
                      Text(
                        _formatTimestamp(item.timestamp),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        '${item.lungsScore}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: dotColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.text, fontSize: 16),
                      ),
                      const Text(
                        'Score',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Tag Chips
                  Wrap(
                    spacing: 6.0,
                    runSpacing: 6.0,
                    children: item.tags.map((tag) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                        decoration: BoxDecoration(
                          color: dotColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: dotColor,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Audio metadata details bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.mic_none_outlined, color: dotColor, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            '${item.duration}s recording',
                            style: const TextStyle(fontSize: 13, color: AppColors.text),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          // Navigate to details visualization
                          context.go('/audio-analysis');
                        },
                        child: Text(
                          'DETAILS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: dotColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
      // e.g. Oct 22
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateStr = "${months[time.month - 1]} ${time.day}";
    }

    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minuteStr = time.minute.toString().padLeft(2, '0');
    
    return "$dateStr, $hour:$minuteStr $period";
  }
}
