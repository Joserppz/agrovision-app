import 'package:get/get.dart';
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
import '../core/bindings.dart';
import '../core/constants.dart';

class AgroPages {
  AgroPages._();

  static final pages = [
    GetPage(
      name:    AgroRoutes.home,
      page:    () => const HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name:    AgroRoutes.camera,
      page:    () => const CameraScreen(),
      binding: CameraBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name:    AgroRoutes.loading,
      page:    () => const LoadingScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name:    AgroRoutes.results,
      page:    () => const ResultsScreen(),
      binding: ResultsBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name:    AgroRoutes.map,
      page:    () => const MapScreen(),
      binding: MapBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name:    AgroRoutes.history,
      page:    () => const HistoryScreen(),
      binding: HistoryBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name:    AgroRoutes.forum,
      page:    () => const ForumScreen(),
      binding: ForumBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name:    AgroRoutes.forumPost,
      page:    () => const ForumPostScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name:    AgroRoutes.login,
      page:    () => const LoginScreen(),
      binding: AuthBinding(),
      transition: Transition.downToUp,
    ),
    GetPage(
      name:    AgroRoutes.profile,
      page:    () => const ProfileScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}