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
            // Capture bloc reference before async gap to avoid BuildContext warning
            final bloc = context.read<WellnessBloc>();
            context.push('/record').then((_) {
              if (mounted) {
                // After recording, fetch fresh score from GET /score/latest
                bloc.add(const WellnessFetchScoreEvent());
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildQuickActionCard(
            title: 'Record Cough\n& Breathing',
            subtitle: 'Record your cough or\ntake a breathing test',
            buttonText: 'Start Recording',
            icon: Icons.mic_rounded,
            cardBgColor: const Color(0xFFF4FAEB),
            borderColor: AppColors.primary.withValues(alpha: 0.22),
            buttonColor: AppColors.primary,
            iconColor: AppColors.primary,
            bgDecorationIconLeft: Icons.graphic_eq_rounded,
            bgDecorationIconRight: Icons.graphic_eq_rounded,
            onTap: () async {
              await context.push('/record');
              if (mounted) {
                // After recording, fetch fresh score from GET /score/latest
                context.read<WellnessBloc>().add(const WellnessFetchScoreEvent());
              }
            },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildQuickActionCard(
            title: 'Daily Log\nSymptoms',
            subtitle: 'Log your symptoms\nand how you feel',
            buttonText: 'Log Symptoms',
            icon: Icons.assignment_turned_in_outlined,
            cardBgColor: const Color(0xFFE9F7F8),
            borderColor: AppColors.secondary.withValues(alpha: 0.22),
            buttonColor: AppColors.secondary,
            iconColor: AppColors.secondary,
            bgDecorationIconLeft: Icons.eco_outlined,
            bgDecorationIconRight: Icons.chat_bubble_outline_rounded,
            onTap: () async {
              await context.push('/daily-log');
              if (mounted) {
                // After symptom log, fetch fresh score from GET /score/latest
                context.read<WellnessBloc>().add(const WellnessFetchScoreEvent());
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required String buttonText,
    required IconData icon,
    required Color cardBgColor,
    required Color borderColor,
    required Color buttonColor,
    required Color iconColor,
    required IconData bgDecorationIconLeft,
    required IconData bgDecorationIconRight,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(24.0),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Column(
          children: [
            // Top Header Graphic with Circle Icon & Decorative Background Accents
            SizedBox(
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    left: 6,
                    child: Icon(
                      bgDecorationIconLeft,
                      size: 26,
                      color: iconColor.withValues(alpha: 0.16),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    child: Icon(
                      bgDecorationIconRight,
                      size: 26,
                      color: iconColor.withValues(alpha: 0.16),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: iconColor, size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Main Card Title
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.text,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 8),

            // Card Description Subtitle
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11.5,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),

            // Bottom Full-Width Pill Action Button
            Container(
              width: double.infinity,
              height: 42,
              decoration: BoxDecoration(
                color: buttonColor,
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    buttonText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ],
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
