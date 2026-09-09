import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../errors/inspections_exception.dart';
import '../../../models/inspection.dart';
import '../../../models/inspection_sync_status.dart';
import '../../../repositories/inspections_repository.dart';
import 'inspection_history_event.dart';
import 'inspection_history_state.dart';

final class InspectionHistoryBloc
    extends Bloc<InspectionHistoryEvent, InspectionHistoryState> {
  InspectionHistoryBloc(
    this._inspectionsRepository, {
    this.workOrderId,
    this.excludeDrafts = false,
  }) : super(const InspectionHistoryInitial()) {
    on<InspectionHistoryRequested>(_onRequested);
    on<InspectionHistoryFilterChanged>(_onFilterChanged);
    on<InspectionHistoryRetryRequested>(_onRetryRequested);
    on<InspectionHistoryUpdated>(
      (event, emit) => _load(filter: _filter, emit: emit),
    );
    _subscription = _inspectionsRepository.changes.listen((_) {
      if (!isClosed) add(const InspectionHistoryUpdated());
    });
  }

  final InspectionsRepository _inspectionsRepository;
  final String? workOrderId;
  final bool excludeDrafts;
  late final StreamSubscription<void> _subscription;
  InspectionHistoryFilter _filter = InspectionHistoryFilter.all;
  String? _retryingClientId;

  @override
  Future<void> close() async {
    await _subscription.cancel();
    await super.close();
  }

  void _onRequested(
    InspectionHistoryRequested event,
    Emitter<InspectionHistoryState> emit,
  ) {
    emit(const InspectionHistoryLoading());
    _load(filter: _filter, emit: emit);
  }

  void _onFilterChanged(
    InspectionHistoryFilterChanged event,
    Emitter<InspectionHistoryState> emit,
  ) {
    _filter = event.filter;
    _load(filter: _filter, emit: emit);
  }

  Future<void> _onRetryRequested(
    InspectionHistoryRetryRequested event,
    Emitter<InspectionHistoryState> emit,
  ) async {
    final currentState = state;

    if (currentState is! InspectionHistoryLoaded || _retryingClientId != null) {
      return;
    }
    if (!currentState.inspections.any(
      (item) =>
          item.clientId == event.clientId &&
          item.syncStatus == InspectionSyncStatus.failed,
    )) {
      return;
    }
    _retryingClientId = event.clientId;

    emit(
      InspectionHistoryLoaded(
        inspections: currentState.inspections,
        filter: currentState.filter,
        retryingClientId: event.clientId,
      ),
    );

    try {
      final inspection = await _inspectionsRepository.syncInspection(
        event.clientId,
      );
      final message = switch (inspection.syncStatus) {
        InspectionSyncStatus.synced => 'Inspeção sincronizada com sucesso.',
        InspectionSyncStatus.pending =>
          'Sem conexão. A inspeção continuará pendente.',
        InspectionSyncStatus.failed =>
          inspection.syncError ?? 'Não foi possível sincronizar a inspeção.',
        InspectionSyncStatus.draft => 'Rascunhos não podem ser sincronizados.',
      };

      _retryingClientId = null;
      _load(filter: _filter, emit: emit, feedbackMessage: message);
    } on InspectionsException catch (error) {
      _retryingClientId = null;
      _load(filter: _filter, emit: emit, feedbackMessage: error.message);
    } catch (_) {
      _retryingClientId = null;
      _load(
        filter: _filter,
        emit: emit,
        feedbackMessage:
            'Não foi possível sincronizar a inspeção. Tente novamente.',
      );
    }
  }

  void _load({
    required InspectionHistoryFilter filter,
    required Emitter<InspectionHistoryState> emit,
    String? feedbackMessage,
  }) {
    try {
      if (emit.isDone) return;
      final inspections = _inspectionsRepository.getInspections();
      final filtered = inspections
          .where(
            (inspection) =>
                workOrderId == null || inspection.workOrderId == workOrderId,
          )
          .where((inspection) => _matchesFilter(inspection, filter))
          .where(
            (inspection) =>
                !excludeDrafts ||
                inspection.syncStatus != InspectionSyncStatus.draft,
          )
          .toList(growable: false);
      filtered.sort(
        (a, b) => (b.capturedAt ?? b.createdAt).compareTo(
          a.capturedAt ?? a.createdAt,
        ),
      );

      emit(
        InspectionHistoryLoaded(
          inspections: filtered,
          filter: filter,
          retryingClientId: _retryingClientId,
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
