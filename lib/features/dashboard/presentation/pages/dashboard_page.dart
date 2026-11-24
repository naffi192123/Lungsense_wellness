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
import '../../../history/presentation/bloc/history_bloc.dart';
import '../../../history/presentation/bloc/history_event.dart';
import '../../../history/presentation/bloc/history_state.dart';
import '../../../history/domain/entities/history_entry.dart';

/// The central dashboard screen managing navigation tabs and real health metrics.
class DashboardPage extends StatefulWidget {
  final int initialTab;
  const DashboardPage({super.key, this.initialTab = 0});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late int _currentTabIndex;
  final List<int> _tabHistory = [0];

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTab;
    _tabHistory.clear();
    _tabHistory.add(widget.initialTab);
    // Full data fetch (score + logs + recordings + history) on app open
    context.read<WellnessBloc>().add(const WellnessFetchDataEvent());
    if (sl.isRegistered<HistoryBloc>()) {
      sl<HistoryBloc>().add(const HistoryFetchEvent());
    }
  }

  void _handleBackNavigation() {
    if (_tabHistory.length > 1) {
      _tabHistory.removeLast();
      setState(() {
        _currentTabIndex = _tabHistory.last;
      });
    } else if (_currentTabIndex != 0) {
      _tabHistory.clear();
      _tabHistory.add(0);
      setState(() {
        _currentTabIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = [
      _buildHomeTab(),
      _buildRecordTabPlaceholder(),
      HistoryPage(onBack: _handleBackNavigation),
      const AnalyticsPage(),
      const ProfilePage(),
    ];

    return PopScope(
      canPop: _currentTabIndex == 0 && _tabHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
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
              final historyBloc = context.read<HistoryBloc>();
              context.push('/daily-checkin').then((_) {
                if (mounted) {
                  // After check-in, fetch fresh data and refresh analytics & history
                  wellnessBloc.add(const WellnessFetchDataEvent());
                  analyticsBloc.add(const AnalyticsLoadEvent());
                  historyBloc.add(const HistoryRefreshEvent());
                }
              });
              return;
            }
            if (_currentTabIndex != index) {
              _tabHistory.add(index);
              setState(() {
                _currentTabIndex = index;
              });
            }
            if (index == 0) {
              // Navigating to Home tab — lightweight score refresh + history refresh
              context.read<WellnessBloc>().add(const WellnessFetchScoreEvent());
              if (sl.isRegistered<HistoryBloc>()) {
                sl<HistoryBloc>().add(const HistoryRefreshEvent());
              }
            } else if (index == 2) {
              // History tab needs full data
              context.read<WellnessBloc>().add(const WellnessFetchDataEvent());
              if (sl.isRegistered<HistoryBloc>()) {
                sl<HistoryBloc>().add(const HistoryRefreshEvent());
              }
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
            icon: Icon(Icons.health_and_safety_outlined),
            activeIcon: Icon(Icons.health_and_safety),
            label: 'Daily Check-in',
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
    ),
  );
}

  Widget _buildHomeTab() {
    final authState = context.watch<AuthBloc>().state;
    final cachedName =
        sl.isRegistered<ApiClient>() ? sl<ApiClient>().userName : null;
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
        final isLoading = state.status == WellnessStatus.loading ||
            state.status == WellnessStatus.scoreLoading;

        return SafeArea(
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              // Pull-to-refresh fetches latest score and fresh history
              context.read<WellnessBloc>().add(const WellnessFetchScoreEvent());
              if (sl.isRegistered<HistoryBloc>()) {
                sl<HistoryBloc>().add(const HistoryRefreshEvent());
              }
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
                                // Manual refresh — fetch fresh data, score, and analytics
                                context.read<WellnessBloc>().add(const WellnessFetchDataEvent());
                                context.read<AnalyticsBloc>().add(const AnalyticsLoadEvent());
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Quick Actions (placed immediately after Welcome Back)
                  const Text(
                    'Quick Actions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.text),
                  ),
                  const SizedBox(height: 14),
                  if (sl.isRegistered<HistoryBloc>())
                    BlocBuilder<HistoryBloc, HistoryState>(
                      bloc: sl<HistoryBloc>(),
                      builder: (context, historyState) {
                        return _buildQuickActionsGrid(state, historyState);
                      },
                    )
                  else
                    _buildQuickActionsGrid(state),
                  const SizedBox(height: 24),

                  // Wellness Scorecard (Lungs Health Score Circular Dial Card)
                  _buildLungsHealthScoreCard(state),
                  const SizedBox(height: 20),

                  // Health Score Breakdown (4 Specific Health Score Breakdown Cards)
                  _buildFourScoreCards(state),
                  const SizedBox(height: 24),

                  // Continuous Auto-Scrolling Daily Tips Section
                  const Text(
                    'Daily Respiratory Wellness Tips',
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
                          if (_currentTabIndex != 2) {
                            _tabHistory.add(2);
                            setState(() {
                              _currentTabIndex = 2; // Jump to History tab
                            });
                          }
                        },
                        child: const Text(
                          'See all',
                          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (sl.isRegistered<HistoryBloc>())
                    BlocBuilder<HistoryBloc, HistoryState>(
                      bloc: sl<HistoryBloc>(),
                      builder: (context, historyState) {
                        return _buildRecentActivityList(historyState.recentActivities);
                      },
                    )
                  else
                    _buildRecentActivityList(const []),
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

    // Display score as whole number
    final scoreStr = hasScore
        ? lungWellnessScore.round().toString()
        : '--';

    final String messageText;
    if (!hasScore) {
      messageText = 'Complete today’s symptom check-in and cough and breathing recordings to generate your score';
    } else {
      final rawMsg = scoreEntity?.message;
      if (rawMsg != null &&
          rawMsg.isNotEmpty &&
          !rawMsg.toLowerCase().contains('no score') &&
          !rawMsg.toLowerCase().contains('score computed fresh')) {
        messageText = rawMsg;
      } else {
        messageText = 'Today\'s check-in is complete! Your respiratory wellness score has been calculated and updated.';
      }
    }

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
            messageText,
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
                icon: Icons.mic,
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
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                child: _buildBaselineCard(state),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBaselineCard(WellnessState state) {
    final baselineVal = state.baselineValue;
    final hasBaseline = baselineVal != null && baselineVal > 0;

    final statusText = hasBaseline
        ? (state.baselineStatusText ?? 'Active')
        : (state.baselineStatusText == 'Forming' || state.baselineStatusText == null
            ? 'Building'
            : state.baselineStatusText!);

    final statusColor = hasBaseline
        ? AppColors.supportingGreen
        : AppColors.secondary;

    final String displayMessage;
    if (hasBaseline) {
      displayMessage = state.baselineMessage ?? 'Personal baseline active and updating.';
    } else {
      final rawMsg = state.baselineMessage;
      displayMessage = (rawMsg != null &&
              rawMsg.isNotEmpty &&
              !rawMsg.toLowerCase().contains('trend') &&
              !rawMsg.toLowerCase().contains('few sessions') &&
              !rawMsg.toLowerCase().contains('available after'))
          ? rawMsg
          : 'Complete check-ins on at least seven separate days.';
    }

    final String displayValue;
    if (hasBaseline) {
      displayValue = baselineVal.round().toString();
    } else {
      displayValue = '';
    }

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
              const Expanded(
                child: Text(
                  'Baseline',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.tune_rounded,
                size: 20,
                color: hasBaseline ? Colors.teal.shade700 : AppColors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasBaseline) ...[
            Text(
              displayValue,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: AppColors.text,
              ),
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              displayMessage,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ] else ...[
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
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              displayMessage,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppColors.textSecondary,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required int? score,
    required DateTime? timestamp,
    required IconData icon,
    required Color color,
    String? customStatusText,
    String? customSubtitle,
  }) {
    final hasScore = score != null && score > 0;

    final statusText = customStatusText ??
        (hasScore
            ? (score >= 80 ? 'Optimal' : (score >= 60 ? 'Fair' : 'Attention'))
            : 'Not recorded today');

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
              Expanded(
                child: Text(
                  statusText,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 11, color: statusColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (hasScore && timestamp != null) ...[
            const SizedBox(height: 6),
            Text(
              customSubtitle ?? _formatScoreTimestamp(timestamp),
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ] else if (customSubtitle != null && customSubtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              customSubtitle,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  String _formatScoreTimestamp(DateTime? timestamp) {
    if (timestamp == null) return 'Not recorded today';
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

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isCheckinCompletedToday(WellnessState state, [HistoryState? historyState]) {
    final now = DateTime.now();

    // 1. Check from WellnessState activity records
    final hasTodayLog = state.dailyLogs.any((l) => _isSameDay(l.timestamp.toLocal(), now));
    final hasTodayCough = state.audioAnalyses.any((a) =>
        a.type.toLowerCase().contains('cough') &&
        a.status.toLowerCase() == 'complete' &&
        _isSameDay(a.timestamp.toLocal(), now));
    final hasTodayBreathing = state.audioAnalyses.any((a) =>
        a.type.toLowerCase().contains('breath') &&
        a.status.toLowerCase() == 'complete' &&
        _isSameDay(a.timestamp.toLocal(), now));

    // 2. Check from HistoryState (GET /history API records)
    bool historyHasCough = false;
    bool historyHasBreathing = false;
    bool historyHasSymptom = false;

    if (historyState != null && historyState.entries.isNotEmpty) {
      for (final entry in historyState.entries) {
        for (final r in entry.records) {
          if (_isSameDay(r.timestamp.toLocal(), now) && r.status.toLowerCase() == 'complete') {
            final t = r.type.toLowerCase();
            if (t.contains('cough')) historyHasCough = true;
            if (t.contains('breath')) historyHasBreathing = true;
            if (t.contains('symptom')) historyHasSymptom = true;
          }
        }
      }
    }

    final coughCompleted = hasTodayCough || historyHasCough;
    final breathingCompleted = hasTodayBreathing || historyHasBreathing;
    final symptomCompleted = hasTodayLog || historyHasSymptom;

    // Display this state ONLY when all three activities have been successfully completed today
    return coughCompleted && breathingCompleted && symptomCompleted;
  }

  Future<void> _openDailyCheckin() async {
    final wellnessBloc = context.read<WellnessBloc>();
    final analyticsBloc = context.read<AnalyticsBloc>();
    await context.push('/daily-checkin');
    if (mounted) {
      wellnessBloc.add(const WellnessFetchDataEvent());
      analyticsBloc.add(const AnalyticsLoadEvent());
      if (sl.isRegistered<HistoryBloc>()) {
        sl<HistoryBloc>().add(const HistoryRefreshEvent());
      }
    }
  }

  void _showAdditionalRecordingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
      ),
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: AppColors.supportingGreen, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Check-in Complete for Today',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.text,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your daily score is up to date. You can add extra audio recordings or retake check-in if needed:',
                  style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 16),
                _buildRecordingOptionTile(
                  icon: Icons.mic,
                  color: AppColors.primary,
                  title: 'Record Cough Sounds',
                  subtitle: '12-15 seconds voluntary cough analysis',
                  onTap: () async {
                    final wellnessBloc = context.read<WellnessBloc>();
                    final analyticsBloc = context.read<AnalyticsBloc>();
                    Navigator.pop(bottomSheetContext);
                    await context.push('/record?type=cough');
                    if (mounted) {
                      wellnessBloc.add(const WellnessFetchDataEvent());
                      analyticsBloc.add(const AnalyticsLoadEvent());
                      if (sl.isRegistered<HistoryBloc>()) {
                        sl<HistoryBloc>().add(const HistoryRefreshEvent());
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildRecordingOptionTile(
                  icon: Icons.air_rounded,
                  color: AppColors.supportingGreen,
                  title: 'Record Breathing Sounds',
                  subtitle: '25-30 seconds deep respiratory analysis',
                  onTap: () async {
                    final wellnessBloc = context.read<WellnessBloc>();
                    final analyticsBloc = context.read<AnalyticsBloc>();
                    Navigator.pop(bottomSheetContext);
                    await context.push('/record?type=breathing');
                    if (mounted) {
                      wellnessBloc.add(const WellnessFetchDataEvent());
                      analyticsBloc.add(const AnalyticsLoadEvent());
                      if (sl.isRegistered<HistoryBloc>()) {
                        sl<HistoryBloc>().add(const HistoryRefreshEvent());
                      }
                    }
                  },
                ),
                const SizedBox(height: 10),
                _buildRecordingOptionTile(
                  icon: Icons.replay_rounded,
                  color: AppColors.textSecondary,
                  title: 'Retake Full Daily Check-in',
                  subtitle: 'Repeat all 3 steps to update today\'s score',
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    await _openDailyCheckin();
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecordingOptionTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(14),
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
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.text),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsGrid(WellnessState state, [HistoryState? historyState]) {
    final isCompleted = _isCheckinCompletedToday(state, historyState);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (isCompleted) {
          _showAdditionalRecordingsSheet(context);
        } else {
          _openDailyCheckin();
        }
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isCompleted
                ? AppColors.supportingGreen.withValues(alpha: 0.35)
                : AppColors.border,
            width: isCompleted ? 1.4 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isCompleted
                  ? AppColors.supportingGreen.withValues(alpha: 0.08)
                  : AppColors.text.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Status Icon Circle Badge
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? AppColors.supportingGreen.withValues(alpha: 0.12)
                    : AppColors.primary.withValues(alpha: 0.10),
              ),
              child: Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.health_and_safety_rounded,
                color: isCompleted ? AppColors.supportingGreen : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // Content Information
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Flexible(
                        child: Text(
                          'Daily Check-in',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.text,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCompleted) ...[
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.check_circle_rounded,
                          size: 15,
                          color: AppColors.supportingGreen,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isCompleted ? 'All 3 steps completed today' : 'Daily Check-in Pending',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isCompleted ? AppColors.supportingGreen : AppColors.secondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    isCompleted
                        ? 'Tap to add more recordings anytime'
                        : "Complete 3 steps to get today's score.",
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      height: 1.25,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Action Button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompleted ? 12 : 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: isCompleted ? AppColors.supportingGreen : AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (isCompleted ? AppColors.supportingGreen : AppColors.primary)
                        .withValues(alpha: 0.25),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: isCompleted
                  ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 15),
                        SizedBox(width: 3),
                        Text(
                          'Record More',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    )
                  : const Text(
                      'Start',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityList(List<HistoryEntry> items) {
    if (items.isEmpty) {
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

    return Column(
      children: items.take(3).map((item) {
        IconData iconData;
        Color iconColor;

        if (item.hasCough && item.hasBreathing) {
          iconData = Icons.health_and_safety_outlined;
          iconColor = AppColors.primary;
        } else if (item.hasCough) {
          iconData = Icons.mic_rounded;
          iconColor = AppColors.primary;
        } else if (item.hasBreathing) {
          iconData = Icons.air_rounded;
          iconColor = AppColors.secondary;
        } else if (item.hasSymptom) {
          iconData = Icons.fact_check_outlined;
          iconColor = AppColors.supportingGreen;
        } else {
          iconData = Icons.history_rounded;
          iconColor = AppColors.textSecondary;
        }

        final isComplete = item.overallStatus.toLowerCase() == 'complete';
        final statusColor = isComplete ? AppColors.supportingGreen : AppColors.error;

        // Resolve score from record results if available
        int? resolvedScore;
        for (final r in item.records) {
          if (r.results != null) {
            final raw = r.results!['score'] ??
                r.results!['quality_score'] ??
                r.results!['lung_wellness_score'];
            if (raw is num && raw > 0) {
              final s = raw.round();
              resolvedScore = s <= 1 ? (raw * 100).round() : s;
              break;
            }
          }
        }

        final hasItemScore = resolvedScore != null && resolvedScore > 0;
        final displayColor = hasItemScore
            ? (resolvedScore >= 80
                ? AppColors.supportingGreen
                : (resolvedScore >= 60 ? AppColors.secondary : AppColors.error))
            : statusColor;

        return GestureDetector(
          onTap: () {
            context.push('/history-details', extra: {
              'logType': 'consolidated',
              'itemData': item,
            });
          },
          child: Container(
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
                              item.title,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatShortTime(item.latestTimestamp),
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
                      hasItemScore ? 'Score $resolvedScore' : (isComplete ? 'Completed' : 'Failed'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: displayColor, fontSize: 13),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.records.length > 1 ? '${item.records.length} records' : (isComplete ? 'Processed' : 'Failed'),
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
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
