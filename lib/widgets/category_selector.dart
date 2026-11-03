import 'package:flutter/material.dart';

import '../models/report_model.dart';

class CategorySelector extends StatelessWidget {
  final ReportCategory? selected;
  final ValueChanged<ReportCategory> onChanged;
  final String? errorText;

  const CategorySelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.errorText,
  });

  IconData _iconFor(ReportCategory category) {
    switch (category) {
      case ReportCategory.maintenance:
        return Icons.build_outlined;
      case ReportCategory.safety:
        return Icons.shield_outlined;
      case ReportCategory.cleanliness:
        return Icons.cleaning_services_outlined;
      case ReportCategory.utilities:
        return Icons.bolt_outlined;
      case ReportCategory.it:
        return Icons.wifi;
      case ReportCategory.other:
        return Icons.more_horiz;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ReportCategory.values.map((category) {
            return ChoiceChip(
              avatar: Icon(_iconFor(category), size: 18),
              label: Text(category.label),
              selected: selected == category,
              showCheckmark: false,
              onSelected: (_) => onChanged(category),
            );
          }).toList(),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 8),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}
