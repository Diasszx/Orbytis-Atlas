import 'package:flutter/material.dart';
import 'package:orbytis_atlas/app/app.dart';
import 'package:orbytis_atlas/app/router/app_router.dart';
import 'package:orbytis_atlas/core/network/dio_client.dart';
import 'package:orbytis_atlas/core/storage/secure_storage_service.dart';
import 'package:orbytis_atlas/features/auth/datasources/auth_remote_data_source.dart';
import 'package:orbytis_atlas/features/auth/repositories/auth_repository.dart';

void main() {
  final secureStorageService = SecureStorageService();

  final dioClient = DioClient(secureStorageService: secureStorageService);

  final authRemoteDataSource = AuthRemoteDataSource(dioClient: dioClient);

  final appRouter = AppRouter();

  final authRepository = AuthRepository(
    remoteDataSource: authRemoteDataSource,
    secureStorageService: secureStorageService,
  );

  runApp(
    OrbytisAtlasApp(authRepository: authRepository, router: appRouter.router),
  );
}
