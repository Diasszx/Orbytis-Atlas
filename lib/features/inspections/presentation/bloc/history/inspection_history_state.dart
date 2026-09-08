import 'package:equatable/equatable.dart';

import '../../../models/inspection.dart';

enum InspectionHistoryFilter { all, draft, pending, synced, failed }

sealed class InspectionHistoryState extends Equatable {
  const InspectionHistoryState();

  @override
  List<Object?> get props => const [];
}

final class InspectionHistoryInitial extends InspectionHistoryState {
  const InspectionHistoryInitial();
}

final class InspectionHistoryLoading extends InspectionHistoryState {
  const InspectionHistoryLoading();
}

final class InspectionHistoryLoaded extends InspectionHistoryState {
  const InspectionHistoryLoaded({
    required this.inspections,
    required this.filter,
    this.retryingClientId,
    this.feedbackMessage,
  });

  final List<Inspection> inspections;
  final InspectionHistoryFilter filter;
  final String? retryingClientId;
  final String? feedbackMessage;

  @override
  List<Object?> get props => [
    inspections,
    filter,
    retryingClientId,
    feedbackMessage,
  ];
}

final class InspectionHistoryFailure extends InspectionHistoryState {
  const InspectionHistoryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
