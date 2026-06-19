import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../models/scan_result.dart';
import '../services/scan_service.dart';
import '../services/location_service.dart';
import '../services/api_service.dart';

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

final locationServiceProvider = Provider((ref) => LocationService());
final scanServiceProvider = Provider((ref) => ScanService(ref.read(apiServiceProvider)));

class ScanController extends Notifier<ScanStateData> {
  CameraController? cameraController;
  List<CameraDescription> _cameras = [];

  @override
  ScanStateData build() {
    ref.onDispose(() => cameraController?.dispose());
    Future.microtask(() {
      _initCamera();
      _loadPosition();
    });
    return const ScanStateData();
  }

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
      state = state.copyWith(status: ScanStatus.error, errorMessage: 'Error cámara');
    }
  }

  Future<void> _loadPosition() async {
    final pos = await ref.read(locationServiceProvider).getCurrentPosition();
    if (pos != null) state = state.copyWith(currentPosition: pos);
  }

  Future<bool> takePictureAndAnalyze() async {
    state = state.copyWith(status: ScanStatus.capturing);
    final xFile = await cameraController!.takePicture();
    state = state.copyWith(capturedImage: File(xFile.path));
    return await _processImage(File(xFile.path));
  }

  Future<bool> analyzeFromGallery(File image) async {
    state = state.copyWith(capturedImage: image);
    return await _processImage(image);
  }

  Future<bool> _processImage(File image) async {
    state = state.copyWith(status: ScanStatus.analyzing);
    try {
      final res = await ref.read(scanServiceProvider).analyzeImage(
        imageFile: image, isOnline: true, mode: state.selectedMode,
      );
      state = state.copyWith(status: ScanStatus.success, result: res);
      return true;
    } catch (e) {
      state = state.copyWith(status: ScanStatus.error, errorMessage: 'Error');
      return false;
    }
  }

  void toggleCamera() async {
    state = state.copyWith(isFrontCamera: !state.isFrontCamera);
    await _initCamera();
  }

  void setMode(AnalysisMode mode) => state = state.copyWith(selectedMode: mode);
  void reset() => state = const ScanStateData();

  saveCurrentScan({required String customName, required String category}) {}

  void setResultForViewing(ScanResult scan) {}
}

final scanControllerProvider = NotifierProvider<ScanController, ScanStateData>(ScanController.new);