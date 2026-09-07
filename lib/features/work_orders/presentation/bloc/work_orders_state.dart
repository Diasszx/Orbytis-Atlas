import 'package:equatable/equatable.dart';
import 'package:orbytis_atlas/features/work_orders/models/work_order.dart';

sealed class WorkOrdersState extends Equatable {
  const WorkOrdersState();

  @override
  List<Object?> get props => const [];
}

final class WorkOrdersInitial extends WorkOrdersState {
  const WorkOrdersInitial();
}

final class WorkOrdersLoading extends WorkOrdersState {
  const WorkOrdersLoading();
}

final class WorkOrdersLoaded extends WorkOrdersState {
  WorkOrdersLoaded({required List<WorkOrder> workOrders})
    : workOrders = List.unmodifiable(workOrders);

  final List<WorkOrder> workOrders;

  @override
  List<Object?> get props => [workOrders];
}

final class WorkOrdersEmpty extends WorkOrdersState {
  const WorkOrdersEmpty();
}

final class WorkOrdersFailure extends WorkOrdersState {
  const WorkOrdersFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
