import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orbytis_atlas/features/work_orders/errors/work_orders_exception.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_orders_event.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_orders_state.dart';
import 'package:orbytis_atlas/features/work_orders/repositories/work_orders_repository.dart';

final class WorkOrdersBloc extends Bloc<WorkOrdersEvent, WorkOrdersState> {
  WorkOrdersBloc(this._workOrdersRepository)
    : super(const WorkOrdersInitial()) {
    on<WorkOrdersRequested>(_onWorkOrdersRequested);
    on<WorkOrdersRefreshed>(_onWorkOrdersRefreshed);
  }

  final WorkOrdersRepository _workOrdersRepository;

  Future<void> _onWorkOrdersRequested(
    WorkOrdersRequested event,
    Emitter<WorkOrdersState> emit,
  ) async {
    emit(const WorkOrdersLoading());

    await _loadWorkOrders(status: event.status, emit: emit);
  }

  Future<void> _onWorkOrdersRefreshed(
    WorkOrdersRefreshed event,
    Emitter<WorkOrdersState> emit,
  ) async {
    emit(const WorkOrdersLoading());
    await _loadWorkOrders(status: event.status, emit: emit);
  }

  Future<void> _loadWorkOrders({
    required String? status,
    required Emitter<WorkOrdersState> emit,
  }) async {
    try {
      final workOrders = await _workOrdersRepository.getWorkOrders(
        status: status,
      );

      if (workOrders.isEmpty) {
        emit(const WorkOrdersEmpty());
        return;
      }

      emit(WorkOrdersLoaded(workOrders: workOrders));
    } on WorkOrdersException catch (error) {
      emit(WorkOrdersFailure(error.message));
    } catch (_) {
      emit(
        const WorkOrdersFailure(
          'Não foi possível carregar as ordens de serviço.',
        ),
      );
    }
  }
}
