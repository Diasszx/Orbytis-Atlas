import 'package:flutter/material.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';
import 'package:orbytis_atlas/app/app.dart';
import 'package:orbytis_atlas/app/router/app_router.dart';
import 'package:orbytis_atlas/core/auth/session_expired_notifier.dart';
import 'package:orbytis_atlas/core/network/dio_client.dart';
import 'package:orbytis_atlas/core/storage/hive_boxes.dart';
import 'package:orbytis_atlas/core/storage/secure_storage_service.dart';
import 'package:orbytis_atlas/features/auth/datasources/auth_remote_data_source.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_event.dart';
import 'package:orbytis_atlas/features/auth/repositories/auth_repository.dart';
import 'package:orbytis_atlas/features/work_orders/datasources/work_orders_local_data_source.dart';
import 'package:orbytis_atlas/features/work_orders/datasources/work_orders_remote_data_source.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_orders_bloc.dart';
import 'package:orbytis_atlas/features/work_orders/repositories/work_orders_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  final workOrdersBox = await Hive.openBox<String>(HiveBoxes.workOrders);

  final workOrdersLocalDataSource = WorkOrdersLocalDataSource(
    box: workOrdersBox,
  );

  final secureStorageService = SecureStorageService();

  final sessionExpiredNotifier = SessionExpiredNotifier();

  final dioClient = DioClient(
    secureStorageService: secureStorageService,
    sessionExpiredNotifier: sessionExpiredNotifier,
  );

  final authRemoteDataSource = AuthRemoteDataSource(dioClient: dioClient);

  final authRepository = AuthRepository(
    remoteDataSource: authRemoteDataSource,
    secureStorageService: secureStorageService,
  );

  final authBloc = AuthBloc(authRepository, sessionExpiredNotifier);
  authBloc.add(const AuthSessionChecked());

  final workOrdersRemoteDataSource = WorkOrdersRemoteDataSource(
    dioClient: dioClient,
  );

  final workOrdersRepository = WorkOrdersRepository(
    remoteDataSource: workOrdersRemoteDataSource,
    localDataSource: workOrdersLocalDataSource,
  );

  final appRouter = AppRouter(
    authBloc: authBloc,
    workOrdersRepository: workOrdersRepository,
  );

  final workOrdersBloc = WorkOrdersBloc(workOrdersRepository);

  runApp(
    OrbytisAtlasApp(
      authBloc: authBloc,
      router: appRouter.router,
      workOrdersBloc: workOrdersBloc,
    ),
  );
}
