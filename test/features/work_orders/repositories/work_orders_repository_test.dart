import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:orbytis_atlas/core/errors/network_exception.dart';
import 'package:orbytis_atlas/features/work_orders/datasources/work_orders_local_data_source.dart';
import 'package:orbytis_atlas/features/work_orders/datasources/work_orders_remote_data_source.dart';
import 'package:orbytis_atlas/features/work_orders/errors/work_orders_exception.dart';
import 'package:orbytis_atlas/features/work_orders/models/work_order.dart';
import 'package:orbytis_atlas/features/work_orders/repositories/work_orders_repository.dart';

final class MockWorkOrdersRemoteDataSource extends Mock
    implements WorkOrdersRemoteDataSource {}

final class MockWorkOrdersLocalDataSource extends Mock
    implements WorkOrdersLocalDataSource {}

void main() {
  late MockWorkOrdersRemoteDataSource remoteDataSource;
  late MockWorkOrdersLocalDataSource localDataSource;
  late WorkOrdersRepository repository;

  setUpAll(() {
    registerFallbackValue(<WorkOrder>[]);
  });

  setUp(() {
    remoteDataSource = MockWorkOrdersRemoteDataSource();
    localDataSource = MockWorkOrdersLocalDataSource();
    repository = WorkOrdersRepository(
      remoteDataSource: remoteDataSource,
      localDataSource: localDataSource,
    );
  });

  group('getWorkOrders', () {
    test('returns remote work orders and updates cache when API succeeds', () async {
      final workOrders = [_buildWorkOrder()];
      when(() => remoteDataSource.getWorkOrders()).thenAnswer(
        (_) async => workOrders,
      );
      when(() => localDataSource.saveWorkOrders(any())).thenAnswer((_) async {});

      final result = await repository.getWorkOrders();

      expect(result, workOrders);
      verify(() => localDataSource.saveWorkOrders(workOrders)).called(1);
    });

    test('returns cached work orders when connection fails', () async {
      final cachedWorkOrders = [_buildWorkOrder()];
      when(() => remoteDataSource.getWorkOrders()).thenThrow(
        const NetworkException(type: NetworkErrorType.connection),
      );
      when(() => localDataSource.hasCachedWorkOrders).thenReturn(true);
      when(() => localDataSource.getWorkOrders()).thenReturn(cachedWorkOrders);

      final result = await repository.getWorkOrders();

      expect(result, cachedWorkOrders);
      verify(() => localDataSource.getWorkOrders()).called(1);
    });

    test('throws WorkOrdersException when connection fails and cache is empty', () async {
      when(() => remoteDataSource.getWorkOrders()).thenThrow(
        const NetworkException(type: NetworkErrorType.connection),
      );
      when(() => localDataSource.hasCachedWorkOrders).thenReturn(false);

      expect(
        () => repository.getWorkOrders(),
        throwsA(isA<WorkOrdersException>()),
      );
      verifyNever(() => localDataSource.getWorkOrders());
    });

    test('does not use cache when API returns unauthorized', () async {
      when(() => remoteDataSource.getWorkOrders()).thenThrow(
        const NetworkException(
          type: NetworkErrorType.unauthorized,
          statusCode: 401,
        ),
      );

      expect(
        () => repository.getWorkOrders(),
        throwsA(isA<WorkOrdersException>()),
      );
      verifyNever(() => localDataSource.getWorkOrders());
    });
  });

  group('getWorkOrderById', () {
    test('returns cached work order when detail request fails by connection', () async {
      final cachedWorkOrder = _buildWorkOrder();
      when(
        () => remoteDataSource.getWorkOrderById(cachedWorkOrder.id),
      ).thenThrow(const NetworkException(type: NetworkErrorType.connection));
      when(
        () => localDataSource.getWorkOrderById(cachedWorkOrder.id),
      ).thenReturn(cachedWorkOrder);

      final result = await repository.getWorkOrderById(cachedWorkOrder.id);

      expect(result.id, cachedWorkOrder.id);
      expect(result.code, 'OS-2026-001');
      verify(
        () => localDataSource.getWorkOrderById(cachedWorkOrder.id),
      ).called(1);
    });

    test('does not load cached detail when request is unauthorized', () async {
      const id = 'wo_1001';
      when(() => remoteDataSource.getWorkOrderById(id)).thenThrow(
        const NetworkException(
          type: NetworkErrorType.unauthorized,
          statusCode: 401,
        ),
      );

      expect(
        () => repository.getWorkOrderById(id),
        throwsA(isA<WorkOrdersException>()),
      );
      verifyNever(() => localDataSource.getWorkOrderById(id));
    });
  });
}

WorkOrder _buildWorkOrder() {
  return WorkOrder(
    id: 'wo_1001',
    code: 'OS-2026-001',
    title: 'Inspeção de poste',
    description: 'Verificar estado do poste.',
    address: 'Rua das Acácias, 120',
    priority: 'high',
    status: 'open',
    latitude: -7.1195,
    longitude: -34.8450,
    scheduledAt: DateTime(2026, 9, 8, 13),
    updatedAt: DateTime(2026, 9, 8, 10),
  );
}
