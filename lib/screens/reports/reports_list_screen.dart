import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/report_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/report_provider.dart';
import '../../widgets/category_filter_field.dart';
import '../../widgets/report_card.dart';
import '../../widgets/status_filter_bar.dart';
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
    provider.startListening();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportProvider>();
    return _buildBody(context, provider);
  }

  Widget _buildBody(BuildContext context, ReportProvider provider) {
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
      return const _MessageView(
        icon: Icons.inbox_outlined,
        title: 'No reports yet',
        message: 'Reports submitted on campus will appear here.',
      );
    }

    final reports = provider.filteredReports;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: _buildViewToggle(context, provider),
        ),
        if (provider.isMineEmpty)
          const Expanded(
            child: _MessageView(
              icon: Icons.assignment_outlined,
              title: 'No reports of your own yet',
              message: 'Reports you submit will appear here.',
            ),
          )
        else ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: _buildSearchField(provider),
          ),
          const SizedBox(height: AppSpacing.sm),
          StatusFilterBar(
            selected: provider.statusFilter,
            onChanged: provider.setStatusFilter,
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: CategoryFilterField(
              selected: provider.categoryFilter,
              onChanged: provider.setCategoryFilter,
            ),
          ),
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
      ],
    );
  }

  Widget _buildViewToggle(BuildContext context, ReportProvider provider) {
    return SegmentedButton<bool>(
      expandedInsets: EdgeInsets.zero,
      showSelectedIcon: false,
      segments: const [
        ButtonSegment(value: false, label: Text('All reports')),
        ButtonSegment(value: true, label: Text('My reports')),
      ],
      selected: {provider.isMineOnly},
      onSelectionChanged: (selection) {
        if (selection.first) {
          final uid = context.read<AuthProvider>().profile?.uid;
          if (uid != null) provider.showMine(uid);
        } else {
          provider.showAll();
        }
      },
    );
  }

  Widget _buildSearchField(ReportProvider provider) {
    return TextField(
      controller: _searchController,
      onChanged: provider.setSearchQuery,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search by title',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: provider.searchQuery.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  provider.setSearchQuery('');
                },
              ),
      ),
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