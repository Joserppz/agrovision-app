import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';

import '../core/exceptions.dart';
import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../services/location_service.dart';
import '../services/local_db_service.dart';
import '../services/api_service.dart';

// --- PROVIDERS DE INYECCIÓN ---
final locationServiceProvider = Provider((ref) => LocationService());

final scanServiceProvider = Provider((ref) {
  return ScanService(
    ref.read(apiServiceProvider),
    ref.read(localDbProvider),
  );
});

// --- ESTADOS ---
enum ScanStatus { idle, capturing, analyzing, success, error, lowConfidence }
enum AnalysisMode { yolo, groq, hybrid }

class ScanStateData {
  final ScanStatus status;
  final String errorMessage;
  final ScanResult? result;
  final File? capturedImage;
  final Position? currentPosition;
  final AnalysisMode selectedMode;
  final bool isCameraReady;
  final bool isFrontCamera;

  const ScanStateData({
    this.status = ScanStatus.idle,
    this.errorMessage = '',
    this.result,
    this.capturedImage,
    this.currentPosition,
    this.selectedMode = AnalysisMode.hybrid,
    this.isCameraReady = false,
    this.isFrontCamera = false,
  });

  ScanStateData copyWith({
    ScanStatus? status, String? errorMessage, ScanResult? result,
    File? capturedImage, Position? currentPosition, AnalysisMode? selectedMode,
    bool? isCameraReady, bool? isFrontCamera,
  }) => ScanStateData(
    status: status ?? this.status,
    errorMessage: errorMessage ?? this.errorMessage,
    result: result ?? this.result,
    capturedImage: capturedImage ?? this.capturedImage,
    currentPosition: currentPosition ?? this.currentPosition,
    selectedMode: selectedMode ?? this.selectedMode,
    isCameraReady: isCameraReady ?? this.isCameraReady,
    isFrontCamera: isFrontCamera ?? this.isFrontCamera,
  );
}

// --- NOTIFIER ---
class ScanController extends Notifier<ScanStateData> {
  CameraController? cameraController;
  List<CameraDescription> _cameras = [];

  @override
  ScanStateData build() {
    // La inicialización se dispara de forma independiente
    Future.microtask(() {
      _initCamera();
      _loadPosition();
    });
    return const ScanStateData();
  }

  // Métodos de acceso a servicios vía ref
  ScanService get _scanService => ref.read(scanServiceProvider);
  LocationService get _locationService => ref.read(locationServiceProvider);

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) return;

      final dir = state.isFrontCamera ? CameraLensDirection.front : CameraLensDirection.back;
      final cam = _cameras.firstWhere((c) => c.lensDirection == dir, orElse: () => _cameras.first);

      await cameraController?.dispose();
      cameraController = CameraController(cam, ResolutionPreset.veryHigh, enableAudio: false);
      await cameraController!.initialize();
      state = state.copyWith(isCameraReady: true);
    } catch (e) {
      state = state.copyWith(status: ScanStatus.error, errorMessage: 'Error de cámara');
    }
  }

  Future<void> _loadPosition() async {
    final pos = await _locationService.getCurrentPosition();
    if (pos != null) state = state.copyWith(currentPosition: pos);
  }

  Future<bool> takePictureAndAnalyze() async {
    if (state.status == ScanStatus.capturing || state.status == ScanStatus.analyzing) return false;
    
    state = state.copyWith(status: ScanStatus.capturing);
    try {
      final xFile = await cameraController!.takePicture();
      final image = File(xFile.path);
      state = state.copyWith(capturedImage: image);
      return await _processImage(image);
    } catch (e) {
      state = state.copyWith(status: ScanStatus.idle);
      return false;
    }
  }

  Future<bool> _processImage(File image) async {
    state = state.copyWith(status: ScanStatus.analyzing);
    try {
      final pos = state.currentPosition;
      final locName = pos != null ? await _locationService.getLocationName(pos.latitude, pos.longitude) : null;
      
      final result = await _scanService.analyzeImage(
        imageFile: image, isOnline: true, mode: state.selectedMode,
        latitude: pos?.latitude, longitude: pos?.longitude, locationName: locName,
      );
      
      state = state.copyWith(status: ScanStatus.success, result: result);
      return true;
    } catch (e) {
      state = state.copyWith(status: ScanStatus.error, errorMessage: 'Error al analizar');
      return false;
    }
  }

  Future<void> saveCurrentScan({required String customName, required String category}) async {
    final result = state.result;
    final image = state.capturedImage;
    if (result == null || image == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final localPath = '${dir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await image.copy(localPath);

      // Usamos el servicio local directamente
      await ref.read(localDbProvider).saveScan(result.copyWith(
        diseaseName: customName,
        plantCategory: category,
        imagePath: localPath,
      ));
    } catch (e) {
      debugPrint('Error al guardar: $e');
    }
  }

  @override
  void dispose() {
    cameraController?.dispose();
    super.dispose();
  }
}

final scanControllerProvider = NotifierProvider<ScanController, ScanStateData>(ScanController.new);