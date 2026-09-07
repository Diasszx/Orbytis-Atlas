import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:orbytis_atlas/features/auth/presentation/bloc/auth_state.dart';
import 'package:orbytis_atlas/features/work_orders/models/work_order.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/pages/work_order_details_page.dart';
import 'package:orbytis_atlas/features/work_orders/presentation/pages/work_orders_page.dart';

import '../../features/auth/presentation/pages/login_page.dart';

import 'page_transitions.dart';

final class AppRouter {
  AppRouter({required AuthBloc authBloc})
    : router = GoRouter(
        initialLocation: '/login',
        redirect: (context, state) {
          final authState = authBloc.state;

          final isAuthenticated = authState is AuthAuthenticated;
          final isGoingToLogin = state.matchedLocation == '/login';

          if (!isAuthenticated && !isGoingToLogin) {
            return '/login';
          }

          if (isAuthenticated && isGoingToLogin) {
            return 'work-orders';
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
            builder: (context, state) => const WorkOrdersPage(),
          ),
          GoRoute(
            path: '/work-orders/:id',
            pageBuilder: (context, state) {
              final workOrder = state.extra as WorkOrder;

              return slideTransitionPage(
                state: state,
                child: WorkOrderDetailsPage(workOrder: workOrder),
              );
            },
          ),
        ],
      );

  final GoRouter router;
}
