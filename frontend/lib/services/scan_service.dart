import 'dart:io';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../models/scan_result.dart';
import '../core/constants.dart';
import '../core/exceptions.dart' as agro_ex;
import 'api_service.dart';
import 'local_db_service.dart';

class ScanService {
  final ApiService     _api;
  final LocalDbService _db;
  final _uuid = const Uuid();

  ScanService(this._api, this._db);

  // Cambia a true para probar sin backend ni planta real
  static const bool _demoMode = false;

  Future<ScanResult> analyzeImage({
    required File   imageFile,
    required bool   isOnline,
    double?         latitude,
    double?         longitude,
    String?         locationName,
  }) async {
    final scanId = _uuid.v4();

    // ── MODO DEMO ────────────────────────────────────────────────────────────
    if (_demoMode) {
      await Future.delayed(const Duration(seconds: 2));
      final demo = ScanResult(
        id:           scanId,
        diseaseClass: 'Late-Blight',
        confidence:   0.874,
        treatment:    'Aislar las plantas afectadas.\nAplicar fungicida a base de cobre.\nReducir riego por aspersión.',
        latitude:     latitude,
        longitude:    longitude,
        locationName: locationName ?? 'La Paz, Bolivia',
        timestamp:    DateTime.now(),
        imagePath:    imageFile.path,
        isSynced:     false,
      );
      await _db.saveScan(demo);
      return demo;
    }

    // ── SIN CONEXIÓN → guardar en cola ───────────────────────────────────────
    if (!isOnline) {
      await _savePending(
        scanId:       scanId,
        imagePath:    imageFile.path,
        latitude:     latitude,
        longitude:    longitude,
        locationName: locationName,
      );
      throw agro_ex.NoConnectionException('No internet connection');
    }

    // ── MODO REAL → FUSIÓN DE MOTORES ─────────────────────────────────────────
    try {
      // 1. ATAQUE RÁPIDO: MODELO YOLO LOCAL
      bool yoloSuccess = false;
      String yoloDisease = 'Other';
      double yoloConfidence = 0.0;

      try {
        final formDataYolo = FormData.fromMap({
          // El backend de YOLO espera el parámetro "file"
          'file': await MultipartFile.fromFile(
            imageFile.path,
            filename: 'yolo_$scanId.jpg',
          ),
        });

        final yoloResponse = await _api.postMultipart<Map<String, dynamic>>(
          '/predict',
          formDataYolo,
        );

        final yoloData = yoloResponse.data!;
        
        if (yoloData['success'] == true && yoloData['detections'] != null) {
          final detections = yoloData['detections'] as List;
          if (detections.isNotEmpty) {
            final bestDetection = detections.first;
            yoloDisease = bestDetection['disease'];
            // YOLO devuelve la confianza x100 (ej. 95.5). La pasamos a 0.955
            yoloConfidence = (bestDetection['confidence'] as num).toDouble() / 100.0;
            yoloSuccess = true;
            print('🎯 YOLO detectó: $yoloDisease (Confianza: $yoloConfidence)');
          }
        } else {
          print('👀 YOLO no detectó nada. Dependeremos al 100% de Gemini.');
        }
      } catch (e) {
        print('⚠️ YOLO falló (Puede que best.pt no esté cargado): $e');
      }

      // 2. RED DE SEGURIDAD Y TRATAMIENTOS: GEMINI
      final formDataGemini = FormData.fromMap({
        // El backend de Gemini espera el parámetro "image"
        'image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'scan_$scanId.jpg',
        ),
        if (latitude  != null) 'latitude':  latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        'scan_id': scanId,
      });

      final geminiResponse = await _api.postMultipart<Map<String, dynamic>>(
        '/analyze',
        formDataGemini,
      );

      final geminiData = geminiResponse.data!;
      print('🧠 Respuesta Gemini: $geminiData');

      if (geminiData['is_plant'] == false) {
        throw const agro_ex.LowConfidenceException(0.0);
      }

      // 3. FUSIÓN TÁCTICA DE RESULTADOS
      String finalDiseaseClass;
      double finalConfidence;

      if (yoloSuccess && yoloConfidence >= AgroConfig.yoloThreshold) {
        // YOLO es confiable para esta planta: Usamos su diagnóstico y el tratamiento de la IA
        finalDiseaseClass = yoloDisease;
        finalConfidence = yoloConfidence;
        print('🤝 Fusión: Diagnóstico YOLO + Tratamiento Gemini');
      } else {
        // YOLO falló o la planta es desconocida: Gemini toma el control total
        finalDiseaseClass = geminiData['disease_class'] as String? ?? 'Other';
        finalConfidence = (geminiData['confidence'] as num).toDouble();
        print('🤝 Fusión: Diagnóstico Gemini + Tratamiento Gemini');

        if (finalConfidence < AgroConfig.yoloThreshold) {
          throw agro_ex.LowConfidenceException(finalConfidence);
        }
      }

      final result = ScanResult(
        id:           geminiData['id'] as String? ?? scanId,
        diseaseClass: finalDiseaseClass,
        confidence:   finalConfidence,
        treatment:    geminiData['treatment'] as String? ?? '',
        latitude:     latitude,
        longitude:    longitude,
        locationName: geminiData['location_name'] as String? ?? locationName,
        timestamp:    DateTime.now(),
        imagePath:    imageFile.path,
        isSynced:     true,
      );

      await _db.saveScan(result);
      return result;

    } on agro_ex.AgroException {
      rethrow;
    } catch (e) {
      throw agro_ex.AgroException(
        'Error al analizar la imagen',
        technicalDetail: e.toString(),
      );
    }
  }

  Future<void> _savePending({
    required String scanId,
    required String imagePath,
    double?  latitude,
    double?  longitude,
    String?  locationName,
  }) async {
    await _db.savePendingScan(
      scanId:       scanId,
      imagePath:    imagePath,
      latitude:     latitude,
      longitude:    longitude,
      locationName: locationName,
    );
  }
}