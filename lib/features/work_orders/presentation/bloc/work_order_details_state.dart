import 'package:equatable/equatable.dart';

import '../../models/work_order.dart';

sealed class WorkOrderDetailsState extends Equatable {
  const WorkOrderDetailsState();

  @override
  List<Object?> get props => const [];
}

final class WorkOrderDetailsInitial extends WorkOrderDetailsState {
  const WorkOrderDetailsInitial();
}

final class WorkOrderDetailsLoading extends WorkOrderDetailsState {
  const WorkOrderDetailsLoading();
}

final class WorkOrderDetailsLoaded extends WorkOrderDetailsState {
  const WorkOrderDetailsLoaded(this.workOrder);

  final WorkOrder workOrder;

  @override
  List<Object?> get props => [workOrder];
}

final class WorkOrderDetailsFailure extends WorkOrderDetailsState {
  const WorkOrderDetailsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
