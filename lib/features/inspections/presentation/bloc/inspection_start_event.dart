import 'package:equatable/equatable.dart';

sealed class InspectionStartEvent extends Equatable {
  const InspectionStartEvent();

  @override
  List<Object?> get props => const [];
}

final class InspectionStartRequested extends InspectionStartEvent {
  const InspectionStartRequested(this.workOrderId);

  final String workOrderId;

  @override
  List<Object?> get props => [workOrderId];
}
