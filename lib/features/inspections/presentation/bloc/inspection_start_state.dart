import 'package:equatable/equatable.dart';

sealed class InspectionStartState extends Equatable {
  const InspectionStartState();

  @override
  List<Object?> get props => const [];
}

final class InspectionStartInitial extends InspectionStartState {
  const InspectionStartInitial();
}

final class InspectionStartLoading extends InspectionStartState {
  const InspectionStartLoading();
}

final class InspectionStartSuccess extends InspectionStartState {
  const InspectionStartSuccess(this.clientId);

  final String clientId;

  @override
  List<Object?> get props => [clientId];
}

final class InspectionStartFailure extends InspectionStartState {
  const InspectionStartFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
