import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';

final class AppRouter {
  AppRouter();

  final GoRouter router = GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(path: '/', redirect: (_, _) => '/login'),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    ],
  );
}
