import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../models/report_model.dart';
import 'status_badge.dart';

/// Row of four compact tiles showing how many reports are in each status.
/// Tapping a tile selects that status as a filter; tapping it again clears it.
class StatusSummary extends StatelessWidget {
  final Map<ReportStatus, int> counts;
  final ReportStatus? selected;
  final ValueChanged<ReportStatus?> onChanged;

  const StatusSummary({
    super.key,
    required this.counts,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final statuses = ReportStatus.values;

    return Row(
      children: [
        for (var i = 0; i < statuses.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _SummaryTile(
              status: statuses[i],
              count: counts[statuses[i]] ?? 0,
              isSelected: selected == statuses[i],
              onTap: () =>
                  onChanged(selected == statuses[i] ? null : statuses[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final ReportStatus status;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _SummaryTile({
    required this.status,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = StatusBadge.colorFor(status);
    final textColor = StatusBadge.textColorFor(context, status);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        side: BorderSide(
          color: isSelected ? color : theme.colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$count',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  status.label,
                  maxLines: 1,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
