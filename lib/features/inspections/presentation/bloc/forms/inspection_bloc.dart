import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orbytis_atlas/features/inspections/errors/inspections_exception.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_event.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_state.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';

final class InspectionBloc extends Bloc<InspectionEvent, InspectionState> {
  InspectionBloc(this._inspectionsRepository)
    : super(const InspectionInitial()) {
    on<InspectionRequested>(_onInspectionRequested);
    on<InspectionObservationChanged>(_onInspectionObservationChanged);
    on<InspectionDraftSaved>(_onInspectionDraftSaved);
  }

  final InspectionsRepository _inspectionsRepository;

  void _onInspectionRequested(
    InspectionRequested event,
    Emitter<InspectionState> emit,
  ) {
    emit(const InspectionLoading());

    try {
      final inspection = _inspectionsRepository.getInspectionByClientId(
        event.clientId,
      );

      if (inspection == null) {
        emit(const InspectionFailure('Inspeção não encontrada.'));
        return;
      }

      emit(InspectionLoaded(inspection));
    } on InspectionsException catch (error) {
      emit(InspectionFailure(error.message));
    } catch (_) {
      emit(const InspectionFailure('Não foi possível carregar a inspeção.'));
    }
  }

  void _onInspectionObservationChanged(
    InspectionObservationChanged event,
    Emitter<InspectionState> emit,
  ) {
    final inspection = _currentInspection;

    if (inspection == null) {
      return;
    }

    emit(InspectionLoaded(inspection.copyWith(observation: event.observation)));
  }

  Future<void> _onInspectionDraftSaved(
    InspectionDraftSaved event,
    Emitter<InspectionState> emit,
  ) async {
    final inspection = _currentInspection;

    if (inspection == null) {
      return;
    }

    emit(InspectionSaving(inspection));

    try {
      final savedInspection = await _inspectionsRepository.saveInspection(
        inspection,
      );

      emit(InspectionLoaded(savedInspection));
    } on InspectionsException catch (error) {
      emit(
        InspectionSaveFailure(inspection: inspection, message: error.message),
      );
    } catch (_) {
      emit(
        InspectionSaveFailure(
          inspection: inspection,
          message: 'Não foi possível salvar o rascunho.',
        ),
      );
    }
  }

  Inspection? get _currentInspection {
    return switch (state) {
      InspectionLoaded(:final inspection) => inspection,
      InspectionSaving(:final inspection) => inspection,
      InspectionSaveFailure(:final inspection) => inspection,
      _ => null,
    };
  }
}
