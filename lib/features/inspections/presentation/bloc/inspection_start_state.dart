import 'package:equatable/equatable.dart';

import '../../models/inspection.dart';

sealed class InspectionState extends Equatable {
  const InspectionState();

  @override
  List<Object?> get props => const [];
}

final class InspectionInitial extends InspectionState {
  const InspectionInitial();
}

final class InspectionLoading extends InspectionState {
  const InspectionLoading();
}

final class InspectionLoaded extends InspectionState {
  const InspectionLoaded(this.inspection);

  final Inspection inspection;

  @override
  List<Object?> get props => [inspection];
}

final class InspectionSaving extends InspectionState {
  const InspectionSaving(this.inspection);

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
