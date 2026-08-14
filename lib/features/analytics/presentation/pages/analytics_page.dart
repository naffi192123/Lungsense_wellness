import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';

/// Full-featured Analytics screen driven entirely from backend APIs.
/// Sources:
///   • GET /score/history  → summary cards, trend chart
///   • GET /score/baseline → baseline status card
///   • GET /score/bands    → distribution section categories
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  @override
  void initState() {
    super.initState();
    // Trigger initial data load when the page is first built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final bloc = context.read<AnalyticsBloc>();
        if (bloc.state.status == AnalyticsStatus.initial) {
          bloc.add(const AnalyticsLoadEvent());
        }
      }
    });
  }

  void _refresh() {
    context.read<AnalyticsBloc>().add(const AnalyticsLoadEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state),
                Expanded(child: _buildBody(context, state)),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AnalyticsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Analytics',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                'Your lung wellness insights',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
          if (state.status == AnalyticsStatus.loading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            )
          else
            GestureDetector(
              onTap: _refresh,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Body routing by state
  // ─────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, AnalyticsState state) {
    switch (state.status) {
      case AnalyticsStatus.initial:
        return _buildLoadingState();
      case AnalyticsStatus.loading:
        // If we already have data, show it with the spinner in the header
        if (state.scoreHistory.isNotEmpty) {
          return _buildContent(context, state);
        }
        return _buildLoadingState();
      case AnalyticsStatus.error:
        // If we have cached data, show it with an error banner
        if (state.scoreHistory.isNotEmpty) {
          return _buildContent(context, state, errorBanner: state.errorMessage);
        }
        return _buildErrorState(context, state.errorMessage);
      case AnalyticsStatus.success:
        if (state.scoreHistory.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildContent(context, state);
    }
  }

  // ─────────────────────────────────────────────────────────
  // Loading skeleton
  // ─────────────────────────────────────────────────────────

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        children: [
          _shimmerBlock(height: 90),
          const SizedBox(height: 16),
          _shimmerBlock(height: 80),
          const SizedBox(height: 16),
          _shimmerBlock(height: 220),
          const SizedBox(height: 16),
          _shimmerBlock(height: 160),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _shimmerBlock({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _ShimmerAnimation(child: Container(color: Colors.white)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Error state
  // ─────────────────────────────────────────────────────────

  Widget _buildErrorState(BuildContext context, String? message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text(
              'Unable to load analytics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Empty state
  // ─────────────────────────────────────────────────────────

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
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics_outlined, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text(
              'No wellness data yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.text),
            ),
            const SizedBox(height: 8),
            Text(
              'Your Lung Wellness Score will appear here after you complete your first wellness session.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Main scrollable content
  // ─────────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    AnalyticsState state, {
    String? errorBanner,
  }) {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner (when data is stale and a refresh failed)
            if (errorBanner != null) ...[
              _buildErrorBanner(errorBanner),
              const SizedBox(height: 16),
            ],

            // 1. Summary Cards
            _buildSummaryCards(state.scoreHistory),
            const SizedBox(height: 20),

            // 2. Baseline Status
            if (state.baselineStatus != null) ...[
              _buildBaselineCard(state.baselineStatus!),
              const SizedBox(height: 20),
            ],

            // 3. Trend Chart
            _buildTrendChart(context, state.scoreHistory),
            const SizedBox(height: 20),

            // 4. Distribution
            _buildDistributionSection(state.scoreHistory, state.bandList),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Showing cached data. Refresh failed.',
              style: const TextStyle(fontSize: 12, color: AppColors.error),
            ),
          ),
          GestureDetector(
            onTap: _refresh,
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 1. Summary Cards — Latest / Average / Peak
  // ─────────────────────────────────────────────────────────

  Widget _buildSummaryCards(List<ScoreHistoryEntity> history) {
    // Use lungWellnessScore (precise double) preferring over the legacy int score
    final validScores = history
        .map((e) => e.lungWellnessScore ?? e.score.toDouble())
        .where((s) => s > 0)
        .toList();

    final String latest;
    final String average;
    final String peak;

    if (validScores.isEmpty) {
      latest = '—';
      average = '—';
      peak = '—';
    } else {
      // History is newest-first; chronological first = history.last
      latest = validScores.first.round().toString();
      final avg = validScores.reduce((a, b) => a + b) / validScores.length;
      average = avg.round().toString();
      final hi = validScores.reduce((a, b) => a > b ? a : b);
      peak = hi.round().toString();
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'LATEST',
            value: latest,
            subtitle: 'Lung Wellness Score',
            color: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.07),
            icon: Icons.speed_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            title: 'AVERAGE',
            value: average,
            subtitle: 'Across all sessions',
            color: AppColors.secondary,
            bgColor: AppColors.secondary.withValues(alpha: 0.07),
            icon: Icons.show_chart_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            title: 'PEAK',
            value: peak,
            subtitle: 'Personal best',
            color: const Color(0xFFE07B39),
            bgColor: const Color(0xFFE07B39).withValues(alpha: 0.07),
            icon: Icons.emoji_events_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(6)),
                child: Icon(icon, color: color, size: 12),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 2. Baseline Status Card
  // ─────────────────────────────────────────────────────────

  Widget _buildBaselineCard(Map<String, dynamic> baseline) {
    final rawStatus = (baseline['status']?.toString() ?? 'initializing').toLowerCase();
    final message = baseline['message']?.toString() ?? 'Complete sessions to activate trend scoring.';
    final sessionCount = baseline['session_count'] as int?;
    final requiredSessions = baseline['required_sessions'] as int?;

    // Color-code by status
    final Color cardColor;
    final Color borderColor;
    final Color iconColor;
    final IconData statusIcon;
    final String statusLabel;

    switch (rawStatus) {
      case 'active':
        cardColor = AppColors.primary.withValues(alpha: 0.07);
        borderColor = AppColors.primary.withValues(alpha: 0.25);
        iconColor = AppColors.primary;
        statusIcon = Icons.verified_rounded;
        statusLabel = 'ACTIVE';
        break;
      case 'progressing':
        cardColor = AppColors.secondary.withValues(alpha: 0.07);
        borderColor = AppColors.secondary.withValues(alpha: 0.25);
        iconColor = AppColors.secondary;
        statusIcon = Icons.trending_up_rounded;
        statusLabel = 'IN PROGRESS';
        break;
      default: // initializing
        cardColor = AppColors.info.withValues(alpha: 0.07);
        borderColor = AppColors.info.withValues(alpha: 0.25);
        iconColor = AppColors.info;
        statusIcon = Icons.hourglass_top_rounded;
        statusLabel = 'INITIALIZING';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: iconColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'BASELINE STATUS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: iconColor,
                  letterSpacing: 0.6,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: iconColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
          ),
          if (sessionCount != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.bar_chart_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '$sessionCount session${sessionCount == 1 ? '' : 's'} completed'
                  '${requiredSessions != null ? ' of $requiredSessions required' : ''}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (requiredSessions != null && sessionCount < requiredSessions) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: sessionCount / requiredSessions,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  minHeight: 5,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 3. Lung Wellness Score Trend Chart
  // ─────────────────────────────────────────────────────────

  Widget _buildTrendChart(BuildContext context, List<ScoreHistoryEntity> history) {
    // Plot chronologically (oldest → newest)
    final chronological = history.reversed
        .where((e) => (e.lungWellnessScore ?? e.score.toDouble()) > 0)
        .toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.03),
            blurRadius: 8,
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
              const Text(
                'Lung Wellness Trend',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Scale: 0 – 100',
                  style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${chronological.length} session${chronological.length == 1 ? '' : 's'} recorded',
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          if (chronological.isEmpty)
            _buildChartEmpty()
          else if (chronological.length == 1)
            _buildSinglePointChart(chronological.first)
          else
            SizedBox(
              height: 180,
              child: chronological.length > 7
                  ? SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: chronological
                            .map((item) => _buildBarItem(item))
                            .toList(),
                      ),
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: chronological
                          .map((item) => Expanded(child: _buildBarItem(item)))
                          .toList(),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildChartEmpty() {
    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart_rounded, size: 32, color: AppColors.border),
          const SizedBox(height: 8),
          const Text(
            'No scored sessions yet',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildSinglePointChart(ScoreHistoryEntity item) {
    final score = (item.lungWellnessScore ?? item.score.toDouble()).round();
    final color = _bandColor(score);

    return Container(
      height: 120,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            score.toString(),
            style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          const Text(
            'First session score',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(item.timestamp),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBarItem(ScoreHistoryEntity item) {
    final rawScore = item.lungWellnessScore ?? item.score.toDouble();
    final score = rawScore.round();
    final heightFactor = (rawScore / 100.0).clamp(0.05, 1.0);
    final color = _bandColor(score);
    final dateLabel = _formatDate(item.timestamp);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            score.toString(),
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 3),
          Container(
            width: 22,
            height: 120 * heightFactor,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [color.withValues(alpha: 0.7), color],
              ),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            dateLabel,
            style: const TextStyle(fontSize: 9, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Color _bandColor(int score) {
    if (score >= 71) return AppColors.primary;
    if (score >= 41) return AppColors.secondary;
    return AppColors.error;
  }

  String _formatDate(DateTime dt) {
    return '${dt.month}/${dt.day}';
  }

  // ─────────────────────────────────────────────────────────
  // 4. Score Category Distribution — thresholds from /score/bands
  // ─────────────────────────────────────────────────────────

  Widget _buildDistributionSection(
    List<ScoreHistoryEntity> history,
    List<Map<String, dynamic>> bands,
  ) {
    // Exclude entries with no valid score
    final scored = history.where(
      (e) => (e.lungWellnessScore ?? e.score.toDouble()) > 0,
    ).toList();

    // Use fallback bands if API returned empty
    final effectiveBands = bands.isNotEmpty
        ? bands
        : [
            {'label': 'Needs Attention', 'min': 0, 'max': 40},
            {'label': 'Room to Improve', 'min': 41, 'max': 70},
            {'label': 'Doing Well', 'min': 71, 'max': 100},
          ];

    // Assign band colors in the same order as typical (low → moderate → good)
    final bandColors = [AppColors.error, AppColors.secondary, AppColors.primary];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Score Distribution',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
              ),
              const Spacer(),
              Text(
                '${scored.length} session${scored.length == 1 ? '' : 's'}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Based on backend score bands',
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 18),

          if (scored.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'No scored sessions yet',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ),
            )
          else
            ...List.generate(effectiveBands.length, (i) {
              final band = effectiveBands[i];
              final label = band['label']?.toString() ?? 'Unknown';
              final min = (band['min'] as num?)?.toDouble() ?? 0;
              final max = (band['max'] as num?)?.toDouble() ?? 100;
              final color = i < bandColors.length ? bandColors[i] : AppColors.primary;

              final count = scored.where((e) {
                final s = e.lungWellnessScore ?? e.score.toDouble();
                return s >= min && s <= max;
              }).length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _buildDistributionRow(
                  label: label,
                  rangeLabel: '${min.toInt()} – ${max.toInt()}',
                  count: count,
                  total: scored.length,
                  color: color,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDistributionRow({
    required String label,
    required String rangeLabel,
    required int count,
    required int total,
    required Color color,
  }) {
    final percentage = total > 0 ? count / total : 0.0;

    return Column(
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
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    rangeLabel,
                    style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(percentage * 100).round()}%',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '$count session${count == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 7,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────
// Shimmer Animation widget
// ─────────────────────────────────────────────────────────

class _ShimmerAnimation extends StatefulWidget {
  final Widget child;
  const _ShimmerAnimation({required this.child});

  @override
  State<_ShimmerAnimation> createState() => _ShimmerAnimationState();
}

class _ShimmerAnimationState extends State<_ShimmerAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.border.withValues(alpha: 0.3),
                AppColors.border.withValues(alpha: 0.6),
                AppColors.border.withValues(alpha: 0.3),
              ],
              stops: [
                (_animation.value - 1).clamp(0.0, 1.0),
                (_animation.value).clamp(0.0, 1.0),
                (_animation.value + 1).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}
