import 'package:get/get.dart';
import '../controllers/connectivity_controller.dart';
import '../controllers/scan_controller.dart';
import '../controllers/map_controller.dart';
import '../controllers/history_controller.dart';
import '../controllers/forum_controller.dart';
import '../controllers/auth_controller.dart';
import '../services/api_service.dart';
import '../services/scan_service.dart';
import '../services/local_db_service.dart';
import '../services/location_service.dart';
import '../services/auth_service.dart';
import '../services/forum_service.dart';

// ─── Binding inicial — corre al arrancar la app ───────────────────────────────
// Solo lo que SIEMPRE se necesita desde el primer frame
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Servicios base — permanentes durante toda la sesión
    Get.put(ApiService(), permanent: true);
    Get.put(LocalDbService(), permanent: true);
    Get.put(AuthService(), permanent: true);

    // Conectividad — permanente, escucha siempre
    Get.put(ConnectivityController(), permanent: true);
  }
}

// ─── Bindings por pantalla — se crean lazy cuando se navega ──────────────────

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // nada extra — HomeScreen usa ConnectivityController que ya está
  }
}

class CameraBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LocationService());
    Get.lazyPut(() => ScanService(Get.find<ApiService>(), Get.find<LocalDbService>()));
    Get.lazyPut(() => ScanController(
      Get.find<ScanService>(),
      Get.find<LocationService>(),
      Get.find<ConnectivityController>(),
    ));
  }
}

class ResultsBinding extends Bindings {
  @override
  void dependencies() {
    // ScanController ya fue creado en CameraBinding
    // Solo nos aseguramos que exista
    if (!Get.isRegistered<ScanController>()) {
      Get.lazyPut(() => ScanController(
        Get.find<ScanService>(),
        Get.find<LocationService>(),
        Get.find<ConnectivityController>(),
      ));
    }
  }
}

class MapBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LocationService());
    Get.lazyPut(() => MapController(
      Get.find<LocalDbService>(),
      Get.find<LocationService>(),
    ));
  }
}

class HistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => HistoryController(Get.find<LocalDbService>()));
  }
}

class ForumBinding extends Bindings {
  @override
  void dependencies() {
    // El foro requiere auth — AuthController ya está en InitialBinding
    Get.lazyPut(() => ForumService());
    Get.lazyPut(() => ForumController(
      Get.find<ForumService>(),
      Get.find<AuthController>(),
    ));
  }
}

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // AuthController se registra aquí si no existe aún
    if (!Get.isRegistered<AuthController>()) {
      Get.lazyPut(() => AuthController(Get.find<AuthService>()));
    }
  }
}