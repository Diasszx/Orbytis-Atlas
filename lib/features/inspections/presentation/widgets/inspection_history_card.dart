import 'package:flutter/material.dart';

import '../../models/inspection.dart';
import '../../models/inspection_sync_status.dart';

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
    final (icon, label, color) = switch (inspection.syncStatus) {
      InspectionSyncStatus.draft => (
        Icons.edit_outlined,
        'Rascunho',
        theme.colorScheme.secondary,
      ),
      InspectionSyncStatus.pending => (
        Icons.schedule,
        'Aguardando sincronização',
        theme.colorScheme.tertiary,
      ),
      InspectionSyncStatus.synced => (
        Icons.cloud_done_outlined,
        'Sincronizada',
        Colors.green,
      ),
      InspectionSyncStatus.failed => (
        Icons.error_outline,
        'Falha na sincronização',
        theme.colorScheme.error,
      ),
    };

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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _formatDate(inspection.updatedAt),
              style: theme.textTheme.bodySmall,
            ),
            if (inspection.syncError case final syncError?
                when syncError.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                syncError,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
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

    return '$day/$month às $hour:$minute';
  }
}
