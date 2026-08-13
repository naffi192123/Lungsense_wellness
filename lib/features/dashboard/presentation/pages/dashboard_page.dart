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
    // Read score directly from backend latest score — single source of truth
    final scoreEntity = state.latestScore ??
        (state.scoreHistory.isNotEmpty ? state.scoreHistory.first : null);
    int? displayScore = (scoreEntity?.score ?? 0) > 0 ? scoreEntity!.score : null;

    if (displayScore == null && state.componentScores.isNotEmpty) {
      final validComps = state.componentScores.values.where((v) => v > 0).toList();
      if (validComps.isNotEmpty) {
        displayScore = (validComps.reduce((a, b) => a + b) / validComps.length).round();
      }
    }

    final scoreTime = scoreEntity?.timestamp ??
        (state.dailyLogs.isNotEmpty ? state.dailyLogs.first.timestamp : (state.audioAnalyses.isNotEmpty ? state.audioAnalyses.first.timestamp : null));
    final trendScore = state.trendScore; // T component from backend breakdown
    final baselineMsg = (state.baselineStatus?['message'] as String?);

    final hasScore = displayScore != null;
    final finalScoreVal = hasScore ? displayScore : 0;
    final statusText = hasScore
        ? (finalScoreVal >= 80 ? 'EXCELLENT' : (finalScoreVal >= 60 ? 'FAIR' : 'ATTENTION'))
        : 'NO SCORE YET';
    final statusColor = hasScore
        ? (finalScoreVal >= 80
            ? AppColors.supportingGreen
            : (finalScoreVal >= 60 ? AppColors.secondary : AppColors.error))
        : AppColors.textSecondary;

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
                  value: hasScore ? (finalScoreVal / 100.0) : 0.0,
                  strokeWidth: 10,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    hasScore ? '$finalScoreVal' : '--',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.text),
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
            hasScore
                ? (scoreEntity?.message ?? 'Score computed from your latest symptom and acoustic screening.')
                : 'Complete your symptom check-in and audio recordings to compute today\'s score.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          // Trend Score chip — shown when T component is available from backend
          if (trendScore != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.trending_up_rounded, size: 15, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Trend Score: $trendScore',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Baseline initializing message
          if (!hasScore && baselineMsg != null) ...[
            const SizedBox(height: 10),
            Text(
              baselineMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
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
    // All four component scores read directly from backend breakdown (C/B/S/T)
    // Populated by WellnessBloc._parseComponentScores after GET /score/latest
    final scoreTime = state.latestScore?.timestamp;

    // Fallback timestamps from individual recordings/logs when available
    DateTime? coughTime = scoreTime;
    DateTime? breathingTime = scoreTime;
    DateTime? symptomTime = scoreTime;
    if (state.audioAnalyses.isNotEmpty) {
      final coughAudio = state.audioAnalyses.where((a) => a.type.toLowerCase() == 'cough').firstOrNull;
      if (coughAudio != null) coughTime = coughAudio.timestamp;
      final breathAudio = state.audioAnalyses.where((a) => a.type.toLowerCase() == 'breathing').firstOrNull;
      if (breathAudio != null) breathingTime = breathAudio.timestamp;
    }
    if (state.dailyLogs.isNotEmpty) {
      symptomTime = state.dailyLogs.first.timestamp;
    }

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
                timestamp: coughTime,
                icon: Icons.sick_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Breathing Score',
                score: state.breathingScore,
                timestamp: breathingTime,
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
                timestamp: symptomTime,
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
  }) {
    final hasScore = score != null && score > 0;
    final statusText = hasScore
        ? (score >= 80 ? 'Optimal' : (score >= 60 ? 'Fair' : 'Attention'))
        : 'No logs yet';
    final statusColor = hasScore
        ? (score >= 80 ? AppColors.supportingGreen : (score >= 60 ? AppColors.secondary : AppColors.error))
        : AppColors.textSecondary;

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
      children: [
        Expanded(
          child: _buildActionTile(
            title: 'Record Audio',
            subtitle: 'Cough & Breathing',
            icon: Icons.mic_none_outlined,
            color: AppColors.primary,
            onTap: () async {
              await context.push('/record');
              if (mounted) {
                // After recording, fetch fresh score from GET /score/latest
                context.read<WellnessBloc>().add(const WellnessFetchScoreEvent());
              }
            },
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionTile(
            title: 'Daily Log',
            subtitle: 'Check symptoms',
            icon: Icons.edit_note_rounded,
            color: AppColors.supportingGreen,
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

  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.0),
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
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
