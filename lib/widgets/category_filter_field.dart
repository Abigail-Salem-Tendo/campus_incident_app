import 'package:flutter/material.dart';

import '../models/report_model.dart';

/// Dropdown to filter by category: "All categories" + one per category.
class CategoryFilterField extends StatelessWidget {
  final ReportCategory? selected; // null means "All categories"
  final ValueChanged<ReportCategory?> onChanged;

  const CategoryFilterField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<ReportCategory?>(
      // The key makes the field rebuild when "Clear filters" resets it.
      key: ValueKey(selected),
      initialValue: selected,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Category',
        prefixIcon: Icon(Icons.category_outlined),
      ),
      items: [
        const DropdownMenuItem<ReportCategory?>(
          value: null,
          child: Text('All categories'),
        ),
        for (final category in ReportCategory.values)
          DropdownMenuItem<ReportCategory?>(
            value: category,
            child: Text(category.label),
          ),
      ],
      onChanged: onChanged,
    );
  }
}
