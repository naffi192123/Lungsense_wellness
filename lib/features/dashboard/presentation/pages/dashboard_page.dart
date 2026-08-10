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
                    const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 24),
                  ],
                ),
                const SizedBox(height: 24),

                // Lungs Health Score Circular Dial Card
                _buildLungsHealthScoreCard(latestScore),
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
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      day = "${months[time.month - 1]} ${time.day}";
    }

    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minuteStr = time.minute.toString().padLeft(2, '0');
    return "$day, $hour:$minuteStr $period";
  }

  Widget _buildRecordTabPlaceholder() {
    return const SizedBox.shrink();
  }
}

/// Continuous smooth auto-scrolling respiratory daily tips carousel.
class _DailyTipsCarousel extends StatefulWidget {
  const _DailyTipsCarousel();

  @override
  State<_DailyTipsCarousel> createState() => _DailyTipsCarouselState();
}

class _DailyTipsCarouselState extends State<_DailyTipsCarousel> {
  late final PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, dynamic>> _tips = const [
    {
      'title': 'Deep Diaphragmatic Breathing',
      'desc': 'Inhale slowly through your nose for 4 seconds, feeling your belly expand. Exhale gently through pursed lips for 6 seconds.',
      'icon': Icons.air_rounded,
      'color': AppColors.primary,
    },
    {
      'title': 'Hydration Keeps Airways Clear',
      'desc': 'Drinking 2 to 2.5 liters of water daily thins mucus secretions in the respiratory tract and eases bronchial airflow.',
      'icon': Icons.local_drink_rounded,
      'color': AppColors.supportingGreen,
    },
    {
      'title': 'Posture & Airflow Expansion',
      'desc': 'Sitting or standing tall opens the thoracic cavity, allowing your lungs to expand fully and receive up to 15% more oxygen.',
      'icon': Icons.accessibility_new_rounded,
      'color': AppColors.secondary,
    },
    {
      'title': 'Monitor Indoor Air Quality',
      'desc': 'Ventilate living spaces regularly and avoid artificial aerosols or dust accumulation to protect sensitive airways.',
      'icon': Icons.wb_sunny_outlined,
      'color': AppColors.primary,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92);
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
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
        onPageChanged: (index) => setState(() => _currentPage = index),
        itemBuilder: (context, index) {
          final tip = _tips[index];
          final color = tip['color'] as Color;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(tip['icon'] as IconData, color: color, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tip['title'] as String,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tip['desc'] as String,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
