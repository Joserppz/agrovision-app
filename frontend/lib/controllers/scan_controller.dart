import 'dart:io';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import '../core/constants.dart';
import '../core/exceptions.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../services/location_service.dart';
import '../services/local_db_service.dart';
import 'connectivity_controller.dart';

enum ScanState { idle, capturing, analyzing, success, error, lowConfidence }
enum AnalysisMode { yolo, groq, hybrid }

class ScanController extends GetxController {
  final ScanService        _scanService;
  final LocationService    _locationService;
  final ConnectivityController _connectivity;

  ScanController(this._scanService, this._locationService, this._connectivity);

  final state           = ScanState.idle.obs;
  final errorMessage    = ''.obs;
  final result          = Rxn<ScanResult>();
  final capturedImage   = Rxn<File>();
  final currentPosition = Rxn<Position>();
  final selectedMode    = AnalysisMode.hybrid.obs;

  CameraController? cameraController;
  final isCameraReady   = false.obs;
  final cameras         = <CameraDescription>[].obs;
  final isFrontCamera   = false.obs;

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

      final targetDirection = isFrontCamera.value ? CameraLensDirection.front : CameraLensDirection.back;
      final selectedCamera = available.firstWhere(
        (c) => c.lensDirection == targetDirection,
        orElse: () => available.first,
      );

      if (cameraController != null) await cameraController!.dispose();

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
    } catch (_) {}
  }

  Future<void> toggleCamera() async {
    if (cameras.isEmpty) return;
    isFrontCamera.value = !isFrontCamera.value;
    await _initCamera();
  }

  void setMode(AnalysisMode mode) {
    selectedMode.value = mode;
  }

  Future<void> takePictureAndAnalyze() async {
    if (state.value == ScanState.capturing || state.value == ScanState.analyzing) return;
    if (!isCameraReady.value || cameraController == null) return;

    try {
      state.value = ScanState.capturing;
      final xFile = await cameraController!.takePicture();
      capturedImage.value = File(xFile.path);
      await _processImage(capturedImage.value!); 
    } catch (e) {
      _showError('Error al capturar la imagen.');
      state.value = ScanState.idle;
    }
  }

  Future<void> analyzeFromGallery(File imageFile) async {
    if (state.value == ScanState.capturing || state.value == ScanState.analyzing) return;
    capturedImage.value = imageFile;
    await _processImage(imageFile);
  }

  Future<void> _processImage(File image) async {
    try {
      state.value = ScanState.analyzing;
      Get.toNamed(AgroRoutes.loading);

      Position? pos = currentPosition.value;
      if (pos == null) {
        pos = await _locationService.getCurrentPosition();
        currentPosition.value = pos;
      }

      String? locationName;
      if (pos != null) {
        locationName = await _locationService.getLocationName(pos.latitude, pos.longitude);
      }

      ScanResult scanResult = await _scanService.analyzeImage(
        imageFile:    image,
        isOnline:     _connectivity.isOnline.value,
        mode:         selectedMode.value,
        latitude:     pos?.latitude,
        longitude:    pos?.longitude,
        locationName: locationName,
      );

      // YA NO GUARDAMOS AUTOMÁTICAMENTE AQUÍ.
      // Solo dejamos el resultado listo para mostrarse en pantalla.
      result.value = scanResult;
      state.value  = ScanState.success;
      Get.offNamed(AgroRoutes.results);

    } on LowConfidenceException catch (e) {
      state.value = ScanState.lowConfidence;
      errorMessage.value = e.userMessage;
      Get.back(); 
      _showError(e.userMessage);
    } on NoConnectionException catch (e) {
      state.value = ScanState.error;
      errorMessage.value = e.userMessage;
      Get.back();
      _showWarning(e.userMessage);
    } on AgroException catch (e) {
      state.value = ScanState.error;
      errorMessage.value = e.userMessage;
      Get.back();
      _showError(e.userMessage);
    } catch (e) {
      state.value = ScanState.error;
      errorMessage.value = 'Error inesperado al analizar';
      if (Get.currentRoute == AgroRoutes.loading) Get.back();
      _showError('Error inesperado. Intenta de nuevo.');
    }
  }

  // NUEVO: Función exclusiva para guardar cuando el usuario lo pida
  Future<void> saveCurrentScan() async {
    final currentResult = result.value;
    final currentImage = capturedImage.value;
    
    if (currentResult != null && currentImage != null && Get.isRegistered<LocalDbService>()) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final localPath = '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        // Copiamos la imagen a la memoria permanente
        await currentImage.copy(localPath);
        
        // Actualizamos la ruta permanente y guardamos en la base de datos
        final resultToSave = currentResult.copyWith(imagePath: localPath);
        await Get.find<LocalDbService>().saveScan(resultToSave);
      } catch (e) {
        print("🚨 Error al guardar el escaneo: $e");
      }
    }
  }

  void reset() {
    state.value        = ScanState.idle;
    result.value       = null;
    capturedImage.value = null;
    errorMessage.value = '';
  }

  void _showError(String msg) => Get.snackbar('⚠️ Error', msg, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));
  void _showWarning(String msg) => Get.snackbar('📵 Sin conexión', msg, snackPosition: SnackPosition.BOTTOM, duration: const Duration(seconds: 4));

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }
}