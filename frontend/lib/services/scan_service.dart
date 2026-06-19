import 'dart:io';
import 'package:uuid/uuid.dart';
import '../models/scan_result.dart';
import '../services/api_service.dart';

import 'package:dio/dio.dart';
import '../core/exceptions.dart';

class ScanService {
  final ApiService _api;

  ScanService(this._api);

  Future<ScanResult> analyzeImage({
    required File imageFile,
    required bool isOnline,
    required dynamic mode,
    double? latitude,
    double? longitude,
    String? locationName,
  }) async {
    final scanId = const Uuid().v4();

    if (!isOnline) {
      // TODO: Implementar inferencia local con flutter_vision (YOLO) aquí si no hay internet
      // Por ahora, si no hay internet lanzamos excepción de conexión
      throw const NoConnectionException('Sin conexión a internet para análisis en la nube.');
    }

    try {
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imageFile.path),
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (locationName != null) 'location_name': locationName,
        'scan_id': scanId,
        // TODO: Pasar aquí los resultados de YOLO local si los tuviéramos
        'yolo_disease': 'Desconocido', 
        'yolo_plant': 'Desconocido',
      });

      final response = await _api.postMultipart('/analyze', formData);
      
      if (response.data == null) {
        throw const BackendException('El servidor no devolvió datos');
      }

      // El backend de FastAPI/Render devuelve un JSON que parseamos
      return ScanResult.fromJson(response.data as Map<String, dynamic>).copyWith(
        id: scanId,
        imagePath: imageFile.path,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        isSynced: true,
      );
    } catch (e) {
      if (e is AgroException) rethrow;
      throw BackendException('Error al contactar con la IA: $e');
    }
  }
}