import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/wellness_bloc.dart';
import '../bloc/wellness_event.dart';
import '../bloc/wellness_state.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../analytics/presentation/pages/analytics_page.dart';
import '../../../analytics/presentation/bloc/analytics_bloc.dart';
import '../../../analytics/presentation/bloc/analytics_event.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// The central dashboard screen managing navigation tabs and real health metrics.
class DashboardPage extends StatefulWidget {
  final int initialTab;
  const DashboardPage({super.key, this.initialTab = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _currentTabIndex;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTab;
    // Full data fetch (score + logs + recordings + history) on app open
    context.read<WellnessBloc>().add(const WellnessFetchDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _buildHomeTab(),
      _buildRecordTabPlaceholder(),
      const HistoryPage(),
      const AnalyticsPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: tabs[_currentTabIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 11),
        onTap: (index) {
          if (index == 1) {
            // Capture bloc references before async gap to avoid BuildContext warning
            final wellnessBloc = context.read<WellnessBloc>();
            final analyticsBloc = context.read<AnalyticsBloc>();
            context.push('/record').then((_) {
              if (mounted) {
                // After recording, fetch fresh score and refresh analytics
                wellnessBloc.add(const WellnessFetchScoreEvent());
                analyticsBloc.add(const AnalyticsLoadEvent());
              }
            });
            return;
          }
          setState(() {
            _currentTabIndex = index;
          });
          if (index == 0) {
            // Navigating to Home tab — lightweight score refresh only
            context.read<WellnessBloc>().add(const WellnessFetchScoreEvent());
          } else if (index == 2) {
            // History tab needs full data
            context.read<WellnessBloc>().add(const WellnessFetchDataEvent());
          } else if (index == 3) {
            // Analytics tab — always fetch fresh analytics data
            context.read<AnalyticsBloc>().add(const AnalyticsLoadEvent());
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none_outlined),
            activeIcon: Icon(Icons.mic),
            label: 'Record',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            activeIcon: Icon(Icons.history_toggle_off_rounded),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline_rounded),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final authState = context.watch<AuthBloc>().state;
    final cachedName = sl<ApiClient>().userName;
    String name = 'User';
    if (authState is AuthAuthenticated) {
      if (authState.user.name != null && authState.user.name!.isNotEmpty) {
        name = authState.user.name!.split(' ').first;
      } else if (cachedName != null && cachedName.isNotEmpty) {
        name = cachedName.split(' ').first;
      } else {
        name = authState.user.email.split('@').first;
      }
    } else if (cachedName != null && cachedName.isNotEmpty) {
      name = cachedName.split(' ').first;
    }

    return BlocBuilder<WellnessBloc, WellnessState>(
      builder: (context, state) {
        final recentAudio = state.audioAnalyses;
        final isLoading = state.status == WellnessStatus.loading ||
            state.status == WellnessStatus.scoreLoading;

        return SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              // Pull-to-refresh always fetches latest score from GET /score/latest
              context.read<WellnessBloc>().add(const WellnessFetchScoreEvent());
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Greeting Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 20,
                            backgroundColor: AppColors.primary,
                            child: Icon(Icons.person, color: AppColors.surface, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome back,',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.text),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              )
                            : const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 24),
                        onPressed: isLoading
                            ? null
                            : () {
                                // Refresh icon — always fetch latest score from GET /score/latest
                                context.read<WellnessBloc>().add(const WellnessFetchScoreEvent());
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Lungs Health Score Circular Dial Card
                  _buildLungsHealthScoreCard(state),
                  const SizedBox(height: 20),

                  // 4 Specific Health Score Breakdown Cards
                  _buildFourScoreCards(state),
                  const SizedBox(height: 24),

                  // Quick Actions
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActionsGrid(),
                  const SizedBox(height: 24),

                  // Continuous Auto-Scrolling Daily Tips Section
                  const Text(
                    'Daily Respiratory Tips',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
                  ),
                  const SizedBox(height: 12),
                  const _DailyTipsCarousel(),
                  const SizedBox(height: 24),

                  // Recent Activity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Recent Activity',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _currentTabIndex = 2; // Jump to History tab
                          });
                        },
                        child: const Text(
                          'See all',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildRecentActivityList(recentAudio, state.dailyLogs),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLungsHealthScoreCard(WellnessState state) {
    // Single source of truth from GET /score/latest
    final scoreEntity = state.latestScore ??
        (state.scoreHistory.isNotEmpty ? state.scoreHistory.first : null);

    final double? lungWellnessScore = scoreEntity?.lungWellnessScore ??
        (scoreEntity?.score != null && scoreEntity!.score > 0 ? scoreEntity.score.toDouble() : null);
    final DateTime? scoreTime = scoreEntity?.timestamp;

    final hasScore = lungWellnessScore != null && lungWellnessScore > 0;
    final displayScoreVal = hasScore ? lungWellnessScore : 0.0;
    final statusText = hasScore
        ? (displayScoreVal >= 80 ? 'EXCELLENT' : (displayScoreVal >= 60 ? 'FAIR' : 'ATTENTION'))
        : 'NO SCORE YET';
    final statusColor = hasScore
        ? (displayScoreVal >= 80
            ? AppColors.supportingGreen
            : (displayScoreVal >= 60 ? AppColors.secondary : AppColors.error))
        : AppColors.textSecondary;

    // Formatting lung_wellness_score to 1 decimal place if fractional, else int
    final scoreStr = hasScore
        ? (lungWellnessScore % 1 == 0 ? lungWellnessScore.toInt().toString() : lungWellnessScore.toStringAsFixed(1))
        : '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 140,
                width: 140,
                child: CircularProgressIndicator(
                  value: hasScore ? (displayScoreVal / 100.0) : 0.0,
                  strokeWidth: 10,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    scoreStr,
                    style: TextStyle(
                      fontSize: scoreStr.length > 4 ? 32 : 40,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    statusText,
                    style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Lung Wellness Score',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
          ),
          const SizedBox(height: 6),
          Text(
            (scoreEntity?.message != null && scoreEntity!.message!.isNotEmpty)
                ? scoreEntity.message!
                : (hasScore
                    ? 'Score computed fresh from backend.'
                    : 'No score computed yet. Complete your symptom check-in and audio recordings to compute today\'s score.'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          if (hasScore && scoreTime != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time_rounded, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  'Updated ${_formatScoreTimestamp(scoreTime)}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFourScoreCards(WellnessState state) {
    // Aligned timestamp from GET /score/latest response
    final scoreTime = state.latestScore?.timestamp ??
        (state.scoreHistory.isNotEmpty ? state.scoreHistory.first.timestamp : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Health Score Breakdown',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Cough Score',
                score: state.coughScore,
                timestamp: scoreTime,
                icon: Icons.sick_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Breathing Score',
                score: state.breathingScore,
                timestamp: scoreTime,
                icon: Icons.air_rounded,
                color: AppColors.supportingGreen,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                title: 'Symptom Score',
                score: state.symptomScore,
                timestamp: scoreTime,
                icon: Icons.assignment_turned_in_outlined,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Trend Score',
                score: state.trendScore,
                timestamp: scoreTime,
                icon: Icons.trending_up_rounded,
                color: Colors.indigoAccent,
                customStatusText: 'Personal trend',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int? score,
    required DateTime? timestamp,
    required IconData icon,
    required Color color,
    String? customStatusText,
  }) {
    final hasScore = score != null && score > 0;
    final statusText = customStatusText ??
        (hasScore
            ? (score >= 80 ? 'Optimal' : (score >= 60 ? 'Fair' : 'Attention'))
            : 'No logs yet');
    final statusColor = customStatusText != null
        ? AppColors.primary
        : (hasScore
            ? (score >= 80 ? AppColors.supportingGreen : (score >= 60 ? AppColors.secondary : AppColors.error))
            : AppColors.textSecondary);

    return Container(
      padding: const EdgeInsets.all(16.0),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasScore ? '$score' : '--',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.text),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: statusColor),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _formatScoreTimestamp(hasScore ? timestamp : null),
            style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _formatScoreTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'No data yet';
    final now = DateTime.now();
    final isToday = now.year == timestamp.year && now.month == timestamp.month && now.day == timestamp.day;
    final isYesterday = now.subtract(const Duration(days: 1)).year == timestamp.year &&
        now.subtract(const Duration(days: 1)).month == timestamp.month &&
        now.subtract(const Duration(days: 1)).day == timestamp.day;

    final hour = timestamp.hour > 12 ? timestamp.hour - 12 : (timestamp.hour == 0 ? 12 : timestamp.hour);
    final minuteStr = timestamp.minute.toString().padLeft(2, '0');
    final period = timestamp.hour >= 12 ? 'PM' : 'AM';
    final timeStr = "$hour:$minuteStr $period";

    if (isToday) {
      return "Today, $timeStr";
    } else if (isYesterday) {
      return "Yesterday, $timeStr";
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return "${timestamp.day} ${months[timestamp.month - 1]}, $timeStr";
    }
  }

  // _extractBreakdownScore removed — scores are now parsed centrally in
  // WellnessBloc._parseComponentScores and exposed via WellnessState.componentScores.

  Widget _buildQuickActionsGrid() {
    return Column(
      children: [
        // Main Unified Daily Check-in Hero Card
        GestureDetector(
          onTap: () async {
            await context.push('/daily-checkin');
            if (mounted) {
              context.read<WellnessBloc>().add(const WellnessFetchDataEvent());
              context.read<AnalyticsBloc>().add(const AnalyticsLoadEvent());
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18.0),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE8F5E9),
                  Color(0xFFE0F2F1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.supportingGreen],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Daily Check-in',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: Color(0xFF1C2B3A),
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: AppColors.supportingGreen,
                          ),
                        ],
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Cough • Breathing • Symptoms',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.supportingGreen,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Complete 3 steps to compute your score',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5C5870),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Start',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Individual quick actions row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Cough',
                  subtitle: 'Record your\ncough',
                  icon: Icons.mic_rounded,
                  cardBgColor: const Color(0xFFF0FAF0),
                  iconGradientColors: [const Color(0xFF7BC67E), const Color(0xFF43A047)],
                  waveColor: const Color(0xFFB9E4B9),
                  arrowColor: const Color(0xFF43A047),
                  onTap: () async {
                    await context.push('/record?tab=0');
                    if (mounted) {
                      context.read<WellnessBloc>().add(const WellnessFetchScoreEvent());
                      context.read<AnalyticsBloc>().add(const AnalyticsLoadEvent());
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Breathing',
                  subtitle: 'Record your\nbreathing',
                  icon: Icons.air_rounded,
                  cardBgColor: const Color(0xFFE8F7F8),
                  iconGradientColors: [const Color(0xFF4ECDC4), const Color(0xFF00897B)],
                  waveColor: const Color(0xFFACE0DC),
                  arrowColor: const Color(0xFF00897B),
                  onTap: () async {
                    await context.push('/record?tab=1');
                    if (mounted) {
                      context.read<WellnessBloc>().add(const WellnessFetchScoreEvent());
                      context.read<AnalyticsBloc>().add(const AnalyticsLoadEvent());
                    }
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildQuickActionCard(
                  title: 'Symptoms',
                  subtitle: 'Log your\nsymptoms',
                  icon: Icons.sentiment_satisfied_alt_rounded,
                  cardBgColor: const Color(0xFFF3EFFA),
                  iconGradientColors: [const Color(0xFFB39DDB), const Color(0xFF7E57C2)],
                  waveColor: const Color(0xFFCFBEEA),
                  arrowColor: const Color(0xFF7E57C2),
                  onTap: () async {
                    await context.push('/daily-log');
                    if (mounted) {
                      context.read<WellnessBloc>().add(const WellnessFetchScoreEvent());
                      context.read<AnalyticsBloc>().add(const AnalyticsLoadEvent());
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color cardBgColor,
    required List<Color> iconGradientColors,
    required Color waveColor,
    required Color arrowColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: arrowColor.withValues(alpha: 0.15), width: 1),
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(
          children: [
            // Wave decoration at bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                size: const Size(double.infinity, 48),
                painter: _WavePainter(color: waveColor.withValues(alpha: 0.55)),
              ),
            ),
            // Card content
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 14, 10, 44),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Gradient circular icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: iconGradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: iconGradientColors.last.withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(height: 10),
                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      color: Color(0xFF1C2B3A),
                      height: 1.25,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.5,
                      color: const Color(0xFF1C2B3A).withValues(alpha: 0.55),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Bottom-right circular arrow button
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: arrowColor.withValues(alpha: 0.12),
                ),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: arrowColor,
                  size: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(List<AudioAnalysisEntity> audioList, List<DailyLogEntity> logList) {
    if (audioList.isEmpty && logList.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.border),
        ),
        child: const Center(
          child: Text(
            'No recent activity yet.\nComplete a recording or symptom log to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ),
      );
    }

    final items = audioList.take(3).toList();

    return Column(
      children: items.map((item) {
        final iconColor = item.lungsScore >= 90 ? AppColors.supportingGreen : AppColors.secondary;
        final iconData = item.type == 'Cough' ? Icons.sick_outlined : Icons.air_rounded;

        return Container(
          margin: const EdgeInsets.only(bottom: 12.0),
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: iconColor.withValues(alpha: 0.12),
                      child: Icon(iconData, color: iconColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.type == 'Cough' ? 'Cough Recording' : 'Breathing Session',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatShortTime(item.timestamp),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Score ${item.lungsScore}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: iconColor, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${item.duration}s',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatShortTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time).inDays;

    String day = 'Today';
    if (difference == 1) {
      day = 'Yesterday';
    } else if (difference > 1) {
      day = '${time.day}/${time.month}';
    }

    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$day, $hour:$minute';
  }

  Widget _buildRecordTabPlaceholder() {
    return const SizedBox.shrink();
  }
}

/// Auto-scrolling carousel demonstrating tips
class _DailyTipsCarousel extends StatefulWidget {
  const _DailyTipsCarousel();

  @override
  State<_DailyTipsCarousel> createState() => _DailyTipsCarouselState();
}

class _DailyTipsCarouselState extends State<_DailyTipsCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _tips = [
    {
      'title': 'Stay Hydrated for Mucus Clearance',
      'body': 'Drinking 2-3 liters of water per day thins lung mucus secretions and promotes natural airway clearing.',
      'tag': 'HYDRATION',
    },
    {
      'title': 'Practice 4-7-8 Breathing',
      'body': 'Inhale for 4 seconds, hold for 7, and exhale slowly for 8 to improve lung capacity and ease anxiety.',
      'tag': 'EXERCISE',
    },
    {
      'title': 'Maintain Good Posture',
      'body': 'Sitting upright expands your diaphragm and increases oxygen uptake by up to 30%.',
      'tag': 'WELLNESS',
    },
    {
      'title': 'Monitor Humidity Levels',
      'body': 'Keeping indoor humidity between 40-50% protects airway mucosa from dryness and irritation.',
      'tag': 'ENVIRONMENT',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _tips.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 120,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _tips.length,
            itemBuilder: (context, index) {
              final tip = _tips[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.08),
                      AppColors.supportingGreen.withValues(alpha: 0.06),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            tip['tag']!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip['title']!,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.text,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tip['body']!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _tips.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentPage == index ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentPage == index ? AppColors.primary : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Paints a soft wave shape used as decoration at the bottom of Quick Action cards.
class _WavePainter extends CustomPainter {
  final Color color;
  const _WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.55);
    path.cubicTo(
      size.width * 0.25, size.height * 0.15,
      size.width * 0.55, size.height * 0.85,
      size.width * 0.80, size.height * 0.40,
    );
    path.cubicTo(
      size.width * 0.90, size.height * 0.20,
      size.width * 0.96, size.height * 0.50,
      size.width, size.height * 0.38,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Second lighter wave layer
    final paint2 = Paint()
      ..color = color.withValues(alpha: color.a * 0.5)
      ..style = PaintingStyle.fill;
    final path2 = Path();
    path2.moveTo(0, size.height * 0.75);
    path2.cubicTo(
      size.width * 0.30, size.height * 0.35,
      size.width * 0.65, size.height * 0.95,
      size.width, size.height * 0.55,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.color != color;
}
