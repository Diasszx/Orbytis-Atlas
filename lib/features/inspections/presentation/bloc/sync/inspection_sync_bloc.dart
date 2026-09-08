import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../errors/inspections_exception.dart';
import '../../../models/inspection_sync_status.dart';
import '../../../repositories/inspections_repository.dart';
import 'inspection_sync_event.dart';
import 'inspection_sync_state.dart';

final class InspectionSyncBloc
    extends Bloc<InspectionSyncEvent, InspectionSyncState> {
  InspectionSyncBloc(this._inspectionsRepository)
    : super(const InspectionSyncInitial()) {
    on<InspectionSyncRequested>(_onInspectionSyncRequested);
  }

  final InspectionsRepository _inspectionsRepository;

  Future<void> _onInspectionSyncRequested(
    InspectionSyncRequested event,
    Emitter<InspectionSyncState> emit,
  ) async {
    emit(const InspectionSyncLoading());

    try {
      final inspection = await _inspectionsRepository.syncInspection(
        event.clientId,
      );

      switch (inspection.syncStatus) {
        case InspectionSyncStatus.synced:
          emit(InspectionSyncSuccess(inspection));
        case InspectionSyncStatus.pending:
          emit(
            InspectionSyncPending(
              inspection: inspection,
              message:
                  inspection.syncError ??
                  'A inspeção continuará aguardando sincronização.',
            ),
          );
        case InspectionSyncStatus.failed:
          emit(
            InspectionSyncFailure(
              inspection: inspection,
              message:
                  inspection.syncError ?? 'Não foi possível sincronizar a inspeção.',
            ),
          );
        case InspectionSyncStatus.draft:
          emit(
            const InspectionSyncFailure(
              message: 'Rascunhos não podem ser sincronizados.',
            ),
          );
      }
    } on InspectionsException catch (error) {
      emit(InspectionSyncFailure(message: error.message));
    } catch (_) {
      emit(
        const InspectionSyncFailure(
          message: 'Não foi possível sincronizar a inspeção.',
        ),
      );
    }
  }
}
