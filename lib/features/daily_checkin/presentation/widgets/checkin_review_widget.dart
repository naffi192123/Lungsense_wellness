import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/daily_checkin_enums.dart';
import '../bloc/daily_checkin_state.dart';

class CheckinReviewWidget extends StatelessWidget {
  final DailyCheckinState state;
  final ValueChanged<CheckinStep> onReRecord;
  final VoidCallback onSubmit;
  final VoidCallback onRetry;

  const CheckinReviewWidget({
    super.key,
    required this.state,
    required this.onReRecord,
    required this.onSubmit,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final cough = state.coughResult;
    final breathing = state.breathingResult;
    final symptoms = state.symptomsResult;

    final isSubmitting = state.isSubmitting;
    final hasError = state.sessionStatus == CheckinSessionStatus.error &&
        state.errorMessage != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.assignment_turned_in_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Your Check-in',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.text,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Verify your captured data before finalizing.',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Error Banner (if any)
          if (hasError) ...[
            Container(
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(fontSize: 12.5, color: AppColors.text),
                    ),
                  ),
                  TextButton(
                    onPressed: onRetry,
                    child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 1. Cough Recording Card
          _buildSummaryCard(
            title: 'Cough Sound Recording',
            icon: Icons.sick_outlined,
            accentColor: AppColors.primary,
            onEdit: () => onReRecord(CheckinStep.cough),
            editLabel: 'Re-record',
            metrics: [
              _MetricItem('Status', cough != null ? 'Completed' : 'Missing', isHighlight: true),
              if (cough != null) ...[
                _MetricItem('Duration', '${cough.durationSeconds?.toStringAsFixed(1) ?? cough.duration}s'),
                if (cough.normalizedQualityScore != null)
                  _MetricItem('Quality', '${cough.normalizedQualityScore!.toStringAsFixed(1)}%'),
                if (cough.coughEventCount != null)
                  _MetricItem('Cough Events', '${cough.coughEventCount} detected'),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // 2. Breathing Recording Card
          _buildSummaryCard(
            title: 'Breathing Sound Recording',
            icon: Icons.air_rounded,
            accentColor: AppColors.secondary,
            onEdit: () => onReRecord(CheckinStep.breathing),
            editLabel: 'Re-record',
            metrics: [
              _MetricItem('Status', breathing != null ? 'Completed' : 'Missing', isHighlight: true),
              if (breathing != null) ...[
                _MetricItem('Duration', '${breathing.durationSeconds?.toStringAsFixed(1) ?? breathing.duration}s'),
                if (breathing.normalizedQualityScore != null)
                  _MetricItem('Quality', '${breathing.normalizedQualityScore!.toStringAsFixed(1)}%'),
                if (breathing.breathingRateBpm != null)
                  _MetricItem('Breathing Rate', '${breathing.breathingRateBpm!.toStringAsFixed(1)} BPM'),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // 3. Symptoms Log Card
          _buildSummaryCard(
            title: 'Daily Symptoms Log',
            icon: Icons.fact_check_outlined,
            accentColor: Colors.amber.shade800,
            onEdit: () => onReRecord(CheckinStep.symptoms),
            editLabel: 'Edit',
            metrics: [
              _MetricItem('Status', symptoms != null ? 'Logged' : 'Missing', isHighlight: true),
              if (symptoms != null) ...[
                _MetricItem('Breathlessness', '${symptoms.breathlessness.toInt()}/3'),
                _MetricItem('Cough Severity', '${symptoms.coughSeverity.toInt()}/3'),
                _MetricItem('Chest Tightness', '${symptoms.chestTightness.toInt()}/3'),
                _MetricItem('Wheezing', '${symptoms.wheezing.toInt()}/3'),
                _MetricItem('Mucus', '${symptoms.mucus.toInt()}/3'),
                _MetricItem('Fever', '${symptoms.fever.toInt()}/3'),
              ],
            ],
          ),
          const SizedBox(height: 32),

          // Complete Check-in Button
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.0),
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.supportingGreen],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isSubmitting ? null : onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.surface,
                shadowColor: Colors.transparent,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
              ),
              child: isSubmitting
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: AppColors.surface,
                            strokeWidth: 2,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Computing Wellness Score...',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Complete Check-in & Compute Score',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Finalizes your daily check-in session and calculates your updated score.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onEdit,
    required String editLabel,
    required List<_MetricItem> metrics,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.text,
                  ),
                ),
              ),
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      editLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: metrics.map((m) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: m.isHighlight
                      ? AppColors.supportingGreen.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: m.isHighlight
                        ? AppColors.supportingGreen.withValues(alpha: 0.3)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${m.label}: ',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: m.isHighlight
                            ? AppColors.supportingGreen
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      m.value,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: m.isHighlight
                            ? AppColors.supportingGreen
                            : AppColors.text,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _MetricItem {
  final String label;
  final String value;
  final bool isHighlight;

  _MetricItem(this.label, this.value, {this.isHighlight = false});
}
