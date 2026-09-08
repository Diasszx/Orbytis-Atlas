import 'package:flutter/material.dart';

import '../../models/inspection_sync_status.dart';

final class InspectionSyncStatusView extends StatelessWidget {
  const InspectionSyncStatusView({
    super.key,
    required this.status,
    this.message,
  });

  final InspectionSyncStatus status;
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (icon, label, color) = switch (status) {
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (message != null && message!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(message!, style: theme.textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
