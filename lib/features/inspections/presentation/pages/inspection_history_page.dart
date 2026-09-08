import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/widgets/orbytis_header.dart';
import '../../models/inspection.dart';
import '../bloc/history/inspection_history_bloc.dart';
import '../bloc/history/inspection_history_event.dart';
import '../bloc/history/inspection_history_state.dart';
import '../widgets/inspection_history_card.dart';

final class InspectionHistoryPage extends StatelessWidget {
  const InspectionHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: SizedBox.expand(
          child: Stack(
          children: [
            const OrbytisHeader(title: 'Inspeções', height: 150),
            Positioned.fill(
              top: 122,
              child: Container(
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: BlocConsumer<InspectionHistoryBloc, InspectionHistoryState>(
                  listener: (context, state) {
                    if (state case InspectionHistoryLoaded(
                      :final feedbackMessage,
                    ) when feedbackMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(feedbackMessage)),
                      );
                    }
                  },
                  builder: (context, state) {
                    return switch (state) {
                      InspectionHistoryInitial() || InspectionHistoryLoading() =>
                        const Center(child: CircularProgressIndicator()),
                      InspectionHistoryFailure(:final message) =>
                        _HistoryFailure(message: message),
                      InspectionHistoryLoaded(
                        :final inspections,
                        :final filter,
                        :final retryingClientId,
                      ) =>
                        _HistoryContent(
                          inspections: inspections,
                          filter: filter,
                          retryingClientId: retryingClientId,
                        ),
                    };
                  },
                ),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

final class _HistoryContent extends StatelessWidget {
  const _HistoryContent({
    required this.inspections,
    required this.filter,
    required this.retryingClientId,
  });

  final List<Inspection> inspections;
  final InspectionHistoryFilter filter;
  final String? retryingClientId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            children: [
              _FilterChip(
                label: 'Todas',
                filter: InspectionHistoryFilter.all,
                selectedFilter: filter,
              ),
              _FilterChip(
                label: 'Rascunhos',
                filter: InspectionHistoryFilter.draft,
                selectedFilter: filter,
              ),
              _FilterChip(
                label: 'Pendentes',
                filter: InspectionHistoryFilter.pending,
                selectedFilter: filter,
              ),
              _FilterChip(
                label: 'Sincronizadas',
                filter: InspectionHistoryFilter.synced,
                selectedFilter: filter,
              ),
              _FilterChip(
                label: 'Falhas',
                filter: InspectionHistoryFilter.failed,
                selectedFilter: filter,
              ),
            ],
          ),
        ),
        Expanded(
          child: inspections.isEmpty
              ? const _HistoryEmpty()
              : RefreshIndicator(
                  onRefresh: () async {
                    final bloc = context.read<InspectionHistoryBloc>();
                    final completed = bloc.stream.firstWhere(
                      (state) =>
                          state is InspectionHistoryLoaded ||
                          state is InspectionHistoryFailure,
                    );

                    bloc.add(const InspectionHistoryRequested());
                    await completed;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: inspections.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final inspection = inspections[index];
                      return InspectionHistoryCard(
                        inspection: inspection,
                        isRetrying: retryingClientId == inspection.clientId,
                        onRetry: () {
                          context.read<InspectionHistoryBloc>().add(
                            InspectionHistoryRetryRequested(inspection.clientId),
                          );
                        },
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

final class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.filter,
    required this.selectedFilter,
  });

  final String label;
  final InspectionHistoryFilter filter;
  final InspectionHistoryFilter selectedFilter;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: filter == selectedFilter,
        onSelected: (_) {
          context.read<InspectionHistoryBloc>().add(
            InspectionHistoryFilterChanged(filter),
          );
        },
      ),
    );
  }
}

final class _HistoryEmpty extends StatelessWidget {
  const _HistoryEmpty();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fact_check_outlined,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma inspeção encontrada',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _HistoryFailure extends StatelessWidget {
  const _HistoryFailure({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
