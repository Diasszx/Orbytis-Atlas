import 'package:equatable/equatable.dart';

sealed class WorkOrderDetailsEvent extends Equatable {
  const WorkOrderDetailsEvent();

  @override
  List<Object?> get props => const [];
}

final class WorkOrderDetailsRequested extends WorkOrderDetailsEvent {
  const WorkOrderDetailsRequested(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
