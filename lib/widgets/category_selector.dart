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
    final iconColor = Theme.of(context).colorScheme.primary;

    return DropdownButtonFormField<ReportCategory>(
      initialValue: selected,
      isExpanded: true,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      forceErrorText: errorText,
      validator: (value) => value == null ? 'Please choose a category' : null,
      decoration: const InputDecoration(labelText: 'Category'),
      items: ReportCategory.values
          .map(
            (category) => DropdownMenuItem(
              value: category,
              child: Row(
                children: [
                  Icon(_iconFor(category), size: 20, color: iconColor),
                  const SizedBox(width: 8),
                  Text(category.label),
                ],
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
