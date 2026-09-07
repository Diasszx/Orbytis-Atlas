import 'package:orbytis_atlas/core/errors/network_exception.dart';
import 'package:orbytis_atlas/features/work_orders/datasources/work_orders_remote_data_source.dart';
import 'package:orbytis_atlas/features/work_orders/errors/work_orders_exception.dart';
import 'package:orbytis_atlas/features/work_orders/models/work_order.dart';

final class WorkOrdersRepository {
  WorkOrdersRepository({required WorkOrdersRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final WorkOrdersRemoteDataSource _remoteDataSource;

  Future<List<WorkOrder>> getWorkOrders({String? status}) async {
    try {
      return await _remoteDataSource.getWorkOrders(status: status);
    } on NetworkException catch (error) {
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
