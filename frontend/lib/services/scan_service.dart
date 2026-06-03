import 'dart:io';
import 'package:flutter/material.dart'; // Necesario para decodeImageFromList
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_vision/flutter_vision.dart'; 
import '../models/scan_result.dart';
import '../core/exceptions.dart' as agro_ex;
import '../controllers/scan_controller.dart'; 
import '../core/disease_dictionary.dart'; // <-- Diccionario local importado
import 'api_service.dart';
import 'local_db_service.dart';

class ScanService {
  final ApiService     _api;
  final LocalDbService _db;
  final FlutterVision  _vision = FlutterVision(); 
  final _uuid = const Uuid();

  ScanService(this._api, this._db);

  // MÉTODO AUXILIAR PARA CORRER TFLITE
  Future<Map<String, dynamic>?> _runLocalModel(File image, String modelPath, String labelsPath) async {
    try {
      await _vision.loadYoloModel(
        labels: labelsPath,
        modelPath: modelPath,
        modelVersion: "yolov8",
        numThreads: 2,
        useGpu: true,
      );

      final bytes = await image.readAsBytes();
      final decodedImage = await decodeImageFromList(bytes);

      final result = await _vision.yoloOnImage(
        bytesList: bytes,
        imageHeight: decodedImage.height,
        imageWidth: decodedImage.width,
        iouThreshold: 0.4,
        confThreshold: 0.4,
        classThreshold: 0.5,
      );

      await _vision.closeYoloModel();

      if (result.isNotEmpty) {
        return {
          "class": result[0]["tag"],
          "confidence": result[0]["box"][4]
        };
      }
      return null;
    } catch (e) {
      print("Error en modelo local: $e");
      return null;
    }
  }

  Future<ScanResult> analyzeImage({
    required File        imageFile,
    required bool        isOnline,
    required AnalysisMode mode,
    double?              latitude,
    double?              longitude,
    String?              locationName,
  }) async {
    final scanId = _uuid.v4();

    if (!isOnline && mode == AnalysisMode.groq) {
      throw agro_ex.NoConnectionException('La IA pura requiere internet. Usa YOLO o Híbrido.');
    }

    String? localPlant;
    String? localDisease;
    double localConfidence = 0.0;

    // ──────────────── EJECUCIÓN LOCAL EN CASCADA (YOLO/HÍBRIDO) ────────────────
    if (mode == AnalysisMode.yolo || mode == AnalysisMode.hybrid) {
      // 1. Detectar Planta
      final plantResult = await _runLocalModel(
          imageFile, 'assets/models/plantae_local.tflite', 'assets/models/labels_plantae.txt');
      if (plantResult != null) localPlant = plantResult['class'];

      // 2. Detectar Enfermedad
      final diseaseResult = await _runLocalModel(
          imageFile, 'assets/models/enfermedades_local.tflite', 'assets/models/labels_enfermedades.txt');
      if (diseaseResult != null) {
        localDisease = diseaseResult['class'];
        localConfidence = diseaseResult['confidence'];
      }

      // Si es YOLO puro (offline), retornamos con la info de nuestro diccionario local
      if (mode == AnalysisMode.yolo) {
        if (localDisease == null && localPlant == null) {
          throw agro_ex.AgroException('YOLO Local no detectó nada en la imagen.');
        }

        final infoLocal = getLocalInfo(localDisease, localPlant);

        final resultObj = ScanResult(
          id: scanId, 
          diseaseClass: localDisease ?? 'Desconocido', 
          diseaseName: localDisease ?? 'Desconocido',
          confidence: localConfidence,
          description: infoLocal["description"]!, 
          treatment: infoLocal["treatment"]!,     
          latitude: latitude, 
          longitude: longitude,
          locationName: locationName, 
          timestamp: DateTime.now(), 
          imagePath: imageFile.path,
          isSynced: false, 
          isPlant: localPlant != null,
        );

        if (!isOnline) {
          await _db.saveScan(resultObj);
          throw agro_ex.NoConnectionException('Resultado generado offline y guardado con éxito.');
        }
        return resultObj;
      }
    }

    // ──────────────── CONEXIÓN A GROQ (HÍBRIDO/GROQ) ────────────────
    try {
      final formDataGemini = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path, filename: 'scan_$scanId.jpg'),
        if (latitude != null) 'latitude': latitude.toString(),
        if (longitude != null) 'longitude': longitude.toString(),
        'scan_id': scanId,
        if (localDisease != null) 'yolo_disease': localDisease, 
        if (localPlant != null) 'yolo_plant': localPlant,       
      });

      final geminiResponse = await _api.postMultipart<Map<String, dynamic>>('/analyze', formDataGemini);
      final geminiData = geminiResponse.data!;

      if (geminiData['is_plant'] == false || geminiData['is_plant'] == "false") throw const agro_ex.LowConfidenceException(0.0);

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

    } on agro_ex.AgroException {
      rethrow;
    } catch (e) {
      throw agro_ex.AgroException('Error al conectar con la IA de Groq.', technicalDetail: e.toString());
    }
  }
}