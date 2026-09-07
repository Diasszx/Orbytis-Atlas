import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:orbytis_atlas/app/theme/app_theme.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_state.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_orders_bloc.dart';

final class OrbytisAtlasApp extends StatelessWidget {
  const OrbytisAtlasApp({
    required this.authBloc,
    required this.router,
    required this.workOrdersBloc,
    super.key,
  });

  final AuthBloc authBloc;
  final GoRouter router;
  final WorkOrdersBloc workOrdersBloc;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: authBloc),
        BlocProvider.value(value: workOrdersBloc),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (_, _) {
          router.refresh();
        },
        child: MaterialApp.router(
          title: 'Orbytis Atlas',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: ThemeMode.system,
          routerConfig: router,
        ),
      ),
    );
  }
}
