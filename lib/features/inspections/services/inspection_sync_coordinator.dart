import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

import '../repositories/inspections_repository.dart';

final class InspectionSyncCoordinator with WidgetsBindingObserver {
  InspectionSyncCoordinator({
    required InspectionsRepository inspectionsRepository,
    Connectivity? connectivity,
  }) : _inspectionsRepository = inspectionsRepository,
       _connectivity = connectivity ?? Connectivity();

  final InspectionsRepository _inspectionsRepository;
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _started = false;
  bool _isSyncing = false;
  bool _syncRequested = false;

  Future<void> start() async {
    if (_started) {
      return;
    }

    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _subscription = _connectivity.onConnectivityChanged.listen(
      _onConnectivityChanged,
    );

    await _checkConnectivityAndSync();
  }

  Future<void> stop() async {
    if (!_started) {
      return;
    }

    _started = false;
    _syncRequested = false;
    WidgetsBinding.instance.removeObserver(this);
    await _subscription?.cancel();
    _subscription = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_checkConnectivityAndSync());
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    if (_hasNetwork(results)) {
      unawaited(_syncPendingInspections());
    }
  }

  Future<void> _checkConnectivityAndSync() async {
    try {
      final results = await _connectivity.checkConnectivity();

      if (_hasNetwork(results)) {
        await _syncPendingInspections();
      }
    } catch (_) {
      // Connectivity é apenas um gatilho; a requisição HTTP é a fonte de
      // verdade sobre conectividade e erros são persistidos pelo Repository.
    }
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _syncPendingInspections() async {
    if (!_started) {
      return;
    }

    _syncRequested = true;
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;

    try {
      do {
        _syncRequested = false;
        try {
          await _inspectionsRepository.syncPendingInspections();
        } catch (_) {
          // Só repetimos se outro gatilho tiver solicitado uma nova passagem.
        }
      } while (_started && _syncRequested);
    } finally {
      _isSyncing = false;
    }
  }
}
