import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../bloc/wellness_bloc.dart';
import '../bloc/wellness_event.dart';
import '../bloc/wellness_state.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../onboarding/domain/entities/wellness_entities.dart';

/// The central premium dashboard screen managing bottom navigation tabs.
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
    // Load local storage check-in and recording details
    context.read<WellnessBloc>().add(const WellnessFetchDataEvent());
  }

  @override
  Widget build(BuildContext context) {
    // List of embedded page widgets corresponding to bottom navigation tabs
    final List<Widget> tabs = [
      _buildHomeTab(),
      _buildRecordTabPlaceholder(),
      const HistoryPage(),
      _buildAnalyticsTabPlaceholder(),
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
            // "Record" button redirects immediately to the new RecordPage recording workflow
            context.go('/record');
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
    final authState = context.read<AuthBloc>().state;
    String name = 'User';
    if (authState is AuthAuthenticated) {
      if (authState.user.name != null && authState.user.name!.isNotEmpty) {
        name = authState.user.name!.split(' ').first;
      } else {
        name = authState.user.email.split('@').first;
      }
    }

    return BlocBuilder<WellnessBloc, WellnessState>(
      builder: (context, state) {
        int lungsScore = 92;
        String coughStatus = 'Normal';
        String breathing = 'High';
        String weeklyTrend = '+5%';
        List<AudioAnalysisEntity> recentActivities = state.audioAnalyses;

        if (recentActivities.isNotEmpty) {
          final latest = recentActivities.first;
          lungsScore = latest.lungsScore;
          coughStatus = latest.intensity == 'Low' ? 'Mild' : (latest.intensity == 'Moderate' ? 'Normal' : latest.intensity);
          breathing = latest.breathingRate > 17 ? 'High' : 'Normal';
        }

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
                            Text(
                              'Good Morning',
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
                _buildLungsHealthScoreCard(lungsScore),
                const SizedBox(height: 24),

                // Metrics Grid
                _buildMetricsGrid(coughStatus, breathing, weeklyTrend),
                const SizedBox(height: 28),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
                ),
                const SizedBox(height: 16),
                _buildQuickActionsGrid(),
                const SizedBox(height: 28),

                // Daily Tip Card
                _buildDailyTipCard(),
                const SizedBox(height: 28),

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
                _buildRecentActivityList(recentActivities),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLungsHealthScoreCard(int score) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.text.withOpacity(0.01),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
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
                  value: score / 100.0,
                  strokeWidth: 10,
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.supportingGreen),
                ),
              ),
              Column(
                children: [
                  Text(
                    '$score',
                    style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppColors.text),
                  ),
                  const Text(
                    'EXCELLENT',
                    style: TextStyle(fontSize: 10, color: AppColors.supportingGreen, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
              Positioned(
                right: 0,
                top: 0,
                child: Icon(Icons.wind_power_outlined, color: AppColors.border.withOpacity(0.5), size: 36),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Lungs Health Score',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
          ),
          const SizedBox(height: 6),
          Text(
            'Your respiratory system is functioning optimally today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(String cough, String breathing, String trend) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildMetricTile('Cough Status', cough, Icons.medical_services_outlined, AppColors.supportingGreen),
        _buildMetricTile('Breathing', breathing, Icons.waves_rounded, AppColors.secondary),
        _buildMetricTile('Lifestyle', '88', Icons.insights_rounded, AppColors.primary),
        _buildMetricTile('Weekly Trend', trend, Icons.trending_up_rounded, AppColors.supportingGreen),
      ],
    );
  }

  Widget _buildMetricTile(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 20),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.6,
      children: [
        GestureDetector(
          onTap: () => context.go('/record'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.supportingGreen,
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mic_rounded, color: AppColors.surface, size: 28),
                SizedBox(height: 8),
                Text(
                  'Record Cough',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.surface, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/record'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: AppColors.supportingGreen),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.air_rounded, color: AppColors.supportingGreen, size: 28),
                SizedBox(height: 8),
                Text(
                  'Record Breathing',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.supportingGreen, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => context.go('/daily-log'),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.edit_note_rounded, color: AppColors.primary, size: 28),
                SizedBox(height: 8),
                Text(
                  'Log Symptoms',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
        GestureDetector(
          onTap: () => setState(() => _currentTabIndex = 2), // Jump to History
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.secondary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, color: AppColors.secondary, size: 28),
                SizedBox(height: 8),
                Text(
                  'View History',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDailyTipCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F8), // Light cyan backdrop
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.secondary.withOpacity(0.15),
            child: const Icon(Icons.lightbulb_outline_rounded, color: AppColors.secondary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Tip',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try 5 mins of box breathing today to improve lung capacity and reduce stress.',
                  style: TextStyle(color: AppColors.text.withOpacity(0.8), fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Text(
                      'Start Exercise',
                      style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.secondary, fontSize: 12),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, color: AppColors.secondary, size: 14),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivityList(List<AudioAnalysisEntity> list) {
    if (list.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24.0),
        child: Center(child: Text('No recent activities logged.')),
      );
    }

    final displayList = list.take(2).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: displayList.length,
      itemBuilder: (context, index) {
        final item = displayList[index];
        final isGood = item.lungsScore >= 90;
        final iconColor = isGood ? AppColors.supportingGreen : AppColors.secondary;
        final iconData = isGood ? Icons.mic_none_outlined : Icons.waves_rounded;

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
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: iconColor.withOpacity(0.1),
                    child: Icon(iconData, color: iconColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.type == 'Cough' ? 'Cough Analysis' : 'Breathing Test',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatShortTime(item.timestamp),
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(fontWeight: FontWeight.bold, color: iconColor, fontSize: 13),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.type == 'Cough' ? 'Confidence ${item.confidence}%' : '${item.lungsScore}/100',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
    return const Center(child: Text('Record Audio...'));
  }

  Widget _buildAnalyticsTabPlaceholder() {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: false,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.text,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16.0),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'Lung Wellness Trends',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Weekly lung score and symptom analytics tracking charts will be displayed here in a future update.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
