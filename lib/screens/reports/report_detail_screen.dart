import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_spacing.dart';
import '../../models/report_model.dart';
import '../../providers/report_provider.dart';
import '../../widgets/status_badge.dart';

/// Full details of one report. Looks the report up by ID in the live list,
/// so status changes show up without reopening the screen.
class ReportDetailScreen extends StatelessWidget {
  final String reportId;

  const ReportDetailScreen({super.key, required this.reportId});

  ReportModel? _find(List<ReportModel> reports) {
    for (final report in reports) {
      if (report.id == reportId) return report;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final reports = context.watch<ReportProvider>().reports;
    final report = _find(reports);

    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: report == null
          ? const Center(child: Text('This report is no longer available.'))
          : _DetailContent(report: report),
    );
  }
}

class _DetailContent extends StatelessWidget {
  final ReportModel report;

  const _DetailContent({required this.report});

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatDate(DateTime? time) {
    if (time == null) return 'Just now';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${time.day} ${_months[time.month - 1]} ${time.year}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = report.photoUrl != null && report.photoUrl!.isNotEmpty;
    final reporter = report.isAnonymous ? 'Anonymous' : report.reporterName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasPhoto) ...[
            _ReportPhoto(url: report.photoUrl!),
            const SizedBox(height: AppSpacing.md),
          ],
          StatusBadge(status: report.status),
          const SizedBox(height: AppSpacing.sm),
          Text(
            report.title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Category',
            value: report.category.label,
          ),
          _InfoRow(
            icon: Icons.place_outlined,
            label: 'Location',
            value: report.location,
          ),
          _InfoRow(
            icon: Icons.person_outline,
            label: 'Reported by',
            value: reporter,
          ),
          _InfoRow(
            icon: Icons.schedule_outlined,
            label: 'Reported on',
            value: _formatDate(report.createdAt),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Description',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(report.description, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Network photo with a spinner while loading and a placeholder on failure.
class _ReportPhoto extends StatelessWidget {
  final String url;

  const _ReportPhoto({required this.url});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final placeholderColor = theme.colorScheme.surfaceContainerHighest;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: SizedBox(
        width: double.infinity,
        height: 240,
        child: Image.network(
          url,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return Container(
              color: placeholderColor,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              color: placeholderColor,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 48,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Photo could not be loaded',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One labeled line: icon, small label, value.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: muted),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(color: muted),
                ),
                const SizedBox(height: 4),
                Text(value, style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
