import 'package:flutter/material.dart';

import '../../../../app/widgets/orbytis_header.dart';
import '../../models/work_order.dart';
import '../widgets/priority_badge.dart';
import '../widgets/status_badge.dart';
import '../widgets/work_order_details_section.dart';

final class WorkOrderDetailsPage extends StatelessWidget {
  static const double _headerHeight = 150;
  static const double _panelOverlap = 75;

  const WorkOrderDetailsPage({required this.workOrder, super.key});

  final WorkOrder workOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SizedBox.expand(
          child: Stack(
            children: [
              const OrbytisHeader(
                title: 'Detalhes OS',
                height: _headerHeight,
              ),
              Positioned.fill(
                top: _headerHeight - _panelOverlap,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.scaffoldBackgroundColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Text(
                        workOrder.title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          PriorityBadge(priority: workOrder.priority),
                          StatusBadge(status: workOrder.status),
                        ],
                      ),
                      const SizedBox(height: 28),
                      WorkOrderDetailsSection(
                        icon: Icons.location_on_outlined,
                        title: 'Local',
                        child: Text(
                          workOrder.address,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 24),
                      WorkOrderDetailsSection(
                        icon: Icons.description_outlined,
                        title: 'Descrição',
                        child: Text(
                          workOrder.description,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 24),
                      WorkOrderDetailsSection(
                        icon: Icons.event_outlined,
                        title: 'Agendamento',
                        child: Text(
                          _formatDateTime(workOrder.scheduledAt),
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      if (workOrder.notes != null &&
                          workOrder.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        WorkOrderDetailsSection(
                          icon: Icons.notes_outlined,
                          title: 'Observações da OS',
                          child: Text(
                            workOrder.notes!,
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final localDate = dateTime.toLocal();

    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year.toString();

    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }
}
