import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/core/auth/session_expired_notifier.dart';
import 'package:orbytis_atlas/core/network/dio_client.dart';
import 'package:orbytis_atlas/core/storage/secure_storage_service.dart';
import 'package:orbytis_atlas/features/work_orders/datasources/work_orders_remote_data_source.dart';
import 'package:orbytis_atlas/features/work_orders/models/work_order.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_orders_bloc.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_orders_event.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_orders_state.dart';
import 'package:orbytis_atlas/features/work_orders/repositories/work_orders_repository.dart';

import '../repositories/work_orders_repository_test.dart'
    show MockWorkOrdersLocalDataSource, MockWorkOrdersRemoteDataSource;

void main() {
  test('HTTP query sends one status and omits it for all orders', () async {
    final notifier = SessionExpiredNotifier();
    final client = DioClient(
      secureStorageService: SecureStorageService(),
      sessionExpiredNotifier: notifier,
    );
    final requests = <Uri>[];
    client.dio.interceptors.clear();
    client.dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          requests.add(options.uri);
          handler.resolve(
            Response<List<dynamic>>(
              requestOptions: options,
              statusCode: 200,
              data: [],
            ),
          );
        },
      ),
    );
    final source = WorkOrdersRemoteDataSourceImpl(dioClient: client);
    for (final status in [null, 'open', 'in_progress', 'done']) {
      await source.getWorkOrders(status: status);
      expect(requests.last.path, '/work-orders');
      expect(
        requests.last.queryParameters,
        status == null ? <String, String>{} : {'status': status},
      );
    }
    client.dio.close();
    notifier.dispose();
  });

  test('a slow previous filter does not replace the latest result', () async {
    final remote = MockWorkOrdersRemoteDataSource();
    final local = MockWorkOrdersLocalDataSource();
    final older = Completer<List<WorkOrder>>();
    final started = Completer<void>();
    when(() => remote.getWorkOrders(status: 'open')).thenAnswer((_) {
      started.complete();
      return older.future;
    });
    when(() => remote.getWorkOrders(status: 'done'))
        .thenAnswer((_) async => []);
    final bloc = WorkOrdersBloc(
      WorkOrdersRepository(remoteDataSource: remote, localDataSource: local),
    );
    bloc.add(const WorkOrdersRequested(status: 'open'));
    await started.future;
    final latest = bloc.stream.firstWhere((state) => state is WorkOrdersEmpty);
    bloc.add(const WorkOrdersRequested(status: 'done'));
    await latest;
    older.completeError(Exception('Old request failed'));
    await Future<void>.delayed(Duration.zero);
    expect(bloc.state, isA<WorkOrdersEmpty>());
    await bloc.close();
  });
}
