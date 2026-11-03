import 'package:flutter/material.dart';

import '../core/theme/app_spacing.dart';
import '../models/report_model.dart';
import 'status_badge.dart';

/// One row in the reports list. Knows nothing about Firestore or Provider.
class ReportCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onTap;

  const ReportCard({super.key, required this.report, required this.onTap});

  String _timeAgo(DateTime? time) {
    if (time == null) return 'Just now';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final hasPhoto = report.photoUrl != null && report.photoUrl!.isNotEmpty;
    final reporter = report.isAnonymous ? 'Anonymous' : report.reporterName;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  StatusBadge(status: report.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${report.category.label} · ${report.location}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(color: muted),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reporter,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ),
                  if (hasPhoto) ...[
                    Icon(Icons.photo_outlined, size: 16, color: muted),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    _timeAgo(report.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
