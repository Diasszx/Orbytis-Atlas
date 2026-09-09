import 'package:equatable/equatable.dart';

import 'inspection_history_state.dart';

sealed class InspectionHistoryEvent extends Equatable {
  const InspectionHistoryEvent();

  @override
  List<Object?> get props => const [];
}

final class InspectionHistoryRequested extends InspectionHistoryEvent {
  const InspectionHistoryRequested();
}

final class InspectionHistoryUpdated extends InspectionHistoryEvent {
  const InspectionHistoryUpdated();
}

final class InspectionHistoryFilterChanged extends InspectionHistoryEvent {
  const InspectionHistoryFilterChanged(this.filter);

  final InspectionHistoryFilter filter;

  @override
  List<Object?> get props => [filter];
}

final class InspectionHistoryRetryRequested extends InspectionHistoryEvent {
  const InspectionHistoryRetryRequested(this.clientId);

  final String clientId;

  @override
  List<Object?> get props => [clientId];
}
