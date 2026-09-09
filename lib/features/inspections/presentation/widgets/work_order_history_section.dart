import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/inspections_repository.dart';
import '../bloc/history/inspection_history_bloc.dart';
import '../bloc/history/inspection_history_event.dart';
import '../bloc/history/inspection_history_state.dart';
import 'inspection_history_card.dart';

final class WorkOrderHistorySection extends StatelessWidget {
  const WorkOrderHistorySection({super.key, required this.workOrderId});

  final String workOrderId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => InspectionHistoryBloc(
        context.read<InspectionsRepository>(),
        workOrderId: workOrderId,
        excludeDrafts: true,
      )..add(const InspectionHistoryRequested()),
      child: BlocConsumer<InspectionHistoryBloc, InspectionHistoryState>(
        listener: (context, state) {
          if (state is InspectionHistoryLoaded &&
              state.feedbackMessage != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.feedbackMessage!)));
          }
        },
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Histórico de inspeções',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (state is InspectionHistoryLoaded) ...[
                Wrap(
                  spacing: 8,
                  children: [
                    for (final (filter, label) in [
                      (InspectionHistoryFilter.all, 'Todas'),
                      (InspectionHistoryFilter.pending, 'Pendentes'),
                      (InspectionHistoryFilter.synced, 'Sincronizadas'),
                      (InspectionHistoryFilter.failed, 'Falhas'),
                    ])
                      ChoiceChip(
                        label: Text(label),
                        selected: state.filter == filter,
                        onSelected: (_) => context
                            .read<InspectionHistoryBloc>()
                            .add(InspectionHistoryFilterChanged(filter)),
                      ),
                  ],
                ),
                if (state.inspections.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Nenhuma inspeção concluída para este filtro.'),
                  ),
                for (final inspection in state.inspections)
                  InspectionHistoryCard(
                    key: ValueKey(inspection.clientId),
                    inspection: inspection,
                    isRetrying: state.retryingClientId == inspection.clientId,
                    onRetry: state.retryingClientId != null
                        ? null
                        : () => context.read<InspectionHistoryBloc>().add(
                            InspectionHistoryRetryRequested(
                              inspection.clientId,
                            ),
                          ),
                  ),
              ] else if (state is InspectionHistoryFailure)
                Text(state.message)
              else
                const Center(child: CircularProgressIndicator()),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('Atualizar histórico'),
                  onPressed: () => context.read<InspectionHistoryBloc>().add(
                    const InspectionHistoryRequested(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
