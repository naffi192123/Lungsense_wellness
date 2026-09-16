import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';
import '../bloc/analytics_bloc.dart';
import '../bloc/analytics_event.dart';
import '../bloc/analytics_state.dart';

/// Full-featured Analytics screen driven entirely from backend APIs,
/// matching the exact LungSense Wellness reference design.
///
/// Features:
///   1. Header with "Analytics", subtitle, "Last 30 Days" / "Last 7 Days" filter, and refresh.
///   2. Top Row: 3 summary cards (LATEST SCORE, AVERAGE SCORE, PEAK SCORE) with icons & subtext.
///   3. "Lung Wellness Trend" card:
///      - Fixed 0 to 100 Y-axis (ticks: 100, 80, 60, 40, 20, 0) with "Wellness Score" axis title.
///      - Gradient score bars with exact score text directly above each bar.
///      - S1..Sn labels with formatted dates (e.g. "Aug 25") underneath.
///      - Linear regression trendline connecting dots across sessions.
///      - Dashed orange Personal Baseline line with "76.9 Baseline" label at the right end.
///      - Bottom legend: Wellness score (per session), Trend line, Personal baseline.
///   4. "PERSONAL BASELINE" panel:
///      - 3-column layout: Baseline score, Latest vs Baseline, Baseline info.
///      - Building state (< 7 sessions) with session progress bar.
///   5. Bottom Row (Side-by-side cards):
///      - Left: "Score Distribution" with Donut chart and 5-tier colored band legend.
///      - Right: "Key Insights" (💡) with Trend, Baseline, and Personal Best insight cards.
class AnalyticsPage extends StatefulWidget {
  const AnalyticsPage({super.key});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  int _selectedFilterDays = 30; // 30 or 7

  // ScrollController for the trend chart – auto-scrolls to newest (rightmost) session
  final ScrollController _chartScrollController = ScrollController();

  /// Schedules a jump to the far right of the chart after the current frame.
  void _jumpChartToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chartScrollController.hasClients &&
          _chartScrollController.position.maxScrollExtent > 0) {
        _chartScrollController.jumpTo(
          _chartScrollController.position.maxScrollExtent,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AnalyticsBloc>().add(const AnalyticsLoadEvent());
      }
      _jumpChartToEnd();
    });
  }

  @override
  void dispose() {
    _chartScrollController.dispose();
    super.dispose();
  }

  void _refresh() {
    context.read<AnalyticsBloc>().add(const AnalyticsLoadEvent());
    _jumpChartToEnd();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnalyticsBloc, AnalyticsState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
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
  // Header: Title, Subtitle, Filter Dropdown, Refresh Button
  // ─────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context, AnalyticsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Your lung wellness insights',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          // Filter Dropdown Pill: "Last 30 Days ▾"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: _selectedFilterDays,
                isDense: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: Color(0xFF475569),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 30,
                    child: Text(
                      'Last 30 Days',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
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
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedFilterDays = val;
                    });
                    _jumpChartToEnd();
                  }
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Refresh Button: circular green
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
                    color: Color(0xFF22C55E),
                  ),
                ),
              ),
            )
          else
            Tooltip(
              message: 'Refresh analytics',
              child: GestureDetector(
                onTap: _refresh,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F8EE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF22C55E),
                    size: 20,
                  ),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8.0),
      child: Column(
        children: [
          _shimmerBlock(height: 90),
          const SizedBox(height: 16),
          _shimmerBlock(height: 380),
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
        color: const Color(0xFFE2E8F0).withValues(alpha: 0.5),
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
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFEF4444)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Unable to load analytics',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              message ?? 'Check your connection and try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.5),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22C55E),
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
                color: const Color(0xFF22C55E).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.analytics_outlined, size: 56, color: Color(0xFF22C55E)),
            ),
            const SizedBox(height: 24),
            const Text(
              'No wellness data yet',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your Lung Wellness Score will appear here after you complete your first wellness session.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF64748B), height: 1.5, fontSize: 13.5),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Refresh'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF22C55E),
                side: const BorderSide(color: Color(0xFF22C55E)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Main Content
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

    // Chronological order (S1, S2...)
    final chronological = validHistory.reversed.toList();

    // Total valid sessions across account
    final totalValidSessions = state.scoreHistory
        .where((e) => (e.lungWellnessScore ?? e.score.toDouble()) > 0)
        .length;

    final backendSessionCount = state.baselineStatus?['session_count'] as int?;
    final effectiveSessionCount = backendSessionCount ?? totalValidSessions;
    final isBaselineActive = effectiveSessionCount >= 7;

    // Baseline value from backend
    final baselineValue = isBaselineActive ? _extractBaselineValue(state.baselineStatus) : null;

    final validScoresChronological = chronological
        .map((e) => (e.lungWellnessScore ?? e.score.toDouble()))
        .toList();
    final regression = _calculateRegression(validScoresChronological);

    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      color: const Color(0xFF22C55E),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (errorBanner != null) ...[
              _buildErrorBanner(errorBanner),
              const SizedBox(height: 14),
            ],

            // 1. Top Row: 3 Summary Cards
            _buildSummaryCards(validHistory),
            const SizedBox(height: 16),

            // 2. Lung Wellness Trend Card (Includes Trend Graph + Personal Baseline Panel)
            _buildTrendCardWithBaseline(
              context: context,
              chronologicalSessions: chronological,
              regression: regression,
              baselineValue: baselineValue,
              isBaselineActive: isBaselineActive,
              effectiveSessionCount: effectiveSessionCount,
              latestScore: validHistory.isNotEmpty
                  ? (validHistory.first.lungWellnessScore ?? validHistory.first.score.toDouble())
                  : null,
            ),
            const SizedBox(height: 16),

            // 3. Bottom Section: Score Distribution + Key Insights (full-width, stacked)
            _buildScoreDistributionCard(context, validHistory),
            const SizedBox(height: 14),
            _buildKeyInsightsCard(
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
        color: const Color(0xFFEF4444).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Showing cached data. Refresh failed.',
              style: TextStyle(fontSize: 12, color: Color(0xFFEF4444)),
            ),
          ),
          GestureDetector(
            onTap: _refresh,
            child: const Text(
              'Retry',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 1. Top Row: 3 Summary Cards
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
      average = avg.toStringAsFixed(1);
      final hi = validScores.reduce((a, b) => a > b ? a : b);
      peak = hi.round().toString();
    }

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'LATEST SCORE',
            value: latest,
            subtitle: 'Current score',
            color: const Color(0xFF16A34A), // Vibrant Green
            bgColor: const Color(0xFFE8F8EE),
            icon: Icons.speed_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            title: 'AVERAGE SCORE',
            value: average,
            subtitle: 'Across all sessions',
            color: const Color(0xFF0284C7), // Blue / Cyan
            bgColor: const Color(0xFFE0F2FE),
            icon: Icons.bar_chart_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricCard(
            title: 'PEAK SCORE',
            value: peak,
            subtitle: 'Highest score',
            color: const Color(0xFFEA580C), // Orange
            bgColor: const Color(0xFFFFF7ED),
            icon: Icons.star_rounded,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 10.5,
              color: Color(0xFF64748B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // 2. Lung Wellness Trend Card (Graph + Baseline Panel)
  // ─────────────────────────────────────────────────────────

  Widget _buildTrendCardWithBaseline({
    required BuildContext context,
    required List<ScoreHistoryEntity> chronologicalSessions,
    required _LinearRegressionResult regression,
    required double? baselineValue,
    required bool isBaselineActive,
    required int effectiveSessionCount,
    required double? latestScore,
  }) {
    final count = chronologicalSessions.length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lung Wellness Trend',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count session${count == 1 ? '' : 's'} recorded',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'Scale: 0 – 100',
                  style: TextStyle(fontSize: 10.5, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // The Trend Graph
          if (count == 0)
            _buildChartEmpty()
          else
            _buildFullTrendGraph(
              chronologicalSessions: chronologicalSessions,
              regression: regression,
              baselineValue: baselineValue,
              isBaselineActive: isBaselineActive,
            ),

          const SizedBox(height: 18),

          // PERSONAL BASELINE Sub-Panel inside the Trend Card
          _buildPersonalBaselineSubPanel(
            context: context,
            sessionCount: effectiveSessionCount,
            isBaselineActive: isBaselineActive,
            baselineValue: baselineValue,
            latestScore: latestScore,
          ),
        ],
      ),
    );
  }

  Widget _buildChartEmpty() {
    return Container(
      height: 150,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.bar_chart_rounded, size: 36, color: Color(0xFFCBD5E1)),
          SizedBox(height: 8),
          Text(
            'No scored sessions in this period',
            style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildFullTrendGraph({
    required List<ScoreHistoryEntity> chronologicalSessions,
    required _LinearRegressionResult regression,
    required double? baselineValue,
    required bool isBaselineActive,
  }) {
    const double plotHeight = 150.0;
    const double topTextHeight = 24.0;
    const double bottomLabelsHeight = 36.0;
    const double totalGraphHeight = topTextHeight + plotHeight + bottomLabelsHeight;
    const double rightLabelWidth = 46.0;

    final count = chronologicalSessions.length;

    // ── Dynamic slot & bar widths based on filter + session count ──
    final double slotWidth;
    final double barWidth;
    if (_selectedFilterDays == 7) {
      slotWidth = 56.0;
      barWidth = 30.0;
    } else {
      // 30 Days
      if (count <= 10) {
        slotWidth = 52.0;
        barWidth = 28.0;
      } else if (count <= 20) {
        slotWidth = 38.0;
        barWidth = 20.0;
      } else {
        slotWidth = 28.0;
        barWidth = 14.0;
      }
    }

    final double totalContentWidth = count * slotWidth + rightLabelWidth;

    // Jump to rightmost (newest) on next frame
    _jumpChartToEnd();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pinned Left Y-Axis: "Wellness Score" rotated label
        SizedBox(
          width: 14,
          height: totalGraphHeight,
          child: Center(
            child: RotatedBox(
              quarterTurns: 3,
              child: const Text(
                'Wellness Score',
                style: TextStyle(
                  fontSize: 9.0,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        // Y-axis numbers 100, 80, 60, 40, 20, 0
        SizedBox(
          width: 26,
          height: totalGraphHeight,
          child: Padding(
            padding: const EdgeInsets.only(top: topTextHeight, bottom: bottomLabelsHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: const [
                Text('100', style: TextStyle(fontSize: 9.0, color: Color(0xFF64748B))),
                Text('80', style: TextStyle(fontSize: 9.0, color: Color(0xFF64748B))),
                Text('60', style: TextStyle(fontSize: 9.0, color: Color(0xFF64748B))),
                Text('40', style: TextStyle(fontSize: 9.0, color: Color(0xFF64748B))),
                Text('20', style: TextStyle(fontSize: 9.0, color: Color(0xFF64748B))),
                Text('0', style: TextStyle(fontSize: 9.0, color: Color(0xFF64748B))),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),

        // Always scrollable chart – ScrollController auto-jumps to rightmost
        Expanded(
          child: SingleChildScrollView(
            controller: _chartScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalContentWidth,
              height: totalGraphHeight,
              child: _buildTrendCanvas(
                chronologicalSessions: chronologicalSessions,
                baselineValue: baselineValue,
                isBaselineActive: isBaselineActive,
                slotWidth: slotWidth,
                barWidth: barWidth,
                plotHeight: plotHeight,
                topTextHeight: topTextHeight,
                bottomLabelsHeight: bottomLabelsHeight,
                rightPadding: rightLabelWidth,
                filterDays: _selectedFilterDays,
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildTrendCanvas({
    required List<ScoreHistoryEntity> chronologicalSessions,
    required double? baselineValue,
    required bool isBaselineActive,
    required double slotWidth,
    required double barWidth,
    required double plotHeight,
    required double topTextHeight,
    required double bottomLabelsHeight,
    required double rightPadding,
    required int filterDays,
  }) {
    final count = chronologicalSessions.length;
    final totalWidth = count * slotWidth + rightPadding;

    // Extract actual scores (clamped 0-100) for trendline dots
    final actualScores = chronologicalSessions
        .map((s) => (s.lungWellnessScore ?? s.score.toDouble()).clamp(0.0, 100.0))
        .toList();

    // Date label density: show every N bars to avoid overlap
    final int dateLabelEvery = filterDays == 7
        ? 1
        : (count <= 10 ? 1 : count <= 20 ? 2 : 3);

    return Stack(
      children: [
        // 1. Gridlines, Axis line, Dashed Baseline line, and Trend Line
        Positioned.fill(
          child: CustomPaint(
            size: Size(totalWidth, topTextHeight + plotHeight + bottomLabelsHeight),
            painter: _LungWellnessTrendPainter(
              sessionCount: count,
              slotWidth: slotWidth,
              plotHeight: plotHeight,
              topTextHeight: topTextHeight,
              actualScores: actualScores,
              baselineValue: isBaselineActive ? baselineValue : null,
              totalWidth: totalWidth,
            ),
          ),
        ),

        // 2. Bars with score values above and labels below
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(count, (index) {
            final session = chronologicalSessions[index];
            final rawScore = (session.lungWellnessScore ?? session.score.toDouble()).clamp(0.0, 100.0);
            final score = rawScore.round();
            final sessionLabel = 'S${index + 1}';
            final dateLabel = _formatSessionDate(session.timestamp);
            final showDate = index % dateLabelEvery == 0 || index == count - 1;

            // ── Bar color logic ──
            // Before baseline active: all teal regardless of score
            // After baseline active: green above, red below, teal equal
            final Color barColor;
            final List<Color> barGradientColors;
            if (!isBaselineActive) {
              barColor = const Color(0xFF00B4D8);
              barGradientColors = [const Color(0xFF48CAE4), const Color(0xFF00B4D8)];
            } else {
              final bv = baselineValue ?? 0.0;
              if (rawScore > bv) {
                barColor = const Color(0xFF65C43B);
                barGradientColors = [const Color(0xFF8CE052), const Color(0xFF65C43B)];
              } else if (rawScore < bv) {
                barColor = const Color(0xFFEF4444);
                barGradientColors = [const Color(0xFFF87171), const Color(0xFFEF4444)];
              } else {
                barColor = const Color(0xFF00B4D8);
                barGradientColors = [const Color(0xFF48CAE4), const Color(0xFF00B4D8)];
              }
            }

            final barHeight = (rawScore / 100.0) * plotHeight;
            final barTopOffset = topTextHeight + (plotHeight - barHeight);

            return SizedBox(
              width: slotWidth,
              height: topTextHeight + plotHeight + bottomLabelsHeight,
              child: Stack(
                alignment: Alignment.topCenter,
                children: [
                  // Score value directly on top of the bar
                  Positioned(
                    top: barTopOffset - 16,
                    child: Text(
                      score.toString(),
                      style: TextStyle(
                        fontSize: slotWidth >= 48 ? 11 : 9,
                        fontWeight: FontWeight.bold,
                        color: barColor,
                      ),
                    ),
                  ),

                  // The rounded gradient bar
                  Positioned(
                    top: barTopOffset,
                    child: Container(
                      width: barWidth,
                      height: barHeight.clamp(4.0, plotHeight),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: barGradientColors,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ),
                  ),

                  // Session ID and Date under the bar
                  Positioned(
                    top: topTextHeight + plotHeight + 4,
                    child: Column(
                      children: [
                        Text(
                          sessionLabel,
                          style: TextStyle(
                            fontSize: slotWidth >= 48 ? 10.5 : 8.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        if (showDate)
                          Text(
                            dateLabel,
                            style: TextStyle(
                              fontSize: slotWidth >= 48 ? 9.5 : 7.5,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                      ],
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
  // PERSONAL BASELINE Sub-Panel (Inside Trend Card)
  // ─────────────────────────────────────────────────────────

  Widget _buildPersonalBaselineSubPanel({
    required BuildContext context,
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
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.adjust_rounded, color: Color(0xFFD97706), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PERSONAL BASELINE',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'BUILDING',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                  ],
                ),
                InkWell(
                  onTap: () => _showPersonalBaselineInfo(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                      SizedBox(width: 3),
                      Text(
                        'Learn more',
                        style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                minHeight: 5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Complete 7 sessions to establish your personal baseline.',
              style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
          ],
        ),
      );
    }

    // ACTIVE State: >= 7 sessions (2-Column Side-by-Side Layout as reference)
    final baseline = baselineValue ?? 76.9;
    final latest = latestScore ?? baseline;
    final diff = latest - baseline;
    final isHigher = diff >= 0;
    final diffStr = isHigher ? '+${diff.toStringAsFixed(1)}' : diff.toStringAsFixed(1);
    final diffColor = isHigher ? const Color(0xFF16A34A) : const Color(0xFFEF4444);
    final diffCardBg = isHigher ? const Color(0xFFF0FAF5) : const Color(0xFFFEF2F2);
    final diffIconBg = isHigher ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.adjust_rounded, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'PERSONAL BASELINE',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: () => _showPersonalBaselineInfo(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.info_outline_rounded, size: 15, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Text(
                        'Learn more',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2-Column Side-by-Side Content Row
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // LEFT COLUMN: PERSONAL BASELINE
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FAF5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.bar_chart_rounded,
                            color: Color(0xFF16A34A),
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          baseline.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF16A34A),
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Your personal baseline',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Based on your most recent 7 completed sessions.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Subtle Vertical Divider
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  width: 1,
                  color: const Color(0xFFE2E8F0),
                ),

                // RIGHT COLUMN: LATEST VS BASELINE
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: diffCardBg,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: diffIconBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isHigher ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                            color: diffColor,
                            size: 18,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'LATEST VS BASELINE',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          diffStr,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: diffColor,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your latest score is ${diff.abs().toStringAsFixed(1)} points ${isHigher ? 'above' : 'below'} your personal baseline.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF64748B),
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPersonalBaselineInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Icon(Icons.adjust_rounded, color: Color(0xFF16A34A), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'About Personal Baseline',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your Personal Baseline is established after completing 7 sessions. It represents your typical wellness score and serves as an individual reference point to track changes over time.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  // ─────────────────────────────────────────────────────────
  // 3. Bottom Section: Score Distribution (Full-Width Card)
  // ─────────────────────────────────────────────────────────

  Widget _buildScoreDistributionCard(
    BuildContext context,
    List<ScoreHistoryEntity> validHistory,
  ) {
    final scores = validHistory
        .map((e) => (e.lungWellnessScore ?? e.score.toDouble()))
        .toList();
    final total = scores.length;

    final count80_100 = scores.where((s) => s >= 80 && s <= 100).length;
    final count60_79 = scores.where((s) => s >= 60 && s < 80).length;
    final count40_59 = scores.where((s) => s >= 40 && s < 60).length;
    final count20_39 = scores.where((s) => s >= 20 && s < 40).length;
    final count0_19 = scores.where((s) => s >= 0 && s < 20).length;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title & Subtitle on left, "What is this?" on right
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Score Distribution',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      total == 0
                          ? 'No completed sessions'
                          : 'Based on $total session${total == 1 ? '' : 's'}',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _showScoreDistributionInfo(context),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF64748B)),
                      SizedBox(width: 4),
                      Text(
                        'What is this?',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (total == 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              alignment: Alignment.center,
              child: Column(
                children: const [
                  Icon(Icons.pie_chart_outline_rounded, size: 40, color: Color(0xFFCBD5E1)),
                  SizedBox(height: 8),
                  Text(
                    'No completed sessions in this period',
                    style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            )
          else
            // Donut Chart + Legend List side by side in full width
            Row(
              children: [
                // Donut Chart
                SizedBox(
                  width: 125,
                  height: 125,
                  child: CustomPaint(
                    painter: _DonutChartPainter(
                      counts: [count80_100, count60_79, count40_59, count20_39, count0_19],
                      colors: const [
                        Color(0xFF65C43B), // Green (80-100)
                        Color(0xFF00B4D8), // Cyan (60-79)
                        Color(0xFFFBBF24), // Yellow (40-59)
                        Color(0xFFF97316), // Orange (20-39)
                        Color(0xFFEF4444), // Red (0-19)
                      ],
                      total: total,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            total.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                              height: 1.0,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Sessions',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),

                // Legend List
                Expanded(
                  child: Column(
                    children: [
                      _buildDonutLegendRow(color: const Color(0xFF65C43B), label: '80 – 100', count: count80_100, total: total),
                      const SizedBox(height: 8),
                      _buildDonutLegendRow(color: const Color(0xFF00B4D8), label: '60 – 79', count: count60_79, total: total),
                      const SizedBox(height: 8),
                      _buildDonutLegendRow(color: const Color(0xFFFBBF24), label: '40 – 59', count: count40_59, total: total),
                      const SizedBox(height: 8),
                      _buildDonutLegendRow(color: const Color(0xFFF97316), label: '20 – 39', count: count20_39, total: total),
                      const SizedBox(height: 8),
                      _buildDonutLegendRow(color: const Color(0xFFEF4444), label: '0 – 19', count: count0_19, total: total),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  void _showScoreDistributionInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: const [
                    Icon(Icons.pie_chart_outline_rounded, color: Color(0xFF0284C7), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'About Score Distribution',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Score Distribution shows how your completed Wellness Scores are spread across different score ranges. The percentage represents the proportion of your completed sessions within each range.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Got it',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _buildDonutLegendRow({
    required Color color,
    required String label,
    required int count,
    required int total,
  }) {
    final pct = total > 0 ? ((count / total) * 100).round() : 0;
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF475569),
          ),
        ),
        const Spacer(),
        Text(
          '$count ($pct%)',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────
  // 4. Bottom Section: Key Insights (Full-Width Card)
  // ─────────────────────────────────────────────────────────

  Widget _buildKeyInsightsCard({
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
    final Color trendIconColor;
    final Color trendIconBg;
    final Color trendCardBg;

    if (count < 2) {
      trendTitle = 'Building Trend';
      trendMessage = 'Complete more sessions to establish a meaningful trend.';
      trendIcon = Icons.hourglass_top_rounded;
      trendIconColor = const Color(0xFF16A34A);
      trendIconBg = const Color(0xFFDCFCE7);
      trendCardBg = const Color(0xFFF0FDF4);
    } else if (regression.slope >= 0.5) {
      trendTitle = 'Trends Upward';
      trendMessage = 'Your wellness score is trending upward over recent sessions.';
      trendIcon = Icons.trending_up_rounded;
      trendIconColor = const Color(0xFF16A34A);
      trendIconBg = const Color(0xFFDCFCE7);
      trendCardBg = const Color(0xFFF0FDF4);
    } else if (regression.slope <= -0.5) {
      trendTitle = 'Trends Downward';
      trendMessage = 'Your wellness score is trending downward over recent sessions.';
      trendIcon = Icons.trending_down_rounded;
      trendIconColor = const Color(0xFFEF4444);
      trendIconBg = const Color(0xFFFEE2E2);
      trendCardBg = const Color(0xFFFEF2F2);
    } else {
      trendTitle = 'Stable Trend';
      trendMessage = 'Your wellness scores have remained relatively stable across recent sessions.';
      trendIcon = Icons.trending_flat_rounded;
      trendIconColor = const Color(0xFF16A34A);
      trendIconBg = const Color(0xFFDCFCE7);
      trendCardBg = const Color(0xFFF0FDF4);
    }

    // 2. Baseline Insight
    final String baselineTitle;
    final String baselineMessage;

    if (!isBaselineActive || baselineValue == null) {
      baselineTitle = 'Building Baseline';
      baselineMessage = 'Complete 7 sessions to unlock your personal baseline insights.';
    } else {
      final last7 = validScoresChronological.length >= 7
          ? validScoresChronological.sublist(validScoresChronological.length - 7)
          : validScoresChronological;
      final aboveCount = last7.where((s) => s > baselineValue).length;
      final belowCount = last7.where((s) => s < baselineValue).length;

      if (aboveCount > belowCount) {
        baselineTitle = 'Above Baseline';
        baselineMessage = '$aboveCount of ${last7.length} sessions are above your baseline.';
      } else if (belowCount > aboveCount) {
        baselineTitle = 'Below Baseline';
        baselineMessage = '$belowCount of ${last7.length} sessions are below your baseline.';
      } else {
        baselineTitle = 'Near Baseline';
        baselineMessage = 'Your recent scores are balanced around your personal baseline.';
      }
    }

    // 3. Personal Best Insight
    final String perfTitle;
    final String perfMessage;
    final int latest = validScoresChronological.isNotEmpty
        ? validScoresChronological.last.round()
        : 0;
    final int peak = validScoresChronological.isNotEmpty
        ? validScoresChronological.reduce((a, b) => a > b ? a : b).round()
        : 0;

    if (count < 2) {
      perfTitle = 'Personal Best';
      perfMessage = 'Complete more sessions to track your highest personal score.';
    } else if (latest >= peak) {
      perfTitle = 'Personal Best';
      perfMessage = 'Your latest score ($latest) is your highest so far!';
    } else {
      perfTitle = 'Personal Best';
      perfMessage = 'Your peak score so far is $peak (latest: $latest).';
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2),
                child: const Icon(Icons.lightbulb_rounded, color: Color(0xFFF59E0B), size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Key Insights',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Personalized insights from your wellness data',
                      style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Item 1: Trend
          _buildInsightItem(
            cardBg: trendCardBg,
            icon: trendIcon,
            iconColor: trendIconColor,
            iconBg: trendIconBg,
            title: trendTitle,
            subtitle: trendMessage,
          ),
          const SizedBox(height: 10),

          // Item 2: Baseline
          _buildInsightItem(
            cardBg: const Color(0xFFFFFBEB),
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFF59E0B),
            iconBg: const Color(0xFFFEF3C7),
            title: baselineTitle,
            subtitle: baselineMessage,
          ),
          const SizedBox(height: 10),

          // Item 3: Personal Best
          _buildInsightItem(
            cardBg: const Color(0xFFFEF2F2),
            icon: Icons.favorite_rounded,
            iconColor: const Color(0xFFEF4444),
            iconBg: const Color(0xFFFEE2E2),
            title: perfTitle,
            subtitle: perfMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem({
    required Color cardBg,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.chevron_right_rounded,
            color: Color(0xFF94A3B8),
            size: 20,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // Helper Methods
  // ─────────────────────────────────────────────────────────

  String _formatSessionDate(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}';
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
// Custom Painter for Trend Graph
// (Gridlines, Dashed Baseline, Baseline Label, and Trendline with points)
// ─────────────────────────────────────────────────────────

class _LungWellnessTrendPainter extends CustomPainter {
  final int sessionCount;
  final double slotWidth;
  final double plotHeight;
  final double topTextHeight;
  final List<double> actualScores; // actual scores per session (0-100)
  final double? baselineValue;
  final double totalWidth;

  _LungWellnessTrendPainter({
    required this.sessionCount,
    required this.slotWidth,
    required this.plotHeight,
    required this.topTextHeight,
    required this.actualScores,
    required this.baselineValue,
    required this.totalWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final double startX = 0.0;
    final double endX = totalWidth;

    // 1. Horizontal Gridlines at 100, 80, 60, 40, 20, 0
    final levels = [100.0, 80.0, 60.0, 40.0, 20.0, 0.0];
    for (final level in levels) {
      final y = topTextHeight + (1.0 - level / 100.0) * plotHeight;
      if (level == 0.0) {
        // Bottom solid axis line
        canvas.drawLine(Offset(startX, y), Offset(endX, y), axisPaint);
      } else {
        // Light gridline
        canvas.drawLine(Offset(startX, y), Offset(endX, y), gridPaint);
      }
    }

    // Left vertical axis line
    canvas.drawLine(
      Offset(startX, topTextHeight),
      Offset(startX, topTextHeight + plotHeight),
      axisPaint,
    );

    // 2. Personal Baseline Horizontal Dashed Line (if active)
    if (baselineValue != null) {
      final baselinePaint = Paint()
        ..color = const Color(0xFFF97316) // Orange
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      final y = topTextHeight + (1.0 - (baselineValue! / 100.0).clamp(0.0, 1.0)) * plotHeight;
      _drawDashedLine(canvas, Offset(startX, y), Offset(endX - 38, y), baselinePaint);

      // Draw "76.9 \n Baseline" text at the right end of the dashed line
      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '${baselineValue!.toStringAsFixed(1)}\n',
            style: const TextStyle(
              color: Color(0xFFEA580C),
              fontWeight: FontWeight.bold,
              fontSize: 10,
              height: 1.1,
            ),
          ),
          const TextSpan(
            text: 'Baseline',
            style: TextStyle(
              color: Color(0xFFEA580C),
              fontWeight: FontWeight.w600,
              fontSize: 8.5,
              height: 1.1,
            ),
          ),
        ],
      );
      final textPainter = TextPainter(
        text: textSpan,
        textAlign: TextAlign.start,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(endX - 34, y - 10));
    }

    // 3. Trend Line: polyline connecting the EXACT TOP CENTER of each bar
    //    Dots are at actualScores[i] y-position — not regression predictions.
    if (sessionCount >= 2 && actualScores.length == sessionCount) {
      final trendLinePaint = Paint()
        ..color = const Color(0xFF0284C7) // Blue
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final dotFillPaint = Paint()
        ..color = const Color(0xFF0284C7)
        ..style = PaintingStyle.fill;

      final dotBorderPaint = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      final path = Path();
      final points = <Offset>[];

      for (int i = 0; i < sessionCount; i++) {
        final x = (i + 0.5) * slotWidth;
        // Use the actual session score — this places the dot at the exact bar top
        final score = actualScores[i].clamp(0.0, 100.0);
        final y = topTextHeight + (1.0 - score / 100.0) * plotHeight;
        points.add(Offset(x, y));
        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      canvas.drawPath(path, trendLinePaint);

      for (final pt in points) {
        canvas.drawCircle(pt, 4.0, dotFillPaint);
        canvas.drawCircle(pt, 4.0, dotBorderPaint);
      }
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const double dashWidth = 6.0;
    const double dashSpace = 4.0;
    double startX = p1.dx;
    while (startX < p2.dx) {
      final x2 = math.min(startX + dashWidth, p2.dx);
      canvas.drawLine(Offset(startX, p1.dy), Offset(x2, p1.dy), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _LungWellnessTrendPainter oldDelegate) {
    return oldDelegate.sessionCount != sessionCount ||
        oldDelegate.slotWidth != slotWidth ||
        oldDelegate.plotHeight != plotHeight ||
        oldDelegate.topTextHeight != topTextHeight ||
        oldDelegate.actualScores.length != actualScores.length ||
        oldDelegate.baselineValue != baselineValue ||
        oldDelegate.totalWidth != totalWidth;
  }
}

// ─────────────────────────────────────────────────────────
// Donut Chart Painter for Score Distribution
// ─────────────────────────────────────────────────────────

class _DonutChartPainter extends CustomPainter {
  final List<int> counts;
  final List<Color> colors;
  final int total;

  _DonutChartPainter({
    required this.counts,
    required this.colors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 18.0;

    if (total == 0) {
      final emptyPaint = Paint()
        ..color = const Color(0xFFE2E8F0)
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke;
      canvas.drawCircle(center, radius, emptyPaint);
      return;
    }

    double startAngle = -math.pi / 2;
    for (int i = 0; i < counts.length; i++) {
      final count = counts[i];
      if (count == 0) continue;
      final sweepAngle = (count / total) * 2 * math.pi;
      final paint = Paint()
        ..color = colors[i]
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.total != total || oldDelegate.counts != counts;
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
                const Color(0xFFE2E8F0).withValues(alpha: 0.3),
                const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                const Color(0xFFE2E8F0).withValues(alpha: 0.3),
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
