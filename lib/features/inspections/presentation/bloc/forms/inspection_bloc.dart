import 'dart:async';

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
    on<InspectionPhotoRequested>(_onInspectionPhotoRequested);
    on<InspectionLocationRequested>(_onInspectionLocationRequested);
    on<InspectionAutosaveRequested>(_onInspectionAutosaveRequested);
    on<InspectionSaveAndExitRequested>(_onInspectionSaveAndExitRequested);
    on<InspectionConditionChanged>(_onInspectionConditionChanged);
    on<InspectionConclusionRequested>(_onInspectionConclusionRequested);
  }

  final InspectionsRepository _inspectionsRepository;
  Timer? _autosaveTimer;

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

    final updatedInspection = inspection.copyWith(observation: event.observation);
    emit(
      InspectionLoaded(
        updatedInspection,
        saveStatus: InspectionSaveStatus.unsaved,
      ),
    );

    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(milliseconds: 700), () {
      if (!isClosed) {
        add(const InspectionAutosaveRequested());
      }
    });
  }

  Future<void> _onInspectionAutosaveRequested(
    InspectionAutosaveRequested event,
    Emitter<InspectionState> emit,
  ) async {
    final currentState = state;

    if (currentState is! InspectionLoaded ||
        currentState.saveStatus == InspectionSaveStatus.saved) {
      return;
    }

    final inspection = currentState.inspection;
    emit(
      InspectionLoaded(
        inspection,
        saveStatus: InspectionSaveStatus.saving,
      ),
    );

    try {
      final savedInspection = await _inspectionsRepository.saveInspection(
        inspection,
      );
      emit(
        InspectionLoaded(
          savedInspection,
          saveStatus: InspectionSaveStatus.saved,
        ),
      );
    } on InspectionsException catch (error) {
      emit(
        InspectionLoaded(
          inspection,
          saveStatus: InspectionSaveStatus.error,
          saveError: error.message,
        ),
      );
    } catch (_) {
      emit(
        InspectionLoaded(
          inspection,
          saveStatus: InspectionSaveStatus.error,
          saveError: 'Não foi possível salvar as alterações.',
        ),
      );
    }
  }

  Future<void> _onInspectionDraftSaved(
    InspectionDraftSaved event,
    Emitter<InspectionState> emit,
  ) async {
    await _saveCurrentInspection(emit);
  }

  Future<void> _onInspectionSaveAndExitRequested(
    InspectionSaveAndExitRequested event,
    Emitter<InspectionState> emit,
  ) async {
    _autosaveTimer?.cancel();

    final inspection = _currentInspection;

    if (inspection == null) {
      return;
    }

    emit(
      InspectionLoaded(
        inspection,
        saveStatus: InspectionSaveStatus.saving,
      ),
    );

    try {
      final savedInspection = await _inspectionsRepository.saveInspection(
        inspection,
      );
      emit(InspectionSaveAndExitSuccess(savedInspection));
    } on InspectionsException catch (error) {
      emit(
        InspectionLoaded(
          inspection,
          saveStatus: InspectionSaveStatus.error,
          saveError: error.message,
        ),
      );
    } catch (_) {
      emit(
        InspectionLoaded(
          inspection,
          saveStatus: InspectionSaveStatus.error,
          saveError: 'Não foi possível salvar as alterações.',
        ),
      );
    }
  }

  Future<void> _onInspectionConditionChanged(
    InspectionConditionChanged event,
    Emitter<InspectionState> emit,
  ) async {
    final inspection = _currentInspection;

    if (inspection == null) {
      return;
    }

    _autosaveTimer?.cancel();
    final updatedInspection = inspection.copyWith(condition: event.condition);
    emit(
      InspectionLoaded(
        updatedInspection,
        saveStatus: InspectionSaveStatus.saving,
      ),
    );

    try {
      final savedInspection = await _inspectionsRepository.saveInspection(
        updatedInspection,
      );
      emit(
        InspectionLoaded(
          savedInspection,
          saveStatus: InspectionSaveStatus.saved,
        ),
      );
    } on InspectionsException catch (error) {
      emit(
        InspectionLoaded(
          updatedInspection,
          saveStatus: InspectionSaveStatus.error,
          saveError: error.message,
        ),
      );
    }
  }

  Future<void> _onInspectionConclusionRequested(
    InspectionConclusionRequested event,
    Emitter<InspectionState> emit,
  ) async {
    _autosaveTimer?.cancel();
    final inspection = _currentInspection;

    if (inspection == null) {
      return;
    }

    emit(InspectionConcluding(inspection));

    try {
      final completedInspection = await _inspectionsRepository.completeInspection(
        inspection,
      );
      emit(InspectionConclusionSuccess(completedInspection));
    } on InspectionsException catch (error) {
      emit(
        InspectionValidationFailure(
          inspection: inspection,
          message: error.message,
        ),
      );
    } catch (_) {
      emit(
        InspectionValidationFailure(
          inspection: inspection,
          message: 'Não foi possível concluir a inspeção.',
        ),
      );
    }
  }

  Future<void> _onInspectionPhotoRequested(
    InspectionPhotoRequested event,
    Emitter<InspectionState> emit,
  ) async {
    _autosaveTimer?.cancel();
    final inspection = _currentInspection;

    if (inspection == null) {
      return;
    }

    try {
      final updatedInspection = await _inspectionsRepository.capturePhoto(
        inspection,
      );

      if (updatedInspection != null) {
        emit(InspectionLoaded(updatedInspection));
      }
    } on InspectionsException catch (error) {
      emit(
        InspectionSaveFailure(inspection: inspection, message: error.message),
      );
    }
  }

  Future<void> _onInspectionLocationRequested(
    InspectionLocationRequested event,
    Emitter<InspectionState> emit,
  ) async {
    _autosaveTimer?.cancel();
    final inspection = _currentInspection;

    if (inspection == null) {
      return;
    }

    emit(InspectionGettingLocation(inspection));

    try {
      final updatedInspection = await _inspectionsRepository.registerLocation(
        inspection,
      );
      emit(InspectionLoaded(updatedInspection));
    } on InspectionsException catch (error) {
      emit(
        InspectionSaveFailure(inspection: inspection, message: error.message),
      );
    } catch (_) {
      emit(
        InspectionSaveFailure(
          inspection: inspection,
          message: 'Não foi possível registrar a localização.',
        ),
      );
    }
  }

  Future<void> _saveCurrentInspection(Emitter<InspectionState> emit) async {
    _autosaveTimer?.cancel();
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
      InspectionGettingLocation(:final inspection) => inspection,
      InspectionSaveFailure(:final inspection) => inspection,
      InspectionConcluding(:final inspection) => inspection,
      InspectionValidationFailure(:final inspection) => inspection,
      _ => null,
    };
  }

  @override
  Future<void> close() {
    _autosaveTimer?.cancel();
    return super.close();
  }
}
