import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';

/// Full-featured Analytics screen driven entirely from backend APIs.
/// Screen structure:
///   1. Header with "Analytics", subtitle, "Last 30 Days" / "Last 7 Days" filter (30d default), and refresh.
///   2. Three summary cards in one row: LATEST SCORE, AVERAGE SCORE, PEAK SCORE.
///   3. "Lung Wellness Trend" card: X sessions recorded, fixed 0-100 y-axis, individual score bars
///      with S1..Sn labels and dates, score values above bars, dynamic linear-regression trendline,
///      and a horizontal dashed Personal Baseline line when baseline is active.
///   4. "PERSONAL BASELINE" panel: Building (<7 sessions) vs Active (>=7 sessions with vs Baseline).
///   5. "Score Distribution" section based on backend score bands.
///   6. "Key Insights" section with 3 dynamic cards: Trend Insight, Baseline Insight, Performance Insight.
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _selectedFilterDays = 30; // 30 or 7

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnalyticsBloc>().add(const AnalyticsLoadEvent());
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
  // Header: Title, Subtitle, Filter (30d/7d), Refresh Button
  // ─────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AnalyticsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Analytics',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.text,
                        fontSize: 24,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your lung wellness insights',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                ),
              ],
            ),
          ),
          // Filter Dropdown / Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedFilterDays,
                isDense: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 30,
                    child: Text(
                      'Last 30 Days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  DropdownMenuItem(
                    value: 7,
                    child: Text(
                      'Last 7 Days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedFilterDays = val;
                    });
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Refresh Button / Loading indicator
          if (state.status == AnalyticsStatus.loading)
            const SizedBox(
              width: 36,
              height: 36,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            )
          else
            IconButton(
              onPressed: _refresh,
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.primary,
                size: 22,
              ),
              tooltip: 'Refresh analytics',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: EdgeInsets.zero,
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Filter Logic
  // ─────────────────────────────────────────────────────────

  List<ScoreHistoryEntity> _filterHistory(List<ScoreHistoryEntity> history) {
    if (history.isEmpty) return [];

    final now = DateTime.now();
    final cutoff = now.subtract(Duration(days: _selectedFilterDays));
    final filtered = history.where((e) => e.timestamp.isAfter(cutoff)).toList();

    // If historical/demo data has timestamps older than cutoff, filter relative to newest item
    if (filtered.isEmpty && history.isNotEmpty) {
      final newestDate = history.first.timestamp;
      final fallbackCutoff = newestDate.subtract(Duration(days: _selectedFilterDays));
      return history
          .where((e) =>
              e.timestamp.isAfter(fallbackCutoff) ||
              e.timestamp.isAtSameMomentAs(fallbackCutoff))
          .toList();
    }
    return filtered;
  }

  // ─────────────────────────────────────────────────────────
  // Body Routing
  // ─────────────────────────────────────────────────────────

  Widget _buildBody(BuildContext context, AnalyticsState state) {
    switch (state.status) {
      case AnalyticsStatus.initial:
        return _buildLoadingState();
      case AnalyticsStatus.loading:
        if (state.scoreHistory.isNotEmpty) {
          return _buildContent(context, state);
        }
        return _buildLoadingState();
      case AnalyticsStatus.error:
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

  Widget _buildLoadingState() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
      child: Column(
        children: [
          _shimmerBlock(height: 90),
          const SizedBox(height: 16),
          _shimmerBlock(height: 240),
          const SizedBox(height: 16),
          _shimmerBlock(height: 110),
          const SizedBox(height: 16),
          _shimmerBlock(height: 180),
          const SizedBox(height: 16),
          _shimmerBlock(height: 200),
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
  // Main Scrollable Content
  // ─────────────────────────────────────────────────────────

  Widget _buildContent(
    BuildContext context,
    AnalyticsState state, {
    String? errorBanner,
  }) {
    final filteredHistory = _filterHistory(state.scoreHistory);

    // Valid completed sessions have score > 0
    final validHistory = filteredHistory
        .where((e) => (e.lungWellnessScore ?? e.score.toDouble()) > 0)
        .toList();

    // Chronological order (oldest to newest: S1, S2...)
    final chronological = validHistory.reversed.toList();

    // All valid sessions in whole history (for baseline 7-session rule)
    final totalValidSessions = state.scoreHistory
        .where((e) => (e.lungWellnessScore ?? e.score.toDouble()) > 0)
        .length;

    final backendSessionCount = state.baselineStatus?['session_count'] as int?;
    final effectiveSessionCount = backendSessionCount ?? totalValidSessions;
    final isBaselineActive = effectiveSessionCount >= 7;

    // Baseline value from backend
    final baselineValue = isBaselineActive ? _extractBaselineValue(state.baselineStatus) : null;

    // Regression calculation for trendline & trend insight
    final validScoresChronological = chronological
        .map((e) => (e.lungWellnessScore ?? e.score.toDouble()))
        .toList();
    final regression = _calculateRegression(validScoresChronological);

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorBanner != null) ...[
              _buildErrorBanner(errorBanner),
              const SizedBox(height: 16),
            ],

            // 1. Three Summary Cards in one row
            _buildSummaryCards(validHistory),
            const SizedBox(height: 18),

            // 2. Lung Wellness Trend Chart
            _buildTrendChartCard(
              context: context,
              chronologicalSessions: chronological,
              regression: regression,
              baselineValue: baselineValue,
              isBaselineActive: isBaselineActive,
            ),
            const SizedBox(height: 18),

            // 3. PERSONAL BASELINE Panel (immediately below chart)
            _buildPersonalBaselinePanel(
              state: state,
              sessionCount: effectiveSessionCount,
              isBaselineActive: isBaselineActive,
              baselineValue: baselineValue,
              latestScore: validHistory.isNotEmpty
                  ? (validHistory.first.lungWellnessScore ?? validHistory.first.score.toDouble())
                  : null,
            ),
            const SizedBox(height: 18),

            // 4. Score Distribution Section
            _buildDistributionSection(validHistory, state.bandList),
            const SizedBox(height: 18),

            // 5. Key Insights Section (3 dynamic cards)
            _buildKeyInsightsSection(
              chronologicalSessions: chronological,
              regression: regression,
              isBaselineActive: isBaselineActive,
              baselineValue: baselineValue,
              validScoresChronological: validScoresChronological,
            ),
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
          const Expanded(
            child: Text(
              'Showing cached data. Refresh failed.',
              style: TextStyle(fontSize: 12, color: AppColors.error),
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
  // 1. Three Summary Cards in One Row: LATEST, AVERAGE, PEAK
  // ─────────────────────────────────────────────────────────

  Widget _buildSummaryCards(List<ScoreHistoryEntity> validHistory) {
    final validScores = validHistory
        .map((e) => e.lungWellnessScore ?? e.score.toDouble())
        .toList();

    final String latest;
    final String average;
    final String peak;

    if (validScores.isEmpty) {
      latest = '--';
      average = '--';
      peak = '--';
    } else {
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
            title: 'LATEST SCORE',
            value: latest,
            subtitle: 'Recent session',
            color: AppColors.primary,
            bgColor: AppColors.primary.withValues(alpha: 0.08),
            icon: Icons.speed_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            title: 'AVERAGE SCORE',
            value: average,
            subtitle: 'All sessions',
            color: AppColors.secondary,
            bgColor: AppColors.secondary.withValues(alpha: 0.08),
            icon: Icons.show_chart_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            title: 'PEAK SCORE',
            value: peak,
            subtitle: 'Personal best',
            color: const Color(0xFFE07B39),
            bgColor: const Color(0xFFE07B39).withValues(alpha: 0.08),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 2. "Lung Wellness Trend" Card
  // ─────────────────────────────────────────────────────────

  Widget _buildTrendChartCard({
    required BuildContext context,
    required List<ScoreHistoryEntity> chronologicalSessions,
    required _LinearRegressionResult regression,
    required double? baselineValue,
    required bool isBaselineActive,
  }) {
    final count = chronologicalSessions.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.02),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.text,
                ),
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
          const SizedBox(height: 4),
          Text(
            '$count session${count == 1 ? '' : 's'} recorded',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
          if (isBaselineActive && baselineValue != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Container(
                  width: 14,
                  height: 2,
                  color: AppColors.secondary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Personal baseline ${baselineValue.toStringAsFixed(1)}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          if (count == 0)
            _buildChartEmpty()
          else
            _buildFullTrendChart(
              chronologicalSessions: chronologicalSessions,
              regression: regression,
              baselineValue: baselineValue,
              isBaselineActive: isBaselineActive,
            ),
        ],
      ),
    );
  }

  Widget _buildChartEmpty() {
    return Container(
      height: 140,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bar_chart_rounded, size: 36, color: AppColors.border),
          SizedBox(height: 8),
          Text(
            'No scored sessions in this period',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildFullTrendChart({
    required List<ScoreHistoryEntity> chronologicalSessions,
    required _LinearRegressionResult regression,
    required double? baselineValue,
    required bool isBaselineActive,
  }) {
    const double chartHeight = 180.0;
    const double yAxisWidth = 32.0;
    const double slotWidth = 52.0;

    final count = chronologicalSessions.length;
    final totalChartWidth = count > 6 ? count * slotWidth : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pinned Y-Axis (0 to 100)
        SizedBox(
          width: yAxisWidth,
          height: chartHeight,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('100', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
              Text('75', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
              Text('50', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
              Text('25', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
              Text('0', style: TextStyle(fontSize: 9.5, color: AppColors.textSecondary)),
              SizedBox(height: 38), // aligns with bottom labels (S1 + date)
            ],
          ),
        ),

        // Scrollable or Stretched Chart Content
        Expanded(
          child: count > 6
              ? SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SizedBox(
                    width: totalChartWidth,
                    height: chartHeight + 42,
                    child: _buildChartCanvas(
                      chronologicalSessions: chronologicalSessions,
                      regression: regression,
                      baselineValue: baselineValue,
                      isBaselineActive: isBaselineActive,
                      slotWidth: slotWidth,
                    ),
                  ),
                )
              : SizedBox(
                  height: chartHeight + 42,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final effectiveSlotWidth = constraints.maxWidth / count;
                      return _buildChartCanvas(
                        chronologicalSessions: chronologicalSessions,
                        regression: regression,
                        baselineValue: baselineValue,
                        isBaselineActive: isBaselineActive,
                        slotWidth: effectiveSlotWidth,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildChartCanvas({
    required List<ScoreHistoryEntity> chronologicalSessions,
    required _LinearRegressionResult regression,
    required double? baselineValue,
    required bool isBaselineActive,
    required double slotWidth,
  }) {
    const double chartPlotHeight = 180.0;
    final count = chronologicalSessions.length;
    final contentWidth = count * slotWidth;

    return Stack(
      children: [
        // Custom Painter for horizontal gridlines, baseline dashed line, and trendline
        Positioned.fill(
          child: CustomPaint(
            size: Size(contentWidth, chartPlotHeight),
            painter: _TrendChartOverlayPainter(
              sessionCount: count,
              slotWidth: slotWidth,
              chartHeight: chartPlotHeight,
              regression: regression,
              baselineValue: isBaselineActive ? baselineValue : null,
            ),
          ),
        ),

        // Bar items with scores above and labels (S1..Sn, date) below
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(count, (index) {
            final session = chronologicalSessions[index];
            final rawScore = (session.lungWellnessScore ?? session.score.toDouble()).clamp(0.0, 100.0);
            final score = rawScore.round();
            final sessionLabel = 'S${index + 1}';
            final dateLabel = '${session.timestamp.month}/${session.timestamp.day}';
            final barColor = _bandColor(score);
            final barHeight = (rawScore / 100.0) * (chartPlotHeight - 28.0);

            return SizedBox(
              width: slotWidth,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    score.toString(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: barColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 20,
                    height: barHeight.clamp(4.0, chartPlotHeight - 28.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          barColor.withValues(alpha: 0.8),
                          barColor,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sessionLabel,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: const TextStyle(
                      fontSize: 8.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // 3. PERSONAL BASELINE Panel (immediately below chart)
  // ─────────────────────────────────────────────────────────

  Widget _buildPersonalBaselinePanel({
    required AnalyticsState state,
    required int sessionCount,
    required bool isBaselineActive,
    required double? baselineValue,
    required double? latestScore,
  }) {
    if (!isBaselineActive) {
      // BUILDING State: < 7 sessions
      final progress = (sessionCount / 7.0).clamp(0.0, 1.0);

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withValues(alpha: 0.02),
              blurRadius: 6,
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
                Row(
                  children: const [
                    Icon(Icons.hourglass_top_rounded, color: AppColors.secondary, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'PERSONAL BASELINE',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'BUILDING',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$sessionCount / 7 sessions',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.secondary),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Complete 7 sessions to establish your personal baseline.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    // ACTIVE State: >= 7 sessions
    final baseline = baselineValue ?? 0.0;
    final latest = latestScore ?? baseline;
    final diff = latest - baseline;
    final isHigher = diff >= 0;
    final diffStr = isHigher ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1);
    final diffColor = isHigher ? AppColors.primary : AppColors.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
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
              Row(
                children: const [
                  Icon(Icons.verified_rounded, color: AppColors.primary, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'PERSONAL BASELINE',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    baseline.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Baseline Score',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Container(
                height: 36,
                width: 1,
                color: AppColors.border,
              ),
              const SizedBox(width: 24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isHigher ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                        size: 16,
                        color: diffColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '$diffStr pts',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: diffColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'vs Baseline',
                    style: TextStyle(fontSize: 10, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isHigher
                ? 'Your latest score is ${diff.toStringAsFixed(1)} pts above your personal baseline.'
                : 'Your latest score is ${diff.abs().toStringAsFixed(1)} pts below your personal baseline.',
            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 4. Score Distribution Section
  // ─────────────────────────────────────────────────────────

  Widget _buildDistributionSection(
    List<ScoreHistoryEntity> scored,
    List<Map<String, dynamic>> bands,
  ) {
    final effectiveBands = bands.isNotEmpty
        ? bands
        : [
            {'label': 'Needs Attention', 'min': 0, 'max': 40},
            {'label': 'Room to Improve', 'min': 41, 'max': 70},
            {'label': 'Doing Well', 'min': 71, 'max': 100},
          ];

    final bandColors = [AppColors.error, AppColors.secondary, AppColors.primary];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.02),
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
          const SizedBox(height: 16),

          if (scored.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'No scored sessions in this period',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
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
                padding: const EdgeInsets.only(bottom: 12),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.text,
                  ),
                ),
                Text(
                  rangeLabel,
                  style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${(percentage * 100).round()}%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  '$count session${count == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondary),
                ),
              ],
            ),
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

  // ─────────────────────────────────────────────────────────
  // 5. Key Insights Section (3 dynamic cards)
  // ─────────────────────────────────────────────────────────

  Widget _buildKeyInsightsSection({
    required List<ScoreHistoryEntity> chronologicalSessions,
    required _LinearRegressionResult regression,
    required bool isBaselineActive,
    required double? baselineValue,
    required List<double> validScoresChronological,
  }) {
    final count = chronologicalSessions.length;

    // 1. Trend Insight
    final String trendTitle;
    final String trendMessage;
    final IconData trendIcon;
    final Color trendColor;

    if (count < 2) {
      trendTitle = 'Building Trend';
      trendMessage = 'Complete more sessions to establish a meaningful trend.';
      trendIcon = Icons.hourglass_top_rounded;
      trendColor = AppColors.secondary;
    } else if (regression.slope >= 0.5) {
      trendTitle = 'Trends Upward';
      trendMessage = 'Your wellness scores are trending upward over recent sessions.';
      trendIcon = Icons.trending_up_rounded;
      trendColor = AppColors.primary;
    } else if (regression.slope <= -0.5) {
      trendTitle = 'Trends Downward';
      trendMessage = 'Your wellness scores are trending downward over recent sessions.';
      trendIcon = Icons.trending_down_rounded;
      trendColor = AppColors.error;
    } else {
      trendTitle = 'Stable Trend';
      trendMessage = 'Your wellness scores have remained relatively stable across recent sessions.';
      trendIcon = Icons.trending_flat_rounded;
      trendColor = AppColors.secondary;
    }

    // 2. Baseline Insight
    final String baselineTitle;
    final String baselineMessage;
    final IconData baselineIcon;
    final Color baselineColor;

    if (!isBaselineActive || baselineValue == null) {
      baselineTitle = 'Building Baseline';
      baselineMessage = 'Complete 7 sessions to unlock your personal baseline insights.';
      baselineIcon = Icons.analytics_outlined;
      baselineColor = AppColors.secondary;
    } else {
      // Compare last 7 scores against baseline
      final last7 = validScoresChronological.length >= 7
          ? validScoresChronological.sublist(validScoresChronological.length - 7)
          : validScoresChronological;
      final aboveCount = last7.where((s) => s > baselineValue).length;
      final belowCount = last7.where((s) => s < baselineValue).length;

      if (aboveCount > belowCount) {
        baselineTitle = 'Above Baseline';
        baselineMessage = '$aboveCount of 7 recent sessions were above your personal baseline.';
        baselineIcon = Icons.arrow_upward_rounded;
        baselineColor = AppColors.primary;
      } else if (belowCount > aboveCount) {
        baselineTitle = 'Below Baseline';
        baselineMessage = '$belowCount of 7 recent sessions were below your personal baseline.';
        baselineIcon = Icons.arrow_downward_rounded;
        baselineColor = AppColors.error;
      } else {
        baselineTitle = 'Near Baseline';
        baselineMessage = 'Your recent scores are balanced around your personal baseline.';
        baselineIcon = Icons.horizontal_rule_rounded;
        baselineColor = AppColors.secondary;
      }
    }

    // 3. Personal Performance Insight
    final String performanceTitle;
    final String performanceMessage;
    final IconData performanceIcon;
    final Color performanceColor;

    if (count < 2) {
      performanceTitle = 'Performance';
      performanceMessage = 'Complete more sessions to establish your personal performance range.';
      performanceIcon = Icons.speed_rounded;
      performanceColor = AppColors.secondary;
    } else {
      final latest = validScoresChronological.last.round();
      final peak = validScoresChronological.reduce((a, b) => a > b ? a : b).round();

      if (latest >= peak) {
        performanceTitle = 'Personal Best';
        performanceMessage = 'Your latest score is your highest recorded score.';
        performanceIcon = Icons.emoji_events_rounded;
        performanceColor = const Color(0xFFE07B39);
      } else {
        performanceTitle = 'Peak Score';
        performanceMessage = 'Your highest recorded score is $peak.';
        performanceIcon = Icons.star_rounded;
        performanceColor = AppColors.primary;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Key Insights',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 12),
        _buildInsightCard(
          title: trendTitle,
          message: trendMessage,
          icon: trendIcon,
          color: trendColor,
        ),
        const SizedBox(height: 10),
        _buildInsightCard(
          title: baselineTitle,
          message: baselineMessage,
          icon: baselineIcon,
          color: baselineColor,
        ),
        const SizedBox(height: 10),
        _buildInsightCard(
          title: performanceTitle,
          message: performanceMessage,
          icon: performanceIcon,
          color: performanceColor,
        ),
      ],
    );
  }

  Widget _buildInsightCard({
    required String title,
    required String message,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Helper Methods
  // ─────────────────────────────────────────────────────────

  Color _bandColor(int score) {
    if (score >= 71) return AppColors.primary;
    if (score >= 41) return AppColors.secondary;
    return AppColors.error;
  }

  double? _extractBaselineValue(Map<String, dynamic>? baselineStatus) {
    if (baselineStatus == null) return null;
    final val = baselineStatus['baseline_mean'] ??
        baselineStatus['baseline_score'] ??
        baselineStatus['baseline'] ??
        baselineStatus['mean'] ??
        baselineStatus['score'];
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  _LinearRegressionResult _calculateRegression(List<double> scores) {
    final n = scores.length;
    if (n < 2) {
      final single = scores.isNotEmpty ? scores.first : 0.0;
      return _LinearRegressionResult(
        slope: 0.0,
        intercept: single,
        startY: single,
        endY: single,
      );
    }

    final meanX = (n + 1) / 2.0;
    final meanY = scores.reduce((a, b) => a + b) / n;

    double numerator = 0.0;
    double denominator = 0.0;

    for (int i = 0; i < n; i++) {
      final x = (i + 1).toDouble();
      final y = scores[i];
      final dx = x - meanX;
      numerator += dx * (y - meanY);
      denominator += dx * dx;
    }

    final slope = denominator != 0 ? numerator / denominator : 0.0;
    final intercept = meanY - slope * meanX;

    final startY = (slope * 1.0 + intercept).clamp(0.0, 100.0);
    final endY = (slope * n.toDouble() + intercept).clamp(0.0, 100.0);

    return _LinearRegressionResult(
      slope: slope,
      intercept: intercept,
      startY: startY,
      endY: endY,
    );
  }
}

// ─────────────────────────────────────────────────────────
// Linear Regression Data Structure
// ─────────────────────────────────────────────────────────

class _LinearRegressionResult {
  final double slope;
  final double intercept;
  final double startY;
  final double endY;

  const _LinearRegressionResult({
    required this.slope,
    required this.intercept,
    required this.startY,
    required this.endY,
  });
}

// ─────────────────────────────────────────────────────────
// Custom Painter for Trend Overlay (Gridlines, Baseline, Trendline)
// ─────────────────────────────────────────────────────────

class _TrendChartOverlayPainter extends CustomPainter {
  final int sessionCount;
  final double slotWidth;
  final double chartHeight;
  final _LinearRegressionResult regression;
  final double? baselineValue;

  _TrendChartOverlayPainter({
    required this.sessionCount,
    required this.slotWidth,
    required this.chartHeight,
    required this.regression,
    required this.baselineValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final effectivePlotHeight = chartHeight - 28.0;

    // 1. Horizontal Gridlines at 100, 75, 50, 25, 0
    final levels = [100.0, 75.0, 50.0, 25.0, 0.0];
    for (final level in levels) {
      final y = effectivePlotHeight - (level / 100.0) * effectivePlotHeight + 14.0;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // 2. Personal Baseline Line (if active & baselineValue provided)
    if (baselineValue != null) {
      final baselinePaint = Paint()
        ..color = AppColors.secondary
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;

      final y = effectivePlotHeight - (baselineValue! / 100.0) * effectivePlotHeight + 14.0;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), baselinePaint);
    }

    // 3. Linear Regression Trendline (if >= 2 sessions)
    if (sessionCount >= 2) {
      final trendPaint = Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final dotPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.fill;

      final startX = slotWidth / 2.0;
      final startY = effectivePlotHeight - (regression.startY / 100.0) * effectivePlotHeight + 14.0;

      final endX = (sessionCount - 0.5) * slotWidth;
      final endY = effectivePlotHeight - (regression.endY / 100.0) * effectivePlotHeight + 14.0;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), trendPaint);
      canvas.drawCircle(Offset(startX, startY), 3.5, dotPaint);
      canvas.drawCircle(Offset(endX, endY), 3.5, dotPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 5.0;
    const double dashSpace = 4.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      final x2 = math.min(startX + dashWidth, p2.dx);
      canvas.drawLine(Offset(startX, p1.dy), Offset(x2, p1.dy), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _TrendChartOverlayPainter oldDelegate) {
    return oldDelegate.sessionCount != sessionCount ||
        oldDelegate.slotWidth != slotWidth ||
        oldDelegate.chartHeight != chartHeight ||
        oldDelegate.regression != regression ||
        oldDelegate.baselineValue != baselineValue;
  }
}

// ─────────────────────────────────────────────────────────
// Shimmer Animation Widget
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
