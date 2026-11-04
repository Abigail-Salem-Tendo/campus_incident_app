import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../models/report_model.dart';
import 'status_badge.dart';

/// Horizontal row of single-select chips: All + one per status.
class StatusFilterBar extends StatelessWidget {
  final ReportStatus? selected; // null means "All"
  final ValueChanged<ReportStatus?> onChanged;

  const StatusFilterBar({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selected == null,
            onSelected: (_) => onChanged(null),
          ),
          for (final status in ReportStatus.values) ...[
            const SizedBox(width: AppSpacing.sm),
            ChoiceChip(
              avatar: Icon(
                Icons.circle,
                size: 12,
                color: StatusBadge.colorFor(status),
              ),
              label: Text(status.label),
              selected: selected == status,
              onSelected: (_) => onChanged(status),
            ),
          ],
        ],
      ),
    );
  }
}
