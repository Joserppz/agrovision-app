import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/scan_result.dart';
import '../core/exceptions.dart' as agro_ex;
import '../controllers/scan_controller.dart'; 
import 'api_service.dart';
import 'local_db_service.dart';

class ScanService {
  final ApiService     _api;
  final LocalDbService _db;
  final _uuid = const Uuid();

  ScanService(this._api, this._db);

  Future<ScanResult> analyzeImage({
    required File         imageFile,
    required bool         isOnline,
    required AnalysisMode mode,
    double?               latitude,
    double?               longitude,
    String?               locationName,
  }) async {
    final scanId = _uuid.v4();

    if (!isOnline && (mode == AnalysisMode.groq || mode == AnalysisMode.hybrid)) {
      throw agro_ex.NoConnectionException('La IA requiere internet. Cambia a YOLO o conéctate.');
    }

    if (!isOnline && mode == AnalysisMode.yolo) {
      await _savePending(
        scanId: scanId, imagePath: imageFile.path, latitude: latitude, 
        longitude: longitude, locationName: locationName,
      );
      throw agro_ex.NoConnectionException('Escaneo guardado offline. (YOLO Local próximamente).');
    }

    try {
      // ──────────────── MODO 1: YOLO ────────────────
      if (mode == AnalysisMode.yolo) {
        final formDataYolo = FormData.fromMap({
          'file': await MultipartFile.fromFile(imageFile.path, filename: 'yolo_$scanId.jpg'),
        });
        final yoloResponse = await _api.postMultipart<Map<String, dynamic>>('/predict', formDataYolo);
        final yoloData = yoloResponse.data!;

        if (yoloData['success'] == true && yoloData['detections'] != null && (yoloData['detections'] as List).isNotEmpty) {
          final best = yoloData['detections'][0];
          return ScanResult(
            id: scanId, diseaseClass: best['disease'], diseaseName: best['disease'],
            confidence: (best['confidence'] as num).toDouble() / 100.0,
            description: 'Diagnóstico generado exclusivamente por YOLO. No incluye análisis de IA.',
            treatment: 'Consulta el manual agrícola.', latitude: latitude, longitude: longitude,
            locationName: locationName, timestamp: DateTime.now(), imagePath: imageFile.path,
            isSynced: true, isPlant: true,
          );
        } else {
          throw agro_ex.AgroException('YOLO no detectó ninguna enfermedad.');
        }
      }

      // ──────────────── MODO 2: GROQ ────────────────
      else if (mode == AnalysisMode.groq) {
        final formDataGemini = FormData.fromMap({
          'image': await MultipartFile.fromFile(imageFile.path, filename: 'scan_$scanId.jpg'),
          'scan_id': scanId,
        });
        final geminiResponse = await _api.postMultipart<Map<String, dynamic>>('/analyze', formDataGemini);
        final geminiData = geminiResponse.data!;

        if (geminiData['is_plant'] == false || geminiData['is_plant'] == "false") throw const agro_ex.LowConfidenceException(0.0);

        return ScanResult(
          id: geminiData['id'] ?? scanId, diseaseClass: geminiData['disease_class'] ?? 'Unknown',
          diseaseName: geminiData['diseaseName'], description: geminiData['description'],
          confidence: (geminiData['confidence'] as num?)?.toDouble() ?? 0.95,
          treatment: geminiData['treatment'] ?? '', latitude: latitude, longitude: longitude,
          locationName: geminiData['location_name'] ?? locationName, timestamp: DateTime.now(),
          imagePath: imageFile.path, isSynced: true,
        );
      }

      // ──────────────── MODO 3: HÍBRIDO ────────────────
      else {
        String? yoloDisease;
        bool yoloSuccess = false;

        // 1. Obtenemos dato YOLO
        try {
          final formDataYolo = FormData.fromMap({
            'file': await MultipartFile.fromFile(imageFile.path, filename: 'yolo_$scanId.jpg'),
          });
          final yoloResponse = await _api.postMultipart<Map<String, dynamic>>('/predict', formDataYolo);
          if (yoloResponse.data!['success'] == true && yoloResponse.data!['detections'] != null && (yoloResponse.data!['detections'] as List).isNotEmpty) {
            yoloDisease = yoloResponse.data!['detections'][0]['disease'];
            yoloSuccess = true;
          }
        } catch (e) {
          print('⚠️ YOLO Híbrido falló silenciado: $e');
        }

        // 2. Pasamos el dato YOLO a Groq para que no haya choques
        final formDataGemini = FormData.fromMap({
          'image': await MultipartFile.fromFile(imageFile.path, filename: 'scan_$scanId.jpg'),
          if (latitude != null) 'latitude': latitude.toString(),
          if (longitude != null) 'longitude': longitude.toString(),
          'scan_id': scanId,
          if (yoloSuccess) 'yolo_disease': yoloDisease, // <--- LA MAGIA OCURRE AQUÍ
        });

        final geminiResponse = await _api.postMultipart<Map<String, dynamic>>('/analyze', formDataGemini);
        final geminiData = geminiResponse.data!;

        if (geminiData['is_plant'] == false || geminiData['is_plant'] == "false") throw const agro_ex.LowConfidenceException(0.0);

        // 3. Dejamos que Groq decida los textos finales para asegurar coherencia
        return ScanResult(
          id: geminiData['id'] ?? scanId,
          diseaseClass: geminiData['disease_class'] ?? 'Unknown',
          diseaseName: geminiData['diseaseName'], 
          confidence: (geminiData['confidence'] as num?)?.toDouble() ?? 0.95,
          description: geminiData['description'],
          treatment: geminiData['treatment'] ?? '',
          latitude: latitude, longitude: longitude, locationName: geminiData['location_name'] ?? locationName,
          timestamp: DateTime.now(), imagePath: imageFile.path, isSynced: true,
        );
      }

    } on agro_ex.AgroException {
      rethrow;
    } catch (e) {
      throw agro_ex.AgroException('Error al analizar la imagen', technicalDetail: e.toString());
    }
  }

  Future<void> _savePending({required String scanId, required String imagePath, double? latitude, double? longitude, String? locationName}) async {
    await _db.savePendingScan(scanId: scanId, imagePath: imagePath, latitude: latitude, longitude: longitude, locationName: locationName);
  }
}