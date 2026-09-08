import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../errors/inspections_exception.dart';
import '../../../models/inspection_sync_status.dart';
import '../../../repositories/inspections_repository.dart';

final class InspectionQueueState {
  const InspectionQueueState({this.isSyncing = false, this.message});

  final bool isSyncing;
  final String? message;
}

final class InspectionQueueCubit extends Cubit<InspectionQueueState> {
  InspectionQueueCubit(this._repository) : super(const InspectionQueueState());

  final InspectionsRepository _repository;

  Future<void> synchronize() async {
    if (state.isSyncing) return;
    emit(const InspectionQueueState(isSyncing: true));
    String message;
    try {
      final pendingIds = _repository
          .getInspections()
          .where((item) => item.syncStatus == InspectionSyncStatus.pending)
          .map((item) => item.clientId)
          .toSet();
      if (pendingIds.isEmpty) {
        message = 'Nenhuma inspeção pendente. Consulte as falhas no histórico.';
      } else {
        await _repository.syncPendingInspections();
        final results = _repository.getInspections().where(
          (item) => pendingIds.contains(item.clientId),
        );
        final synced = results
            .where((item) => item.syncStatus == InspectionSyncStatus.synced)
            .length;
        final pending = results
            .where((item) => item.syncStatus == InspectionSyncStatus.pending)
            .length;
        final failed = results
            .where((item) => item.syncStatus == InspectionSyncStatus.failed)
            .length;
        message =
            '$synced sincronizada(s), $pending pendente(s), $failed com falha. '
            'Consulte os detalhes no histórico.';
      }
    } on InspectionsException catch (error) {
      message = error.message;
    } catch (_) {
      message = 'Não foi possível sincronizar. Tente novamente.';
    }
    if (!isClosed) emit(InspectionQueueState(message: message));
  }
}
