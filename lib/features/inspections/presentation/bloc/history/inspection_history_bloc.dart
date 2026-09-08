import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../errors/inspections_exception.dart';
import '../../../models/inspection.dart';
import '../../../models/inspection_sync_status.dart';
import '../../../repositories/inspections_repository.dart';
import 'inspection_history_event.dart';
import 'inspection_history_state.dart';

final class InspectionHistoryBloc
    extends Bloc<InspectionHistoryEvent, InspectionHistoryState> {
  InspectionHistoryBloc(this._inspectionsRepository)
    : super(const InspectionHistoryInitial()) {
    on<InspectionHistoryRequested>(_onRequested);
    on<InspectionHistoryFilterChanged>(_onFilterChanged);
    on<InspectionHistoryRetryRequested>(_onRetryRequested);
  }

  final InspectionsRepository _inspectionsRepository;

  void _onRequested(
    InspectionHistoryRequested event,
    Emitter<InspectionHistoryState> emit,
  ) {
    emit(const InspectionHistoryLoading());
    _load(filter: InspectionHistoryFilter.all, emit: emit);
  }

  void _onFilterChanged(
    InspectionHistoryFilterChanged event,
    Emitter<InspectionHistoryState> emit,
  ) {
    _load(filter: event.filter, emit: emit);
  }

  Future<void> _onRetryRequested(
    InspectionHistoryRetryRequested event,
    Emitter<InspectionHistoryState> emit,
  ) async {
    final currentState = state;

    if (currentState is! InspectionHistoryLoaded) {
      return;
    }

    emit(
      InspectionHistoryLoaded(
        inspections: currentState.inspections,
        filter: currentState.filter,
        retryingClientId: event.clientId,
      ),
    );

    try {
      final inspection = await _inspectionsRepository.syncInspection(event.clientId);
      final message = switch (inspection.syncStatus) {
        InspectionSyncStatus.synced => 'Inspeção sincronizada com sucesso.',
        InspectionSyncStatus.pending =>
          'Sem conexão. A inspeção continuará pendente.',
        InspectionSyncStatus.failed =>
          inspection.syncError ?? 'Não foi possível sincronizar a inspeção.',
        InspectionSyncStatus.draft => 'Rascunhos não podem ser sincronizados.',
      };

      _load(
        filter: currentState.filter,
        emit: emit,
        feedbackMessage: message,
      );
    } on InspectionsException catch (error) {
      _load(
        filter: currentState.filter,
        emit: emit,
        feedbackMessage: error.message,
      );
    }
  }

  void _load({
    required InspectionHistoryFilter filter,
    required Emitter<InspectionHistoryState> emit,
    String? feedbackMessage,
  }) {
    try {
      final inspections = _inspectionsRepository.getInspections();
      final filtered = inspections
          .where((inspection) => _matchesFilter(inspection, filter))
          .toList(growable: false);

      emit(
        InspectionHistoryLoaded(
          inspections: filtered,
          filter: filter,
          feedbackMessage: feedbackMessage,
        ),
      );
    } on InspectionsException catch (error) {
      emit(InspectionHistoryFailure(error.message));
    }
  }

  bool _matchesFilter(Inspection inspection, InspectionHistoryFilter filter) {
    return switch (filter) {
      InspectionHistoryFilter.all => true,
      InspectionHistoryFilter.draft =>
        inspection.syncStatus == InspectionSyncStatus.draft,
      InspectionHistoryFilter.pending =>
        inspection.syncStatus == InspectionSyncStatus.pending,
      InspectionHistoryFilter.synced =>
        inspection.syncStatus == InspectionSyncStatus.synced,
      InspectionHistoryFilter.failed =>
        inspection.syncStatus == InspectionSyncStatus.failed,
    };
  }
}
