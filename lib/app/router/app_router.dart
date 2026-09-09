import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_state.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/forms/inspection_event.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/history/inspection_history_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/history/inspection_history_event.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/inspection_start_bloc.dart';
import 'package:orbytis_atlas/features/inspections/presentation/bloc/sync/inspection_queue_cubit.dart';
import 'package:orbytis_atlas/features/inspections/presentation/pages/inspection_history_page.dart';
import 'package:orbytis_atlas/features/inspections/presentation/pages/inspection_page.dart';
import 'package:orbytis_atlas/features/inspections/repositories/inspections_repository.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_order_details_bloc.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/bloc/work_order_details_event.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/pages/work_order_details_page.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/pages/work_orders_page.dart';
import 'package:orbytis_atlas/features/work_orders/repositories/work_orders_repository.dart';

import '../../features/auth/presentation/pages/login_page.dart';

import 'page_transitions.dart';

final class AppRouter {
  AppRouter({
    required AuthBloc authBloc,
    required WorkOrdersRepository workOrdersRepository,
    required InspectionsRepository inspectionsRepository,
  }) : router = GoRouter(
         initialLocation: '/login',
         redirect: (context, state) {
           final authState = authBloc.state;

           final isAuthenticated = authState is AuthAuthenticated;
           final isGoingToLogin = state.matchedLocation == '/login';

           if (!isAuthenticated && !isGoingToLogin) {
             return '/login';
           }

           if (isAuthenticated && isGoingToLogin) {
             return '/work-orders';
           }

           return null;
         },
         routes: [
           GoRoute(path: '/', redirect: (_, _) => '/work-orders'),
           GoRoute(
             path: '/login',
             builder: (context, state) => const LoginPage(),
           ),
           GoRoute(
             path: '/work-orders',
             builder: (context, state) => BlocProvider(
               create: (_) => InspectionQueueCubit(inspectionsRepository),
               child: RepositoryProvider.value(
                 value: inspectionsRepository,
                 child: const WorkOrdersPage(),
               ),
             ),
           ),
           GoRoute(
             path: '/work-orders/:id',
             pageBuilder: (context, state) {
               final id = state.pathParameters['id']!;

               return slideTransitionPage(
                 state: state,
                 child: MultiBlocProvider(
                   providers: [
                     BlocProvider(
                       create: (_) =>
                           WorkOrderDetailsBloc(workOrdersRepository)
                             ..add(WorkOrderDetailsRequested(id)),
                     ),
                     BlocProvider(
                       create: (_) =>
                           InspectionStartBloc(inspectionsRepository),
                     ),
                   ],
                   child: RepositoryProvider.value(
                     value: inspectionsRepository,
                     child: const WorkOrderDetailsPage(),
                   ),
                 ),
               );
             },
           ),
           GoRoute(
             path: '/inspections',
             pageBuilder: (context, state) {
               return slideTransitionPage(
                 state: state,
                 child: BlocProvider(
                   create: (_) => InspectionHistoryBloc(
                     inspectionsRepository,
                     workOrderId: state.uri.queryParameters['workOrderId'],
                   )..add(const InspectionHistoryRequested()),
                   child: const InspectionHistoryPage(),
                 ),
               );
             },
           ),
           GoRoute(
             path: '/inspections/:clientId',
             pageBuilder: (context, state) {
               final clientId = state.pathParameters['clientId']!;

               return slideTransitionPage(
                 state: state,
                 child: MultiBlocProvider(
                   providers: [
                     BlocProvider(
                       create: (_) =>
                           InspectionBloc(inspectionsRepository)
                             ..add(InspectionRequested(clientId)),
                     ),
                   ],
                   child: const InspectionPage(),
                 ),
               );
             },
           ),
         ],
       );

  final GoRouter router;
}
