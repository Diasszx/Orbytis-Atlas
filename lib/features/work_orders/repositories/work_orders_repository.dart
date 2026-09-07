import 'package:orbytis_atlas/core/errors/network_exception.dart';
import 'package:orbytis_atlas/features/work_orders/datasources/work_orders_local_data_source.dart';
import 'package:orbytis_atlas/features/work_orders/datasources/work_orders_remote_data_source.dart';
import 'package:orbytis_atlas/features/work_orders/errors/work_orders_exception.dart';
import 'package:orbytis_atlas/features/work_orders/models/work_order.dart';

final class WorkOrdersRepository {
  WorkOrdersRepository({
    required WorkOrdersRemoteDataSource remoteDataSource,
    required WorkOrdersLocalDataSource localDataSource,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource;

  final WorkOrdersRemoteDataSource _remoteDataSource;
  final WorkOrdersLocalDataSource _localDataSource;

  Future<List<WorkOrder>> getWorkOrders({String? status}) async {
    try {
      final workOrders = await _remoteDataSource.getWorkOrders(status: status);

      if (status == null) {
        await _localDataSource.saveWorkOrders(workOrders);
      }

      return workOrders;
    } on NetworkException catch (error) {
      if (error.type == NetworkErrorType.unauthorized) {
        throw _mapNetworkError(error);
      }

      if (_localDataSource.hasCachedWorkOrders) {
        try {
          final cachedWorkOrders = _localDataSource.getWorkOrders();

          if (status == null) {
            return cachedWorkOrders;
          }

          return cachedWorkOrders
              .where((workOrder) => workOrder.status == status)
              .toList();
        } on FormatException {
          throw const WorkOrdersException(
            'Os dados locais das ordens de serviço são inválidos.',
          );
        }
      }

      throw _mapNetworkError(error);
    } on FormatException {
      throw const WorkOrdersException(
        'Os dados das ordens de serviço são inválidos.',
      );
    }
  }

  WorkOrdersException _mapNetworkError(NetworkException error) {
    switch (error.type) {
      case NetworkErrorType.unauthorized:
        return const WorkOrdersException(
          'Sua sessão expirou. Faça login novamente.',
        );

      case NetworkErrorType.timeout:
        return const WorkOrdersException(
          'Tempo de conexão excedido. Tente novamente.',
        );

      case NetworkErrorType.connection:
        return const WorkOrdersException(
          'Não foi possível conectar ao servidor.',
        );

      case NetworkErrorType.badResponse:
        return const WorkOrdersException(
          'Não foi possível carregar as ordens de serviço.',
        );

      case NetworkErrorType.cancelled:
        return const WorkOrdersException('A solicitação foi cancelada.');

      case NetworkErrorType.badCertificate:
        return const WorkOrdersException(
          'Não foi possível estabelecer uma conexão segura.',
        );

      case NetworkErrorType.unknown:
        return const WorkOrdersException(
          'Ocorreu um erro inesperado ao carregar as ordens.',
        );
    }
  }
}
