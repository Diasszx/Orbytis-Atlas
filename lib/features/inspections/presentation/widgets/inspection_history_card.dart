import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExpansionTile(
            key: PageStorageKey('inspection-${inspection.clientId}'),
            title: Text(
              'Inspeção • ${_formatDate(inspection.capturedAt ?? inspection.createdAt)}',
              style: theme.textTheme.titleSmall,
            ),
            subtitle: InspectionSyncStatusView(
              status: inspection.syncStatus,
              message: inspection.syncError,
            ),
            expandedCrossAxisAlignment: CrossAxisAlignment.start,
            childrenPadding: const EdgeInsets.all(16),
            children: [
              if (inspection.observation case final observation?
                  when observation.isNotEmpty) ...[
                const Text('Observação'),
                SelectableText(observation),
              ],
              if (inspection.condition case final condition?) ...[
                const SizedBox(height: 12),
                const Text('Condição'),
                Text(condition),
              ],
              const SizedBox(height: 12),
              const Text('Localização'),
              SelectableText(
                inspection.latitude != null && inspection.longitude != null
                    ? '${inspection.latitude}, ${inspection.longitude}'
                    : 'Localização não registrada.',
              ),
              const SizedBox(height: 12),
              const Text('Foto'),
              if (inspection.photoPath case final photoPath?)
                Image.file(
                  File(photoPath),
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.contain,
                  semanticLabel: 'Foto da inspeção',
                  errorBuilder: (_, _, _) =>
                      const Text('Foto indisponível neste dispositivo.'),
                )
              else
                const Text('Foto não registrada.'),
            ],
          ),
          if (inspection.syncStatus == InspectionSyncStatus.draft)
            Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton.icon(
                onPressed: () =>
                    context.push('/inspections/${inspection.clientId}'),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Continuar inspeção'),
              ),
            ),
          if (inspection.syncStatus == InspectionSyncStatus.failed) ...[
            Padding(
              padding: const EdgeInsets.all(16),
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
