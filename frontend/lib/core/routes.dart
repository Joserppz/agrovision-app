import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../screens/home_screen.dart';
import '../screens/camera_screen.dart';
import '../screens/loading_screen.dart';
import '../screens/results_screen.dart';
import '../screens/map_screen.dart';
import '../screens/history_screen.dart';
import '../screens/forum_screen.dart';
import '../screens/forum_post_screen.dart';
import '../screens/login_screen.dart';
import '../screens/profile_screen.dart';
import '../core/constants.dart';

// Este Provider expone tu enrutador a toda la app
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AgroRoutes.home, 
    routes: [
      GoRoute(
        path: AgroRoutes.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AgroRoutes.camera,
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: AgroRoutes.loading,
        builder: (context, state) => const LoadingScreen(),
      ),
      GoRoute(
        path: AgroRoutes.results,
        builder: (context, state) => const ResultsScreen(),
      ),
      GoRoute(
        path: AgroRoutes.map,
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: AgroRoutes.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AgroRoutes.forum,
        builder: (context, state) => const ForumScreen(),
      ),
      GoRoute(
        path: AgroRoutes.forumPost,
        builder: (context, state) => const ForumPostScreen(),
      ),
      GoRoute(
        path: AgroRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AgroRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});