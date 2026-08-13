import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/bloc/wellness_bloc.dart';
import '../../../dashboard/presentation/bloc/wellness_state.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// Screen presenting real-time wellness score trends, baseline progress, and acoustic statistics.
class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WellnessBloc, WellnessState>(
      builder: (context, state) {
        final scores = state.scoreHistory;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Analytics',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                      ),
                      const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 24),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: scores.isEmpty
                      ? _buildEmptyState(context)
                      : SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Summary Stats
                              _buildSummaryCards(scores),
                              const SizedBox(height: 24),

                              // Baseline Lifecycle Status
                              if (state.baselineStatus != null) ...[
                                _buildBaselineCard(state.baselineStatus!),
                                const SizedBox(height: 24),
                              ],

                              // Real Score Trend Chart
                              _buildChartSection(context, scores),
                              const SizedBox(height: 24),

                              // Score Distribution
                              _buildDistributionSection(scores),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        );
      },
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
                Icons.analytics_outlined,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No wellness data yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Lung Wellness Score will appear here after you start completing your wellness activities.',
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

  Widget _buildSummaryCards(List<ScoreHistoryEntity> scores) {
    final latest = scores.first.score;
    final total = scores.map((e) => e.score).reduce((a, b) => a + b);
    final average = (total / scores.length).round();
    final highest = scores.map((e) => e.score).reduce((a, b) => a > b ? a : b);

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'LATEST',
            value: '$latest',
            color: AppColors.primary,
            icon: Icons.speed_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            title: 'AVERAGE',
            value: '$average',
            color: AppColors.supportingGreen,
            icon: Icons.trending_up_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            title: 'PEAK',
            value: '$highest',
            color: AppColors.secondary,
            icon: Icons.emoji_events_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: color, size: 15),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBaselineCard(Map<String, dynamic> baseline) {
    final status = baseline['status']?.toString().toUpperCase() ?? 'INITIALIZING';
    final message = baseline['message']?.toString() ?? 'Complete sessions to activate trend scoring.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BASELINE STATUS: $status',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primary),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(BuildContext context, List<ScoreHistoryEntity> scores) {
    // Chronological order for plotting
    final chronological = List<ScoreHistoryEntity>.from(scores.reversed);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lung Wellness Score Trend',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
              ),
              Text(
                'Scale: 0 - 100',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Custom Bar/Line Trend visualization with horizontal scroll safety
          SizedBox(
            height: 180,
            child: chronological.length > 7
                ? SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: chronological.map((item) => _buildBarItem(item)).toList(),
                    ),
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: chronological.map((item) => _buildBarItem(item)).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarItem(ScoreHistoryEntity item) {
    final heightFactor = (item.score / 100.0).clamp(0.05, 1.0);
    final dateLabel = "${item.timestamp.month}/${item.timestamp.day}";

    Color barColor = AppColors.supportingGreen;
    if (item.score < 60) {
      barColor = AppColors.error;
    } else if (item.score < 80) {
      barColor = AppColors.secondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '${item.score}',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: barColor),
          ),
          const SizedBox(height: 4),
          Container(
            width: 24,
            height: 120 * heightFactor,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            dateLabel,
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionSection(List<ScoreHistoryEntity> scores) {
    int goodCount = scores.where((s) => s.score >= 80).length;
    int fairCount = scores.where((s) => s.score >= 60 && s.score < 80).length;
    int attentionCount = scores.where((s) => s.score < 60).length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Score Category Distribution',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
          ),
          const SizedBox(height: 16),
          _buildDistributionRow('Optimal (80 - 100)', goodCount, scores.length, AppColors.supportingGreen),
          const SizedBox(height: 10),
          _buildDistributionRow('Fair (60 - 79)', fairCount, scores.length, AppColors.secondary),
          const SizedBox(height: 10),
          _buildDistributionRow('Needs Attention (< 60)', attentionCount, scores.length, AppColors.error),
        ],
      ),
    );
  }

  Widget _buildDistributionRow(String label, int count, int total, Color color) {
    final percentage = total > 0 ? (count / total) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.text)),
            Text('$count session${count == 1 ? '' : 's'} (${(percentage * 100).round()}%)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
