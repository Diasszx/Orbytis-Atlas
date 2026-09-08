import 'package:flutter/material.dart';

import '../../models/inspection.dart';
import '../../models/inspection_sync_status.dart';
import 'inspection_sync_status.dart';

final class InspectionHistoryCard extends StatelessWidget {
  const InspectionHistoryCard({
    required this.inspection,
    this.onRetry,
    this.isRetrying = false,
    super.key,
  });

  final Inspection inspection;
  final VoidCallback? onRetry;
  final bool isRetrying;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'OS ${inspection.workOrderId}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            InspectionSyncStatusView(
              status: inspection.syncStatus,
              message: inspection.syncError,
            ),
            const SizedBox(height: 12),
            Text(
              _formatDate(inspection.updatedAt),
              style: theme.textTheme.bodySmall,
            ),
            if (inspection.observation case final observation?
                when observation.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                observation,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (inspection.syncStatus == InspectionSyncStatus.failed) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: isRetrying ? null : onRetry,
                  icon: isRetrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh),
                  label: Text(
                    isRetrying ? 'Tentando novamente...' : 'Tentar novamente',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime value) {
    final date = value.toLocal();
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} às $hour:$minute';
  }
}
