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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        if (message != null && message!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            message!,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ],
      ],
    );
  }
}
