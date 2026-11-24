import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/history_bloc.dart';
import '../bloc/history_event.dart';
import '../bloc/history_state.dart';
import '../../domain/entities/history_entry.dart';

/// Screen listing consolidated historical activities (grouped by activity_id)
/// fetched from the GET /history API endpoint.
class HistoryPage extends StatelessWidget {
  final VoidCallback? onBack;

  const HistoryPage({super.key, this.onBack});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header details with Back Navigation
              _buildHeader(context),

              // Content Area powered by History API
              Expanded(
                child: BlocBuilder<HistoryBloc, HistoryState>(
                  bloc: sl.isRegistered<HistoryBloc>() ? sl<HistoryBloc>() : null,
                  builder: (context, state) {
                    if (state.status == HistoryStatus.loading && state.entries.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.primary),
                      );
                    }

                    if (state.entries.isEmpty) {
                      return RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          if (sl.isRegistered<HistoryBloc>()) {
                            sl<HistoryBloc>().add(const HistoryRefreshEvent());
                          }
                        },
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                                child: _buildEmptyState(context),
                              ),
                            );
                          },
                        ),
                      );
                    }

                    return RefreshIndicator(
                      color: AppColors.primary,
                      onRefresh: () async {
                        if (sl.isRegistered<HistoryBloc>()) {
                          sl<HistoryBloc>().add(const HistoryRefreshEvent());
                        }
                      },
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                        itemCount: state.entries.length,
                        itemBuilder: (context, index) {
                          return _buildTimelineItem(context, state.entries[index]);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleBack(BuildContext context) {
    if (onBack != null) {
      onBack!();
    } else if (Navigator.of(context).canPop()) {
      context.pop();
    } else {
      context.go('/dashboard?tab=0');
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.text, size: 24),
            onPressed: () => _handleBack(context),
          ),
          const SizedBox(width: 4),
          Text(
            'History',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                ),
          ),
          const Spacer(),
          const Icon(Icons.notifications_none_rounded, color: AppColors.textSecondary, size: 24),
        ],
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
              child: const Icon(
                Icons.history_toggle_off_rounded,
                size: 56,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No history yet',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your recordings, symptom logs, and wellness activities will appear here once you start using the app.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, HistoryEntry entry) {
    IconData icon;
    Color iconColor;

    if (entry.hasCough && entry.hasBreathing) {
      icon = Icons.health_and_safety_outlined;
      iconColor = AppColors.primary;
    } else if (entry.hasCough) {
      icon = Icons.mic_none_rounded;
      iconColor = AppColors.primary;
    } else if (entry.hasBreathing) {
      icon = Icons.air_rounded;
      iconColor = AppColors.secondary;
    } else if (entry.hasSymptom) {
      icon = Icons.fact_check_outlined;
      iconColor = AppColors.supportingGreen;
    } else {
      icon = Icons.history_rounded;
      iconColor = AppColors.textSecondary;
    }

    final isComplete = entry.overallStatus.toLowerCase() == 'complete';
    final statusColor = isComplete ? AppColors.supportingGreen : AppColors.error;

    // Extract any score if available across records
    int? score;
    for (final r in entry.records) {
      if (r.results != null) {
        final rawScore = r.results!['score'] ??
            r.results!['quality_score'] ??
            r.results!['lung_wellness_score'];
        if (rawScore is num && rawScore > 0) {
          final s = rawScore.round();
          score = s <= 1 ? (rawScore * 100).round() : s;
          break;
        }
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        leading: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.text),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              entry.subtitle,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(entry.latestTimestamp),
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (score != null) ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.supportingGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$score',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.supportingGreen),
                ),
              ),
            ] else ...[
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  entry.overallStatus.toUpperCase(),
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: statusColor),
                ),
              ),
            ],
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textSecondary),
          ],
        ),
        onTap: () {
          context.push('/history-details', extra: {
            'logType': 'consolidated',
            'itemData': entry,
          });
        },
      ),
    );
  }

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time).inDays;

    String dateStr = '';
    if (difference == 0) {
      dateStr = 'Today';
    } else if (difference == 1) {
      dateStr = 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      dateStr = "${months[time.month - 1]} ${time.day}";
    }

    final period = time.hour >= 12 ? 'PM' : 'AM';
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minuteStr = time.minute.toString().padLeft(2, '0');

    return "$dateStr, $hour:$minuteStr $period";
  }
}
