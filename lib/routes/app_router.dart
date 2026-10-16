import 'package:go_router/go_router.dart';

import '../screens/alerts_screen.dart';
import '../features/asset_management/presentation/asset_list_screen.dart';
import '../features/project_management/presentation/project_list_screen.dart';
import '../features/watchlist/presentation/watchlist_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/project_dashboard_screen.dart';
import '../screens/register_screen.dart';
import '../screens/scan_result_detail_screen.dart';

const bool _isAuthenticated = true;

final GoRouter appRouter = GoRouter(
  initialLocation: '/projects',
  redirect: (context, state) {
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';
    if (!_isAuthenticated && !isAuthRoute) return '/login';
    if (_isAuthenticated && isAuthRoute) return '/projects';
    return null;
  },
  routes: [
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(
        path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(
        path: '/projects',
        builder: (context, state) => const ProjectListScreen()),
    GoRoute(
        path: '/watchlist',
        builder: (context, state) => const WatchlistScreen()),
    GoRoute(
      path: '/projects/:id',
      builder: (context, state) =>
          ProjectDashboardScreen(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id/assets',
      builder: (context, state) =>
          AssetListScreen(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/projects/:id/scan-results/:assetId',
      builder: (context, state) =>
          ScanResultDetailScreen(assetId: state.pathParameters['assetId']!),
    ),
    GoRoute(
      path: '/projects/:id/alerts',
      builder: (context, state) =>
          AlertsScreen(projectId: state.pathParameters['id']!),
    ),
    GoRoute(
        path: '/profile', builder: (context, state) => const ProfileScreen()),
  ],
);
