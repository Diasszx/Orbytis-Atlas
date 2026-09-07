import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/work_order.dart';
import 'priority_badge.dart';
import 'status_badge.dart';

final class WorkOrderCard extends StatelessWidget {
  const WorkOrderCard({super.key, required this.workOrder});

  final WorkOrder workOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          context.push('/work-orders/${workOrder.id}', extra: workOrder);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                workOrder.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      workOrder.address,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                ],
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
            ],
          ),
        ),
      ),
    );
  }
}
