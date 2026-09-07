import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/inspections_exception.dart';
import '../../repositories/inspections_repository.dart';
import 'inspection_start_event.dart';
import 'inspection_start_state.dart';

final class InspectionStartBloc
    extends Bloc<InspectionStartEvent, InspectionStartState> {
  InspectionStartBloc(this._inspectionsRepository)
    : super(const InspectionStartInitial()) {
    on<InspectionStartRequested>(_onInspectionStartRequested);
  }

  final InspectionsRepository _inspectionsRepository;

  Future<void> _onInspectionStartRequested(
    InspectionStartRequested event,
    Emitter<InspectionStartState> emit,
  ) async {
    emit(const InspectionStartLoading());

    try {
      final inspection = await _inspectionsRepository.createDraft(
        workOrderId: event.workOrderId,
      );

      emit(InspectionStartSuccess(inspection.clientId));
    } on InspectionsException catch (error) {
      emit(InspectionStartFailure(error.message));
    } catch (_) {
      emit(
        const InspectionStartFailure('Não foi possível iniciar a inspeção.'),
      );
    }
  }
}
