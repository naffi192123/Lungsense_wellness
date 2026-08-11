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
    // Fetch and synchronize real user data from backend
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
            context.push('/record');
            return;
          }
          setState(() {
            _currentTabIndex = index;
          });
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
        final latestScore = state.latestScore?.score ??
            (state.scoreHistory.isNotEmpty ? state.scoreHistory.first.score : null);

        final recentAudio = state.audioAnalyses;

        return SafeArea(
          child: SingleChildScrollView(
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
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 24),
                      onPressed: () {
                        context.read<WellnessBloc>().add(const WellnessFetchDataEvent());
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Lungs Health Score Circular Dial Card
                _buildLungsHealthScoreCard(latestScore),
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
        );
      },
    );
  }

  Widget _buildLungsHealthScoreCard(int? score) {
    final hasScore = score != null && score > 0;
    final displayScore = hasScore ? score : 0;
    final statusText = hasScore
        ? (displayScore >= 80 ? 'EXCELLENT' : (displayScore >= 60 ? 'FAIR' : 'ATTENTION'))
        : 'NO SCORE YET';
    final statusColor = hasScore
        ? (displayScore >= 80 ? AppColors.supportingGreen : (displayScore >= 60 ? AppColors.secondary : AppColors.error))
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
                  value: hasScore ? (displayScore / 100.0) : 0.0,
                  strokeWidth: 10,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    hasScore ? '$displayScore' : '--',
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
                ? 'Score computed from your latest symptom and acoustic screening.'
                : 'Complete your symptom check-in and audio recordings to compute today\'s score.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildFourScoreCards(WellnessState state) {
    // 1. Cough Score
    int? coughScore = _extractBreakdownScore(state.latestScore?.breakdown, ['C', 'cough_score', 'cough']);
    if (coughScore == null && state.audioAnalyses.isNotEmpty) {
      final coughAudio = state.audioAnalyses.where((a) => a.type.toLowerCase() == 'cough').firstOrNull;
      if (coughAudio != null) {
        coughScore = coughAudio.lungsScore;
      }
    }

    // 2. Breathing Score
    int? breathingScore = _extractBreakdownScore(state.latestScore?.breakdown, ['B', 'breathing_score', 'breathing']);
    if (breathingScore == null && state.audioAnalyses.isNotEmpty) {
      final breathingAudio = state.audioAnalyses.where((a) => a.type.toLowerCase() == 'breathing').firstOrNull;
      if (breathingAudio != null) {
        breathingScore = breathingAudio.lungsScore;
      }
    }

    // 3. Symptom Score
    int? symptomScore = _extractBreakdownScore(state.latestScore?.breakdown, ['S', 'symptom_score', 'symptom']);
    if (symptomScore == null && state.dailyLogs.isNotEmpty) {
      final latestLog = state.dailyLogs.first;
      final sumSymptoms = latestLog.breathlessness +
          latestLog.activityLimitation +
          latestLog.changeFromUsual +
          latestLog.fever +
          latestLog.chestTightness +
          latestLog.chestDiscomfortBreathing +
          latestLog.wheezing +
          latestLog.coughSeverity +
          latestLog.mucus +
          latestLog.sleepDisruption +
          latestLog.chestPain;
      final scoreVal = (100 - (sumSymptoms / 44.0 * 100)).clamp(0, 100).round();
      symptomScore = scoreVal;
    }

    // 4. Heart Score
    int? heartScore = _extractBreakdownScore(state.latestScore?.breakdown, ['heart_score', 'heart_rate_score', 'H']);
    if (heartScore == null && state.audioAnalyses.isNotEmpty) {
      final rate = state.audioAnalyses.first.breathingRate;
      if (rate > 0) {
        if (rate >= 12 && rate <= 20) {
          heartScore = 90;
        } else if (rate >= 10 && rate <= 24) {
          heartScore = 75;
        } else {
          heartScore = 60;
        }
      }
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
                score: coughScore,
                icon: Icons.sick_outlined,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Breathing Score',
                score: breathingScore,
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
                score: symptomScore,
                icon: Icons.assignment_turned_in_outlined,
                color: Colors.amber.shade800,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                title: 'Heart Score',
                score: heartScore,
                icon: Icons.favorite_rounded,
                color: Colors.redAccent,
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
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.textSecondary),
              ),
              Icon(icon, size: 20, color: color),
            ],
          ),
          const SizedBox(height: 12),
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
        ],
      ),
    );
  }

  int? _extractBreakdownScore(Map<String, dynamic>? breakdown, List<String> keys) {
    if (breakdown == null) return null;
    for (final k in keys) {
      if (breakdown.containsKey(k) && breakdown[k] != null) {
        final val = breakdown[k];
        if (val is num && val > 0) return val.round();
      }
    }
    return null;
  }

  Widget _buildQuickActionsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildActionTile(
            title: 'Record Audio',
            subtitle: 'Cough & Breathing',
            icon: Icons.mic_none_outlined,
            color: AppColors.primary,
            onTap: () => context.push('/record'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionTile(
            title: 'Daily Log',
            subtitle: 'Check symptoms',
            icon: Icons.edit_note_rounded,
            color: AppColors.supportingGreen,
            onTap: () => context.push('/daily-log'),
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
              backgroundColor: color.withOpacity(0.12),
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
                      backgroundColor: iconColor.withOpacity(0.12),
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

/// Continuous Auto-Scrolling Respiratory Tips Carousel
class _DailyTipsCarousel extends StatefulWidget {
  const _DailyTipsCarousel();

  @override
  State<_DailyTipsCarousel> createState() => _DailyTipsCarouselState();
}

class _DailyTipsCarouselState extends State<_DailyTipsCarousel> {
  final PageController _pageController = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _currentPage = 0;

  final List<Map<String, String>> _tips = const [
    {
      'title': 'Pursed-Lip Breathing',
      'body': 'Inhale slowly through your nose for 2 counts, then breathe out gently through pursed lips for 4 counts to keep airways open.',
      'tag': 'Exercise',
    },
    {
      'title': 'Stay Hydrated',
      'body': 'Drinking 2+ liters of water daily thins mucus secretions, making it easier for your lungs to clear irritants.',
      'tag': 'Hydration',
    },
    {
      'title': 'Diaphragmatic Breathing',
      'body': 'Place one hand on your belly. Breathe deeply so your belly rises more than your chest. Strengthens diaphragm capacity.',
      'tag': 'Wellness',
    },
    {
      'title': 'Monitor Air Quality',
      'body': 'Check local AQI before outdoor workouts. Avoid exercising near heavy traffic during peak pollution hours.',
      'tag': 'Environment',
    },
    {
      'title': 'Consistent Sleep Rest',
      'body': '7-8 hours of sleep allows bronchial tissues to repair and supports stronger immune defense against respiratory infections.',
      'tag': 'Sleep',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoScroll();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        _currentPage = (_currentPage + 1) % _tips.length;
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
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
    return SizedBox(
      height: 120,
      child: PageView.builder(
        controller: _pageController,
        itemCount: _tips.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          final tip = _tips[index];
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.08),
                  AppColors.supportingGreen.withOpacity(0.06),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      tip['title']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tip['tag']!,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tip['body']!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
