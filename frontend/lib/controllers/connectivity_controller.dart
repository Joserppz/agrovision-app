import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';

class ConnectivityController extends GetxController {
  final _connectivity = Connectivity();
  
  // 1. Corregido: Ya no es una Lista, ahora es un objeto individual
  StreamSubscription<ConnectivityResult>? _subscription;

  final isOnline         = true.obs;
  final pendingSyncCount = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _checkInitialStatus();
    _listenToChanges();
  }

  Future<void> _checkInitialStatus() async {
    // 2. Corregido: checkConnectivity() devuelve un ConnectivityResult único en v6
    final result = await _connectivity.checkConnectivity();
    _updateStatus(result);
  }

  void _listenToChanges() {
    // 3. Corregido: Quitamos los trucos de casteo raros. Recibe un 'result' directo y limpio.
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final wasOffline = !isOnline.value;
      _updateStatus(result);
      if (wasOffline && isOnline.value) {
        _onReconnected();
      }
    });
  }

  // 4. Corregido: El método ahora acepta un objeto único en lugar de List<ConnectivityResult>
  void _updateStatus(ConnectivityResult result) {
    // Ya no necesitas usar .any(). La validación se hace directamente con el resultado.
    final connected = result == ConnectivityResult.mobile ||
        result == ConnectivityResult.wifi ||
        result == ConnectivityResult.ethernet;

    if (isOnline.value != connected) {
      isOnline.value = connected;
      if (connected) {
        Get.snackbar(
          '📶 Conexión restaurada',
          'Sincronizando datos pendientes...',
          duration: const Duration(seconds: 3),
          snackPosition: SnackPosition.TOP,
        );
      } else {
        Get.snackbar(
          '📵 Sin conexión',
          'Modo offline activado — los escaneos se guardan localmente',
          duration: const Duration(seconds: 4),
          snackPosition: SnackPosition.TOP,
        );
      }
    }
  }

  void _onReconnected() {
    // SyncService escucha este cambio via ever() en su propio init
  }

  void updatePendingCount(int count) {
    pendingSyncCount.value = count;
  }

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}