import 'package:dio/dio.dart';
import 'package:orbytis_atlas/core/network/dio_client.dart';
import 'package:orbytis_atlas/core/network/dio_exception_mapper.dart';
import 'package:orbytis_atlas/features/work_orders/models/work_order.dart';

final class WorkOrdersRemoteDataSource {
  WorkOrdersRemoteDataSource({required DioClient dioClient})
    : _dio = dioClient.dio;

  final Dio _dio;

  Future<WorkOrder> getWorkOrderById(String id) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>('/work-orders/$id');

      final data = response.data;

      if (data == null) {
        throw const FormatException('Invalid work order response');
      }

      return WorkOrder.fromJson(data);
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }

  Future<List<WorkOrder>> getWorkOrders({String? status}) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        '/work-orders',
        queryParameters: {'status': ?status},
      );

      final data = response.data;

      if (data == null) {
        throw const FormatException('Invalid work orders response');
      }

      return data.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid work order data');
        }

        return WorkOrder.fromJson(item);
      }).toList();
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
