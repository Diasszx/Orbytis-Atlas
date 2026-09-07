import 'package:equatable/equatable.dart';
import 'package:orbytis_atlas/features/inspections/models/inspection.dart';

sealed class InspectionState extends Equatable {
  const InspectionState();

  @override
  List<Object?> get props => const [];
}

enum InspectionSaveStatus { saved, unsaved, saving, error }

final class InspectionInitial extends InspectionState {
  const InspectionInitial();
}

final class InspectionLoading extends InspectionState {
  const InspectionLoading();
}

final class InspectionLoaded extends InspectionState {
  const InspectionLoaded(
    this.inspection, {
    this.saveStatus = InspectionSaveStatus.saved,
    this.saveError,
  });

  final Inspection inspection;
  final InspectionSaveStatus saveStatus;
  final String? saveError;

  @override
  List<Object?> get props => [inspection, saveStatus, saveError];
}

final class InspectionSaving extends InspectionState {
  const InspectionSaving(this.inspection);

  final Inspection inspection;

  @override
  List<Object?> get props => [inspection];
}

final class InspectionGettingLocation extends InspectionState {
  const InspectionGettingLocation(this.inspection);

  final Inspection inspection;

  @override
  List<Object?> get props => [inspection];
}

final class InspectionSaveAndExitSuccess extends InspectionState {
  const InspectionSaveAndExitSuccess(this.inspection);

  final Inspection inspection;

  @override
  List<Object?> get props => [inspection];
}

final class InspectionSaveFailure extends InspectionState {
  const InspectionSaveFailure({
    required this.inspection,
    required this.message,
  });

  final Inspection inspection;
  final String message;

  @override
  List<Object?> get props => [inspection, message];
}

final class InspectionFailure extends InspectionState {
  const InspectionFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
