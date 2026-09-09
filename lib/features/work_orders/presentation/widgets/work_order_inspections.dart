import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../inspections/models/inspection.dart';
import '../../../inspections/models/inspection_sync_status.dart';
import '../../../inspections/repositories/inspections_repository.dart';

String workOrderStatusFromInspections(List<Inspection> inspections) {
  if (inspections.any(
    (inspection) => inspection.syncStatus == InspectionSyncStatus.draft,
  )) {
    return 'in_progress';
  }

  if (inspections.isNotEmpty) {
    return 'done';
  }

  return 'open';
}

final class WorkOrderInspectionsBuilder extends StatelessWidget {
  const WorkOrderInspectionsBuilder({
    super.key,
    required this.workOrderId,
    required this.builder,
  });

  final String workOrderId;
  final Widget Function(BuildContext, List<Inspection>) builder;

  @override
  Widget build(BuildContext context) {
    final repository = context.read<InspectionsRepository>();
    return StreamBuilder<void>(
      stream: repository.changes,
      builder: (context, _) =>
          builder(context, repository.getInspectionsByWorkOrderId(workOrderId)),
    );
  }
}

final class WorkOrderInspectionSummary extends StatelessWidget {
  const WorkOrderInspectionSummary({super.key, required this.inspections});

  final List<Inspection> inspections;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final status in [
          InspectionSyncStatus.failed,
          InspectionSyncStatus.pending,
          InspectionSyncStatus.draft,
          InspectionSyncStatus.synced,
        ])
          if (inspections.any((item) => item.syncStatus == status))
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Builder(
                builder: (context) {
                  final count = inspections
                      .where((item) => item.syncStatus == status)
                      .length;
                  final plural = count != 1;
                  final (icon, text, color) = switch (status) {
                    InspectionSyncStatus.failed => (
                      Icons.error_outline,
                      'com falha no envio',
                      colors.error,
                    ),
                    InspectionSyncStatus.pending => (
                      Icons.schedule,
                      'aguardando envio',
                      colors.tertiary,
                    ),
                    InspectionSyncStatus.draft => (
                      Icons.edit_outlined,
                      'em rascunho',
                      colors.secondary,
                    ),
                    InspectionSyncStatus.synced => (
                      Icons.cloud_done_outlined,
                      plural ? 'sincronizadas' : 'sincronizada',
                      colors.primary,
                    ),
                  };
                  return Row(
                    children: [
                      Icon(icon, size: 20, color: color),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '$count ${plural ? 'inspeções' : 'inspeção'} $text',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: color),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
      ],
    );
  }
}
