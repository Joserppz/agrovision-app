import 'dart:io';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../services/location_service.dart';
import 'connectivity_controller.dart';

enum ScanState { idle, capturing, analyzing, success, error, lowConfidence }

class ScanController extends GetxController {
  final ScanService        _scanService;
  final LocationService    _locationService;
  final ConnectivityController _connectivity;

  ScanController(this._scanService, this._locationService, this._connectivity);

  // ─── Estado reactivo ──────────────────────────────────────────────────────

  final state           = ScanState.idle.obs;
  final errorMessage    = ''.obs;
  final result          = Rxn<ScanResult>();      // null hasta que hay resultado
  final capturedImage   = Rxn<File>();
  final currentPosition = Rxn<Position>();

  // Cámara
  CameraController? cameraController;
  final isCameraReady   = false.obs;
  final cameras         = <CameraDescription>[].obs;
  final isFrontCamera   = false.obs;

  // ─── Ciclo de vida ────────────────────────────────────────────────────────

  @override
  Future<void> onInit() async {
    super.onInit();
    await _initCamera();
    await _loadPosition();
  }

  Future<void> _initCamera() async {
    try {
      isCameraReady.value = false;
      final available = await availableCameras();
      cameras.value = available;

      if (available.isEmpty) {
        errorMessage.value = 'No se encontró ninguna cámara';
        return;
      }

      // Filtrar según la dirección deseada (trasera por defecto)
      final targetDirection = isFrontCamera.value ? CameraLensDirection.front : CameraLensDirection.back;
      
      final selectedCamera = available.firstWhere(
        (c) => c.lensDirection == targetDirection,
        orElse: () => available.first,
      );

      // Liberar memoria del controlador anterior
      if (cameraController != null) {
        await cameraController!.dispose();
      }

      cameraController = CameraController(
        selectedCamera,
        ResolutionPreset.veryHigh, 
        enableAudio: false,        
      );

      await cameraController!.initialize();
      isCameraReady.value = true;
    } catch (e) {
      errorMessage.value = 'Error al iniciar la cámara: $e';
    }
  }

  Future<void> _loadPosition() async {
    try {
      currentPosition.value = await _locationService.getCurrentPosition();
    } catch (_) {
      // Evita que un fallo de GPS bloquee el inicio de la cámara
    }
  }

  Future<void> toggleCamera() async {
    if (cameras.isEmpty) return;
    isFrontCamera.value = !isFrontCamera.value;
    await _initCamera();
  }

  // ─── Captura y análisis ───────────────────────────────────────────────────

  Future<void> takePictureAndAnalyze() async {
    if (state.value == ScanState.capturing ||
        state.value == ScanState.analyzing) return;
    if (!isCameraReady.value || cameraController == null) return;

    try {
      // 1. Capturar foto
      state.value = ScanState.capturing;
      final xFile = await cameraController!.takePicture();
      capturedImage.value = File(xFile.path);

      // 2. Pantalla de carga
      state.value = ScanState.analyzing;
      Get.toNamed(AgroRoutes.loading);

      // 3. Ubicación
      Position? pos = currentPosition.value;
      if (pos == null) {
        pos = await _locationService.getCurrentPosition();
        currentPosition.value = pos;
      }

      String? locationName;
      if (pos != null) {
        locationName = await _locationService.getLocationName(
          pos.latitude, pos.longitude,
        );
      }

      // 4. Enviar al backend híbrido
      final scanResult = await _scanService.analyzeImage(
        imageFile:    capturedImage.value!,
        isOnline:     _connectivity.isOnline.value,
        latitude:     pos?.latitude,
        longitude:    pos?.longitude,
        locationName: locationName,
      );

      result.value = scanResult;
      state.value  = ScanState.success;

      // 5. Ir a resultados
      Get.offNamed(AgroRoutes.results);

    } on LowConfidenceException catch (e) {
      print("🚨 ERROR DE CONFIANZA BAJA: ${e.userMessage}");
      state.value   = ScanState.lowConfidence;
      errorMessage.value = e.userMessage;
      Get.back(); 
      _showError(e.userMessage);

    } on NoConnectionException catch (e) {
      print("🚨 ERROR DE RED (Offline): ${e.userMessage}");
      state.value = ScanState.error;
      errorMessage.value = e.userMessage;
      Get.back();
      _showWarning(e.userMessage);

    } on AgroException catch (e) {
      print("🚨 ERROR AGRO (Backend/Conexión): ${e.userMessage}");
      state.value = ScanState.error;
      errorMessage.value = e.userMessage;
      Get.back();
      _showError(e.userMessage);

    } catch (e, stacktrace) {
      print("🚨 ERROR DESCONOCIDO: $e");
      print("🚨 DETALLE TÉCNICO: $stacktrace");
      state.value = ScanState.error;
      errorMessage.value = 'Error inesperado al analizar';
      if (Get.currentRoute == AgroRoutes.loading) Get.back();
      _showError('Error inesperado. Intenta de nuevo.');
    }
  }

  Future<void> analyzeFromGallery(File imageFile) async {
    capturedImage.value = imageFile;
    await takePictureAndAnalyze();
  }

  void reset() {
    state.value        = ScanState.idle;
    result.value       = null;
    capturedImage.value = null;
    errorMessage.value = '';
  }

  // ─── Helpers UI ───────────────────────────────────────────────────────────

  void _showError(String msg) => Get.snackbar(
    '⚠️ Error',
    msg,
    snackPosition: SnackPosition.BOTTOM,
    duration:      const Duration(seconds: 4),
  );

  void _showWarning(String msg) => Get.snackbar(
    '📵 Sin conexión',
    msg,
    snackPosition: SnackPosition.BOTTOM,
    duration:      const Duration(seconds: 4),
  );

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}