import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../models/report_model.dart';

/// Small pill showing a report's status: tinted background, colored dot,
/// text label (so color is never the only signal).
class StatusBadge extends StatelessWidget {
  final ReportStatus status;

  const StatusBadge({super.key, required this.status});

  /// Single place that maps a status to its color.
  static Color colorFor(ReportStatus status) {
    switch (status) {
      case ReportStatus.submitted:
        return AppColors.submitted;
      case ReportStatus.underReview:
        return AppColors.underReview;
      case ReportStatus.inProgress:
        return AppColors.inProgress;
      case ReportStatus.resolved:
        return AppColors.resolved;
    }
  }

  // In dark mode the base colors are too dim against dark surfaces, so they are lightened to stay readable.
  static Color textColorFor(BuildContext context, ReportStatus status) {
    final color = colorFor(status);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? Color.lerp(color, Colors.white, 0.4)! : color;
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(status);
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: AppSpacing.sm,
            height: AppSpacing.sm,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            status.label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
