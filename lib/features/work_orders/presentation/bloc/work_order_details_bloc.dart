import 'package:flutter_bloc/flutter_bloc.dart';

import '../../errors/work_orders_exception.dart';
import '../../repositories/work_orders_repository.dart';
import 'work_order_details_event.dart';
import 'work_order_details_state.dart';

final class WorkOrderDetailsBloc
    extends Bloc<WorkOrderDetailsEvent, WorkOrderDetailsState> {
  WorkOrderDetailsBloc(this._workOrdersRepository)
    : super(const WorkOrderDetailsInitial()) {
    on<WorkOrderDetailsRequested>(_onWorkOrderDetailsRequested);
  }

  final WorkOrdersRepository _workOrdersRepository;

  Future<void> _onWorkOrderDetailsRequested(
    WorkOrderDetailsRequested event,
    Emitter<WorkOrderDetailsState> emit,
  ) async {
    emit(const WorkOrderDetailsLoading());

    try {
      final workOrder = await _workOrdersRepository.getWorkOrderById(event.id);
      emit(WorkOrderDetailsLoaded(workOrder));
    } on WorkOrdersException catch (error) {
      emit(WorkOrderDetailsFailure(error.message));
    } catch (_) {
      emit(
        const WorkOrderDetailsFailure(
          'Não foi possível carregar a ordem de serviço.',
        ),
      );
    }
  }
}
