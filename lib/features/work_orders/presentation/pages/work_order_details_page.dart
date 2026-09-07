import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/widgets/orbytis_header.dart';
import '../../../inspections/presentation/bloc/inspection_start_bloc.dart';
import '../../../inspections/presentation/bloc/inspection_start_event.dart';
import '../../../inspections/presentation/bloc/inspection_start_state.dart';
import '../../models/work_order.dart';
import '../bloc/work_order_details_bloc.dart';
import '../bloc/work_order_details_state.dart';
import '../widgets/priority_badge.dart';
import '../widgets/status_badge.dart';
import '../widgets/work_order_details_section.dart';

final class WorkOrderDetailsPage extends StatelessWidget {
  const WorkOrderDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<InspectionStartBloc, InspectionStartState>(
      listener: (context, state) {
        if (state case InspectionStartSuccess(:final clientId)) {
          context.push('/inspections/$clientId');
        }

        if (state case InspectionStartFailure(:final message)) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: BlocBuilder<WorkOrderDetailsBloc, WorkOrderDetailsState>(
            builder: (context, state) {
              return switch (state) {
                WorkOrderDetailsInitial() || WorkOrderDetailsLoading() =>
                  const Center(child: CircularProgressIndicator()),
                WorkOrderDetailsLoaded(:final workOrder) =>
                  _WorkOrderDetailsContent(workOrder: workOrder),
                WorkOrderDetailsFailure(:final message) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(message, textAlign: TextAlign.center),
                  ),
                ),
              };
            },
          ),
        ),
      ),
    );
  }
}

final class _WorkOrderDetailsContent extends StatelessWidget {
  static const double _headerHeight = 150;
  static const double _panelOverlap = 28;

  const _WorkOrderDetailsContent({required this.workOrder});

  final WorkOrder workOrder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox.expand(
      child: Stack(
        children: [
          const OrbytisHeader(
            title: 'Detalhes OS',
            height: _headerHeight,
          ),
          Positioned.fill(
            top: _headerHeight - _panelOverlap,
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
                  BlocBuilder<InspectionStartBloc, InspectionStartState>(
                    builder: (context, state) {
                      final isLoading = state is InspectionStartLoading;

                      return SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.read<InspectionStartBloc>().add(
                                    InspectionStartRequested(workOrder.id),
                                  );
                                },
                          icon: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.play_arrow),
                          label: Text(
                            isLoading ? 'Iniciando...' : 'Iniciar inspeção',
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDateTime(DateTime dateTime) {
    final localDate = dateTime.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    final year = localDate.year;
    final hour = localDate.hour.toString().padLeft(2, '0');
    final minute = localDate.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  }
}
