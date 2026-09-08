import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../repositories/inspections_repository.dart';

final class InspectionSyncCoordinator {
  InspectionSyncCoordinator({
    required InspectionsRepository inspectionsRepository,
    Connectivity? connectivity,
  }) : _inspectionsRepository = inspectionsRepository,
       _connectivity = connectivity ?? Connectivity();

  final InspectionsRepository _inspectionsRepository;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  void start() {
    _subscription ??= _connectivity.onConnectivityChanged.listen((results) {
      if (results.any((result) => result != ConnectivityResult.none)) {
        _trySyncPendingInspections();
      }
    });

    _trySyncPendingInspections();
  }

  Future<void> _trySyncPendingInspections() async {
    try {
      await _inspectionsRepository.syncPendingInspections();
    } catch (_) {
      // A próxima alteração de rede realizará outra tentativa. A resposta HTTP
      // continua sendo a fonte de verdade sobre a conectividade.
    }
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }
}
