import 'package:equatable/equatable.dart';

sealed class InspectionEvent extends Equatable {
  const InspectionEvent();

  @override
  List<Object?> get props => const [];
}

final class InspectionRequested extends InspectionEvent {
  const InspectionRequested(this.clientId);

  final String clientId;

  @override
  List<Object?> get props => [clientId];
}

final class InspectionObservationChanged extends InspectionEvent {
  const InspectionObservationChanged(this.observation);

  final String observation;

  @override
  List<Object?> get props => [observation];
}

final class InspectionDraftSaved extends InspectionEvent {
  const InspectionDraftSaved();
}

final class InspectionPhotoRequested extends InspectionEvent {
  const InspectionPhotoRequested();
}

final class InspectionLocationRequested extends InspectionEvent {
  const InspectionLocationRequested();
}
