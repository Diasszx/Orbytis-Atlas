import 'package:equatable/equatable.dart';

sealed class WorkOrdersEvent extends Equatable {
  const WorkOrdersEvent();

  @override
  List<Object?> get props => const [];
}

final class WorkOrdersRequested extends WorkOrdersEvent {
  const WorkOrdersRequested({this.status});

  final String? status;

  @override
  List<Object?> get props => [status];
}

final class WorkOrdersRefreshed extends WorkOrdersEvent {
  const WorkOrdersRefreshed({this.status});

  final String? status;

  @override
  List<Object?> get props => [status];
}
