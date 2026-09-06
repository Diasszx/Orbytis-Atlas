import 'package:flutter/material.dart';
import 'package:orbytis_atlas/app/app.dart';
import 'package:orbytis_atlas/app/router/app_router.dart';
import 'package:orbytis_atlas/core/network/dio_client.dart';
import 'package:orbytis_atlas/core/storage/secure_storage_service.dart';
import 'package:orbytis_atlas/features/auth/datasources/auth_remote_data_source.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_event.dart';
import 'package:orbytis_atlas/features/auth/repositories/auth_repository.dart';

void main() {
  final secureStorageService = SecureStorageService();

  final dioClient = DioClient(secureStorageService: secureStorageService);

  final authRemoteDataSource = AuthRemoteDataSource(dioClient: dioClient);

  final authRepository = AuthRepository(
    remoteDataSource: authRemoteDataSource,
    secureStorageService: secureStorageService,
  );

  final authBloc = AuthBloc(authRepository);
  authBloc.add(const AuthSessionChecked());

  final appRouter = AppRouter(authBloc: authBloc);

  runApp(OrbytisAtlasApp(authBloc: authBloc, router: appRouter.router));
}
