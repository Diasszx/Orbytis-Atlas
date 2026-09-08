import 'package:equatable/equatable.dart';

import '../../../models/inspection.dart';

sealed class InspectionSyncState extends Equatable {
  const InspectionSyncState();

  @override
  List<Object?> get props => const [];
}

final class InspectionSyncInitial extends InspectionSyncState {
  const InspectionSyncInitial();
}

final class InspectionSyncLoading extends InspectionSyncState {
  const InspectionSyncLoading();
}

final class InspectionSyncSuccess extends InspectionSyncState {
  const InspectionSyncSuccess(this.inspection);

  final Inspection inspection;

  @override
  List<Object?> get props => [inspection];
}

final class InspectionSyncPending extends InspectionSyncState {
  const InspectionSyncPending({
    required this.inspection,
    required this.message,
  });

  final Inspection inspection;
  final String message;

  @override
  List<Object?> get props => [inspection, message];
}

final class InspectionSyncFailure extends InspectionSyncState {
  const InspectionSyncFailure({this.inspection, required this.message});

  final Inspection? inspection;
  final String message;

  @override
  List<Object?> get props => [inspection, message];
}
