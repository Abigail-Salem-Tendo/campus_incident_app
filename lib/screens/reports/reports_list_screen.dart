import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../providers/report_provider.dart';
import '../../widgets/report_card.dart';
import 'report_detail_screen.dart';

class ReportsListScreen extends StatefulWidget {
  const ReportsListScreen({super.key});

  @override
  State<ReportsListScreen> createState() => _ReportsListScreenState();
}

class _ReportsListScreenState extends State<ReportsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ReportProvider>().startListening();
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

    final reports = provider.reports;
    if (reports.isEmpty) {
      return const _MessageView(
        icon: Icons.inbox_outlined,
        title: 'No reports yet',
        message: 'Reports submitted on campus will appear here.',
      );
    }

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
                builder: (_) => ReportDetailScreen(reportId: report.id)
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
