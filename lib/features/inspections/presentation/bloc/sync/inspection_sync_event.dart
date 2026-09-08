import 'package:equatable/equatable.dart';

sealed class InspectionSyncEvent extends Equatable {
  const InspectionSyncEvent();

  @override
  List<Object?> get props => const [];
}

final class InspectionSyncRequested extends InspectionSyncEvent {
  const InspectionSyncRequested(this.clientId);

  final String clientId;

  @override
  List<Object?> get props => [clientId];
}
