import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/network/dio_exception_mapper.dart';
import '../models/inspection.dart';

final class InspectionsRemoteDataSource {
  InspectionsRemoteDataSource({required DioClient dioClient})
    : _dio = dioClient.dio;

  final Dio _dio;

  Future<String> submitInspection(Inspection inspection) async {
    final photoPath = inspection.photoPath;
    final observation = inspection.observation;
    final latitude = inspection.latitude;
    final longitude = inspection.longitude;
    final capturedAt = inspection.capturedAt;

    if (photoPath == null ||
        observation == null ||
        latitude == null ||
        longitude == null ||
        capturedAt == null) {
      throw const FormatException('Inspection data is incomplete');
    }

    try {
      final formData = FormData.fromMap({
        'clientId': inspection.clientId,
        'workOrderId': inspection.workOrderId,
        'observation': observation,
        if (inspection.condition != null) 'condition': inspection.condition,
        'latitude': latitude,
        'longitude': longitude,
        'capturedAt': capturedAt.toIso8601String(),
        'photo': await MultipartFile.fromFile(photoPath),
      });

      final response = await _dio.post<Map<String, dynamic>>(
        '/inspections',
        data: formData,
      );
      final serverId = response.data?['id'];

      if (serverId is! String) {
        throw const FormatException('Invalid inspection server id');
      }

      return serverId;
    } on DioException catch (error) {
      throw mapDioException(error);
    }
  }
}
