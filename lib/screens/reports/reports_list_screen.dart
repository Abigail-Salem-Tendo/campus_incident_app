import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/report_card.dart';
import '../../widgets/status_filter_bar.dart';
import '../../widgets/status_summary.dart';
import 'report_detail_screen.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<ReportProvider>();
    _searchController = TextEditingController(text: provider.searchQuery);
    final auth = context.read<AuthProvider>();
    final uid = auth.profile?.uid;
    if (uid != null) {
      provider.startListening(uid: uid, isStaff: auth.isStaff);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    final isStaff = context.watch<AuthProvider>().isStaff;
    return _buildBody(context, provider, isStaff);
  }

  Widget _buildBody(
    BuildContext context,
    ReportProvider provider,
    bool isStaff,
  ) {
    if (provider.listError != null) {
      return _MessageView(
        icon: Icons.cloud_off_outlined,
        title: 'Something went wrong',
        message: provider.listError!,
        actionLabel: 'Retry',
        onAction: provider.retry,
      );
    }

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.reports.isEmpty) {
      return _MessageView(
        icon: isStaff ? Icons.inbox_outlined : Icons.assignment_outlined,
        title: isStaff ? 'No reports yet' : 'You have no reports yet',
        message: isStaff
            ? 'Reports submitted on campus will appear here.'
            : 'Tap "New report" to report an issue on campus.',
      );
    }

    final reports = provider.filteredReports;
    final category = provider.categoryFilter;

    return Column(
      children: [
        if (isStaff)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            child: StatusSummary(
              counts: provider.statusCount,
              selected: provider.statusFilter,
              onChanged: provider.setStatusFilter,
            ),
          ),
        SizedBox(height: isStaff ? AppSpacing.sm : AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: _buildSearchField(context, provider),
        ),
        const SizedBox(height: AppSpacing.sm),
        if (!isStaff)
          StatusFilterBar(
            selected: provider.statusFilter,
            onChanged: provider.setStatusFilter,
          ),
        if (category != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Align(
              alignment: Alignment.centerLeft,
              child: InputChip(
                label: Text(category.label),
                onDeleted: () => provider.setCategoryFilter(null),
              ),
            ),
          ),
        ],
        Expanded(
          child: reports.isEmpty
              ? _MessageView(
                  icon: Icons.search_off_outlined,
                  title: 'No matching reports',
                  message: 'Try a different search or filter.',
                  actionLabel: 'Clear filters',
                  onAction: () {
                    _searchController.clear();
                    provider.clearFilters();
                  },
                )
              : _buildList(reports),
        ),
      ],
    );
  }

  Widget _buildSearchField(BuildContext context, ReportProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: provider.setSearchQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by title',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (provider.searchQuery.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
              ),
            IconButton(
              icon: Badge(
                isLabelVisible: provider.categoryFilter != null,
                smallSize: 8,
                child: const Icon(Icons.tune),
              ),
              tooltip: 'Filter by category',
              onPressed: () => _showCategorySheet(context, provider),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCategorySheet(
    BuildContext context,
    ReportProvider provider,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final selected = provider.categoryFilter;

        Widget option(String label, ReportCategory? value) {
          return ListTile(
            title: Text(label),
            trailing: selected == value ? const Icon(Icons.check) : null,
            selected: selected == value,
            onTap: () {
              provider.setCategoryFilter(value);
              Navigator.of(sheetContext).pop();
            },
          );
        }

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    'Filter by category',
                    style: Theme.of(sheetContext).textTheme.titleMedium,
                  ),
                ),
                option('All categories', null),
                for (final c in ReportCategory.values) option(c.label, c),
                const SizedBox(height: AppSpacing.sm),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(List<ReportModel> reports) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        88,
      ),
      itemCount: reports.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final report = reports[index];
        return ReportCard(
          report: report,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportDetailScreen(reportId: report.id),
              ),
            );
          },
        );
      },
    );
  }
}

/// Centered icon + title + message (+ optional button) for empty/error states.
class _MessageView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageView({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpacing.md),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
